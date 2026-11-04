// lib/features/room/services/call_signaling_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// WebRTC + Supabase Realtime ile sesli arama sinyalizasyonu.
/// P2P WebRTC, Google STUN, Supabase Broadcast kanalı.
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
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
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
    await _broadcast('call_accept', {'from': myId});
    await _setupPeerConnection(isOffer: false);
  }

  // ───────────── Aramayı reddet ─────────────

  Future<void> rejectCall() async {
    _ringingTimer?.cancel();
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
    _ringingTimer = Timer(const Duration(seconds: 30), () {
      if (_state == CallState.ringing) {
        _setState(CallState.idle);
      }
    });
    _setState(CallState.ringing);
    _onIncomingCall.add(IncomingCallEvent(callerId: from ?? partnerId));
  }

  void _onCallAccept(Map<String, dynamic> payload) {
    final from = _extract(payload, 'from') as String?;
    if (from == myId || _state != CallState.calling) return;
    _ringingTimer?.cancel();
    _setState(CallState.connecting);
    _setupPeerConnection(isOffer: true);
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

    await _pc?.setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await _pc?.createAnswer();
    if (answer == null) return;
    await _pc?.setLocalDescription(answer);
    await _broadcast('call_answer', {
      'from': myId,
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  Future<void> _onCallAnswer(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    final sdp = _extract(payload, 'sdp') as String?;
    final type = _extract(payload, 'type') as String?;
    if (sdp == null || type == null) return;
    await _pc?.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> _onIceCandidate(Map<String, dynamic> payload) async {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    final candidate = _extract(payload, 'candidate') as String?;
    final sdpMid = _extract(payload, 'sdpMid') as String?;
    final sdpMLineIndex = _extract(payload, 'sdpMLineIndex') as int?;
    if (candidate == null) return;
    await _pc?.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  void _onCallEnd(Map<String, dynamic> payload) {
    final from = _extract(payload, 'from') as String?;
    if (from == myId) return;
    _endCall(CallEndReason.ended, local: false);
  }

  // ───────────── WebRTC peer bağlantısı ─────────────

  Future<void> _setupPeerConnection({required bool isOffer}) async {
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
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _broadcast('ice_candidate', {
          'from': myId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        _onRemoteStream.add(event.streams.first);
      }
      _setState(CallState.active);
      _startDurationTimer();
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _endCall(CallEndReason.connectionLost, local: false);
      }
    };

    if (isOffer) {
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(offer);
      await _broadcast('call_offer', {
        'from': myId,
        'sdp': offer.sdp,
        'type': offer.type,
      });
    }
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
    _durationTimer?.cancel();

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
