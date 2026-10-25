// lib/data/services/room_presence.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Karşı taraftan gelen "Seni Düşünüyorum" sinyali.
class PokeEvent {
  const PokeEvent({required this.nickname});
  final String nickname;
}

/// Supabase Realtime ile:
///  - Presence: online / yazıyor durumu
///  - Broadcast: Poki-Poke sinyali (veritabanına yazılmaz)
class RoomPresence extends ChangeNotifier {
  RoomPresence({
    required this.roomId,
    required this.myId,
    required this.partnerId,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client;

  static const String _pokeEvent = 'poki_poke';

  final String roomId;
  final String myId;
  final String partnerId;
  final SupabaseClient _db;

  RealtimeChannel? _channel;
  final StreamController<PokeEvent> _pokes = StreamController.broadcast();
  bool _typing = false;
  bool _disposed = false;

  bool partnerOnline = false;
  bool partnerTyping = false;

  Stream<PokeEvent> get pokes => _pokes.stream;

  void join() {
    final channel = _db.channel(
      'room:$roomId',
      opts: RealtimeChannelConfig(key: myId),
    );
    channel
        .onPresenceSync((_) => _sync())
        .onBroadcast(event: _pokeEvent, callback: _onPokePayload)
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _track();
      }
    });
    _channel = channel;
  }

  void _onPokePayload(Map<String, dynamic> payload) {
    // Sürüme göre payload iç içe ('payload' anahtarı) gelebilir.
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;
    final name = (data['nickname'] as String?)?.trim();
    if (!_disposed && !_pokes.isClosed) {
      _pokes.add(PokeEvent(nickname: (name == null || name.isEmpty) ? 'Biri' : name));
    }
  }

  /// "Seni Düşünüyorum" gönder.
  Future<void> sendPoke(String myNickname) async {
    await _channel?.sendBroadcastMessage(
      event: _pokeEvent,
      payload: {'from': myId, 'nickname': myNickname},
    );
  }

  void _sync() {
    var online = false;
    var typing = false;
    for (final state in _channel?.presenceState() ?? <SinglePresenceState>[]) {
      if (state.key != partnerId) continue;
      for (final presence in state.presences) {
        online = true;
        if (presence.payload['typing'] == true) typing = true;
      }
    }
    if (online != partnerOnline || typing != partnerTyping) {
      partnerOnline = online;
      partnerTyping = typing;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _track() async {
    await _channel?.track({'typing': _typing});
  }

  void setTyping(bool value) {
    if (value == _typing) return;
    _typing = value;
    _track();
  }

  /// Uygulama arka plana gidince çevrimdışı görün.
  Future<void> pause() async {
    _typing = false;
    await _channel?.untrack();
  }

  Future<void> resume() => _track();

  @override
  void dispose() {
    _disposed = true;
    _pokes.close();
    final channel = _channel;
    if (channel != null) {
      channel.untrack();
      _db.removeChannel(channel);
    }
    super.dispose();
  }
}
