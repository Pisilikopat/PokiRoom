// lib/data/services/room_presence.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PokiRoom aktivite türleri (Zengin Durum / Rich Presence).
enum PokiActivityType {
  chatting,       // Sohbette
  typing,         // Yazıyor...
  inQuizWaiting,  // Quiz odasında seni bekliyor
  inQuizPlaying,  // Quiz çözüyor
  inPuzzleWaiting,// Puzzle odasında seni bekliyor
  inPuzzlePlaying,// Puzzle çözüyor
  inLiveDoodle,   // Birlikte çizimde seni bekliyor
  workshop,       // Atölyede çıkartma çiziyor
  memories,       // Anılara göz atıyor
  gamesHub,       // Oyun Odasında
  inApp,          // Uygulamada geziniyor
  offline,        // Çevrimdışı / uyuyor
}

/// Poki aktivite modeli.
class PokiActivity {
  const PokiActivity({
    required this.type,
    required this.text,
    this.actionLabel,
    this.actionType,
  });

  final PokiActivityType type;
  final String text;
  final String? actionLabel; // Örn: 'Hemen Katıl ➔'
  final String? actionType;  // 'quiz', 'doodle', 'puzzle'

  static const PokiActivity chatting = PokiActivity(
    type: PokiActivityType.chatting,
    text: 'Sohbette 💬',
  );

  static const PokiActivity typing = PokiActivity(
    type: PokiActivityType.typing,
    text: 'Yazıyor... ✍️',
  );

  static const PokiActivity inQuizWaiting = PokiActivity(
    type: PokiActivityType.inQuizWaiting,
    text: 'Quiz odasında seni bekliyor 🎮',
    actionLabel: 'Hemen Katıl ➔',
    actionType: 'quiz',
  );

  static const PokiActivity inQuizPlaying = PokiActivity(
    type: PokiActivityType.inQuizPlaying,
    text: 'Quiz çözüyor 🎮',
  );

  static const PokiActivity inPuzzleWaiting = PokiActivity(
    type: PokiActivityType.inPuzzleWaiting,
    text: 'Puzzle odasında seni bekliyor 🧩',
    actionLabel: 'Hemen Katıl ➔',
    actionType: 'puzzle',
  );

  static const PokiActivity inPuzzlePlaying = PokiActivity(
    type: PokiActivityType.inPuzzlePlaying,
    text: 'Puzzle çözüyor 🧩',
  );

  static const PokiActivity inLiveDoodle = PokiActivity(
    type: PokiActivityType.inLiveDoodle,
    text: 'Birlikte çizimde seni bekliyor 🎨',
    actionLabel: 'Tuvale Gir ➔',
    actionType: 'doodle',
  );

  static const PokiActivity workshop = PokiActivity(
    type: PokiActivityType.workshop,
    text: 'Atölyede çıkartma çiziyor ✨',
  );

  static const PokiActivity memories = PokiActivity(
    type: PokiActivityType.memories,
    text: 'Anılara göz atıyor 📸',
  );

  static const PokiActivity gamesHub = PokiActivity(
    type: PokiActivityType.gamesHub,
    text: 'Oyun Odasında 🎮',
  );

  static const PokiActivity inApp = PokiActivity(
    type: PokiActivityType.inApp,
    text: 'Uygulamada 🐾',
  );

  static const PokiActivity offline = PokiActivity(
    type: PokiActivityType.offline,
    text: 'Şu an uyuyor 💤',
  );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'text': text,
        'actionLabel': actionLabel,
        'actionType': actionType,
      };

  factory PokiActivity.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'chatting';
    final type = PokiActivityType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => PokiActivityType.chatting,
    );
    final text = map['text'] as String? ?? 'Sohbette 💬';
    final actionLabel = map['actionLabel'] as String?;
    final actionType = map['actionType'] as String?;

    return PokiActivity(
      type: type,
      text: text,
      actionLabel: actionLabel,
      actionType: actionType,
    );
  }
}

/// Karşı taraftan gelen sinyal (Poki-Poke veya doodle daveti).
class PokeEvent {
  const PokeEvent({required this.nickname});
  final String nickname;
}

