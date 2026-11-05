// lib/features/room/services/call_signaling_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// WebRTC + Supabase Realtime ile sesli arama sinyalizasyonu.
/// P2P WebRTC, STUN + TURN (Metered Relay) ile NAT/CGNAT aşımı, Supabase Broadcast kanalı.
class CallSignalingService extends ChangeNotifier {
  CallSignalingService({
    required this.roomId,
    required this.myId,
    required this.partnerId,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client;

  final String roomId;
  final String myId;
  final String partnerId;
  final SupabaseClient _db;

  // ───────────── Durum ─────────────
  CallState _state = CallState.idle;
  CallState get state => _state;

  bool _isCaller = false;
  bool get isCaller => _isCaller;

  Duration _callDuration = Duration.zero;
  Duration get callDuration => _callDuration;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  double _remoteVolume = 0.0;
  double get remoteVolume => _remoteVolume;

  // ───────────── Dahili ─────────────
  RealtimeChannel? _channel;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  Timer? _durationTimer;
  Timer? _ringingTimer;
  Timer? _connectingTimeoutTimer;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  // ICE Candidates & Offer Buffer (Yarış durumlarını önlemek için)
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _hasRemoteDescription = false;
  Map<String, String>? _pendingOffer;

  // STUN + TURN (Farklı ülkeler / Farklı mobil operatörler / Simetrik NAT için)
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      {'urls': 'stun:openrelay.metered.ca:80'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:relay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:relay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:relay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ───────────── Stream controllers ─────────────
  final _onIncomingCall = StreamController<IncomingCallEvent>.broadcast();
  final _onCallEnded = StreamController<CallEndReason>.broadcast();
  final _onRemoteStream = StreamController<MediaStream>.broadcast();

  Stream<IncomingCallEvent> get onIncomingCall => _onIncomingCall.stream;
  Stream<CallEndReason> get onCallEnded => _onCallEnded.stream;
  Stream<MediaStream> get onRemoteStream => _onRemoteStream.stream;

  // ───────────── Başlatma ─────────────

  Future<void> init() async {
    try {
      await _remoteRenderer.initialize();
    } catch (_) {}

    _channel = _db.channel('room:$roomId:call');
    _channel!
        .onBroadcast(event: 'call_invite', callback: _onCallInvite)
        .onBroadcast(event: 'call_accept', callback: _onCallAccept)
        .onBroadcast(event: 'call_reject', callback: _onCallReject)
        .onBroadcast(event: 'call_offer', callback: _onCallOffer)
        .onBroadcast(event: 'call_answer', callback: _onCallAnswer)
        .onBroadcast(event: 'ice_candidate', callback: _onIceCandidate)
        .onBroadcast(event: 'call_end', callback: _onCallEnd)
        .subscribe();
  }

  // ───────────── Arama başlat ─────────────

  Future<void> startCall() async {
    if (_state != CallState.idle) return;
    _isCaller = true;
    _setState(CallState.calling);

    await _broadcast('call_invite', {'from': myId});

    _ringingTimer?.cancel();
    _ringingTimer = Timer(const Duration(seconds: 30), () {
      if (_state == CallState.calling) {
        _endCall(CallEndReason.noAnswer, local: true);
      }
    });
  }

  // ───────────── Aramayı kabul et ─────────────

  Future<void> acceptCall() async {
    if (_state != CallState.ringing) return;
    _ringingTimer?.cancel();
    _setState(CallState.connecting);
    _startConnectingTimeout();

    try {
      // 1. Önce alıcı taraf peer connection'ı kursun ve mikrofonu alsın
      await _setupPeerConnection(isOffer: false);

      // 2. Şimdi arayana hazır olduğumuzu bildir
      await _broadcast('call_accept', {'from': myId});

      // 3. Eğer kurulum sırasında offer zaten ulaştıysa hemen yanıtla
      if (_pendingOffer != null) {
        final offer = _pendingOffer!;
        _pendingOffer = null;
        await _processOffer(offer['sdp']!, offer['type']!);
      }
    } catch (e) {
      debugPrint('[CallSignaling] acceptCall error: $e');
      await _endCall(CallEndReason.connectionLost, local: true);
    }
  }

  // ───────────── Aramayı reddet ─────────────

  Future<void> rejectCall() async {
    _ringingTimer?.cancel();
    _connectingTimeoutTimer?.cancel();
    await _broadcast('call_reject', {'from': myId});
    _setState(CallState.idle);
  }

  // ───────────── Aramayı bitir ─────────────

  Future<void> endCall() async {
    await _endCall(CallEndReason.ended, local: true);
  }

  // ───────────── Mikrofon ─────────────

  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((t) {
      t.enabled = !_isMuted;
    });
    notifyListeners();
  }

  // ───────────── Hoparlör ─────────────

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    if (!kIsWeb) {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    }
    notifyListeners();
  }

  // ───────────── Broadcast yardımcıları ─────────────

  Future<void> _broadcast(String event, Map<String, dynamic> payload) async {
    await _channel?.sendBroadcastMessage(event: event, payload: payload);
  }

  // ───────────── Olay işleyicileri ─────────────

  void _onCallInvite(Map<String, dynamic> payload) {
    final from = _extract(payload, 'from') as String?;
    if (from == myId || _state != CallState.idle) return;
    _ringingTimer?.cancel();
    _ringingTimer = Timer(const Duration(seconds: 30), () {
      if (_state == CallState.ringing) {
        _setState(CallState.idle);
      }
    });
    _setState(CallState.ringing);
    _onIncomingCall.add(IncomingCallEvent(callerId: from ?? partnerId));
  }

  Future<void> _onCallAccept(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId || _state != CallState.calling) return;
    _ringingTimer?.cancel();
    _setState(CallState.connecting);
    _startConnectingTimeout();
    await _setupPeerConnection(isOffer: true);
  }