/// Supabase Realtime ile:
///  - Presence: online / aktivite durumu / yazıyor
///  - Broadcast: Poki-Poke ve "birlikte çiz" daveti
class RoomPresence extends ChangeNotifier with WidgetsBindingObserver {
  RoomPresence._({
    required this.roomId,
    required this.myId,
    required this.partnerId,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client {
    WidgetsBinding.instance.addObserver(this);
  }

  factory RoomPresence({
    required String roomId,
    required String myId,
    required String partnerId,
    SupabaseClient? client,
  }) {
    return ensure(
      roomId: roomId,
      myId: myId,
      partnerId: partnerId,
      client: client,
    );
  }

  static RoomPresence? current;

  /// Singleton / kalıcı erişim: oda için var olanı döndürür veya yenisini üretir.
  static RoomPresence ensure({
    required String roomId,
    required String myId,
    required String partnerId,
    SupabaseClient? client,
  }) {
    if (current != null &&
        current!.roomId == roomId &&
        current!.myId == myId &&
        !current!._disposed) {
      return current!;
    }
    current?.dispose();
    final p = RoomPresence._(
      roomId: roomId,
      myId: myId,
      partnerId: partnerId,
      client: client,
    );
    current = p;
    return p;
  }

  static const String _pokeEvent = 'poki_poke';
  static const String _inviteEvent = 'doodle_invite';

  final String roomId;
  final String myId;
  final String partnerId;
  final SupabaseClient _db;

  RealtimeChannel? _channel;
  final StreamController<PokeEvent> _pokes = StreamController.broadcast();
  final StreamController<PokeEvent> _invites = StreamController.broadcast();
  bool _typing = false;
  bool _disposed = false;
  bool _joined = false;

  PokiActivity _myActivity = PokiActivity.chatting;

  bool partnerOnline = false;
  bool partnerTyping = false;
  PokiActivity partnerActivity = PokiActivity.offline;

  Stream<PokeEvent> get pokes => _pokes.stream;
  Stream<PokeEvent> get doodleInvites => _invites.stream;

  void join() {
    if (_joined && _channel != null) return;
    _joined = true;

    final channel = _db.channel(
      'room:$roomId',
      opts: RealtimeChannelConfig(key: myId),
    );
    channel
        .onPresenceSync((_) => _sync())
        .onBroadcast(event: _pokeEvent, callback: (p) => _emit(_pokes, p))
        .onBroadcast(event: _inviteEvent, callback: (p) => _emit(_invites, p))
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _track();
      }
    });
    _channel = channel;
  }

  void _emit(StreamController<PokeEvent> target, Map<String, dynamic> payload) {
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;
    final name = (data['nickname'] as String?)?.trim();
    if (!_disposed && !target.isClosed) {
      target.add(PokeEvent(
          nickname: (name == null || name.isEmpty) ? 'Biri' : name));
    }
  }

  Future<void> _broadcast(String event, String myNickname) async {
    await _channel?.sendBroadcastMessage(
      event: event,
      payload: {'from': myId, 'nickname': myNickname},
    );
  }

  Future<void> sendPoke(String myNickname) => _broadcast(_pokeEvent, myNickname);

  Future<void> sendDoodleInvite(String myNickname) =>
      _broadcast(_inviteEvent, myNickname);

  void _sync() {
    var online = false;
    var typing = false;
    PokiActivity activity = PokiActivity.offline;

    for (final state in _channel?.presenceState() ?? <SinglePresenceState>[]) {
      if (state.key != partnerId) continue;
      for (final presence in state.presences) {
        online = true;
        final p = presence.payload;
        if (p['typing'] == true) {
          typing = true;
          activity = PokiActivity.typing;
        } else if (p['activity'] is Map) {
          activity = PokiActivity.fromMap(
              (p['activity'] as Map).cast<String, dynamic>());
        } else {
          activity = PokiActivity.chatting;
        }
      }
    }

    if (!online) {
      activity = PokiActivity.offline;
    }

    if (online != partnerOnline ||
        typing != partnerTyping ||
        activity.type != partnerActivity.type ||
        activity.actionLabel != partnerActivity.actionLabel) {
      partnerOnline = online;
      partnerTyping = typing;
      partnerActivity = activity;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _track() async {
    if (_disposed || _channel == null) return;
    await _channel?.track({
      'typing': _typing,
      'activity': _myActivity.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void setTyping(bool value) {
    if (value == _typing) return;
    _typing = value;
    _track();
  }

  /// Aktiflik durumunu güncelle (Örn: quiz, atölye, çizim, anılar).
  void setActivity(PokiActivity activity) {
    if (_disposed) return;
    _myActivity = activity;
    _track();
  }

  /// Uygulama arka plana gidince çevrimdışı görün.
  Future<void> pause() async {
    _typing = false;
    await _channel?.untrack();
  }

  Future<void> resume() => _track();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      pause();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (current == this) current = null;
    _pokes.close();
    _invites.close();
    final channel = _channel;
    if (channel != null) {
      channel.untrack();
      _db.removeChannel(channel);
    }
    super.dispose();
  }
}