  void _onCallReject(Map<String, dynamic> payload) {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    _endCall(CallEndReason.rejected, local: false);
  }

  Future<void> _onCallOffer(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    final sdp = _extract(payload, 'sdp') as String?;
    final type = _extract(payload, 'type') as String?;
    if (sdp == null || type == null) return;

    if (_pc == null) {
      // Peer connection henüz hazırlanıyorsa offer'ı sakla, bitince işlenecek
      _pendingOffer = {'sdp': sdp, 'type': type};
      return;
    }

    await _processOffer(sdp, type);
  }

  Future<void> _processOffer(String sdp, String type) async {
    if (_pc == null) return;
    try {
      await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
      await _drainPendingCandidates();

      final answer = await _pc!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _pc!.setLocalDescription(answer);

      await _broadcast('call_answer', {
        'from': myId,
        'sdp': answer.sdp,
        'type': answer.type,
      });
    } catch (e) {
      debugPrint('[CallSignaling] processOffer error: $e');
    }
  }

  Future<void> _onCallAnswer(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    final sdp = _extract(payload, 'sdp') as String?;
    final type = _extract(payload, 'type') as String?;
    if (sdp == null || type == null || _pc == null) return;

    try {
      await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
      await _drainPendingCandidates();
    } catch (e) {
      debugPrint('[CallSignaling] onCallAnswer error: $e');
    }
  }

  Future<void> _onIceCandidate(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    final candidateStr = _extract(payload, 'candidate') as String?;
    final sdpMid = _extract(payload, 'sdpMid') as String?;
    final rawIndex = _extract(payload, 'sdpMLineIndex');
    final sdpMLineIndex = (rawIndex is num) ? rawIndex.toInt() : null;

    if (candidateStr == null || candidateStr.isEmpty) return;

    final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);

    if (_pc != null && _hasRemoteDescription) {
      try {
        await _pc!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[CallSignaling] addCandidate error: $e');
      }
    } else {
      _pendingCandidates.add(candidate);
    }
  }

  Future<void> _drainPendingCandidates() async {
    _hasRemoteDescription = true;
    if (_pc == null) return;
    for (final candidate in _pendingCandidates) {
      try {
        await _pc!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[CallSignaling] drainCandidate error: $e');
      }
    }
    _pendingCandidates.clear();
  }

  void _onCallEnd(Map<String, dynamic> payload) {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    _endCall(CallEndReason.ended, local: false);
  }

  // ───────────── WebRTC peer bağlantısı ─────────────

  Future<void> _setupPeerConnection({required bool isOffer}) async {
    _hasRemoteDescription = false;
    _pendingCandidates.clear();
    _pendingOffer = null;

    _pc = await createPeerConnection(_iceServers);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !_isMuted;
      await _pc!.addTrack(track, _localStream!);
    }

    if (!kIsWeb) {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    }

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        _broadcast('ice_candidate', {
          'from': myId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _pc!.onTrack = (event) {
      debugPrint('[CallSignaling] onTrack: streams=${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        _onRemoteStream.add(event.streams.first);
      }
      _markConnected();
    };

    _pc!.onConnectionState = (state) {
      debugPrint('[CallSignaling] onConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _markConnected();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _endCall(CallEndReason.connectionLost, local: false);
      }
    };

    _pc!.onIceConnectionState = (state) {
      debugPrint('[CallSignaling] onIceConnectionState: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _markConnected();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _endCall(CallEndReason.connectionLost, local: false);
      }
    };

    if (isOffer) {
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _pc!.setLocalDescription(offer);
      await _broadcast('call_offer', {
        'from': myId,
        'sdp': offer.sdp,
        'type': offer.type,
      });
    }
  }

  void _markConnected() {
    _connectingTimeoutTimer?.cancel();
    if (_state != CallState.active) {
      _setState(CallState.active);
      _startDurationTimer();
    }
  }

  void _startConnectingTimeout() {
    _connectingTimeoutTimer?.cancel();
    _connectingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_state == CallState.connecting) {
        debugPrint('[CallSignaling] Connection timed out after 30s');
        _endCall(CallEndReason.connectionLost, local: true);
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _setState(CallState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  Future<void> _endCall(CallEndReason reason, {required bool local}) async {
    if (_state == CallState.idle) return;

    if (local) {
      await _broadcast('call_end', {'from': myId});
    }

    _ringingTimer?.cancel();
    _connectingTimeoutTimer?.cancel();
    _durationTimer?.cancel();

    _pendingCandidates.clear();
    _pendingOffer = null;
    _hasRemoteDescription = false;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteRenderer.srcObject = null;

    await _pc?.close();
    _pc = null;

    _isMuted = false;
    _isSpeakerOn = false;
    _callDuration = Duration.zero;
    _isCaller = false;

    _setState(CallState.idle);
    if (!_onCallEnded.isClosed) {
      _onCallEnded.add(reason);
    }
  }

  dynamic _extract(Map<String, dynamic> payload, String key) {
    final nested = payload['payload'];
    if (nested is Map) {
      return nested[key] ?? payload[key];
    }
    return payload[key];
  }

  @override
  void dispose() {
    _endCall(CallEndReason.ended, local: false);
    _remoteRenderer.dispose();
    final ch = _channel;
    if (ch != null) {
      _db.removeChannel(ch);
    }
    _onIncomingCall.close();
    _onCallEnded.close();
    _onRemoteStream.close();
    super.dispose();
  }
}

enum CallState { idle, calling, ringing, connecting, active }

enum CallEndReason { ended, rejected, noAnswer, connectionLost }

class IncomingCallEvent {
  const IncomingCallEvent({required this.callerId});
  final String callerId;
}
