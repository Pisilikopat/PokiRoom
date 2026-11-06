import '../models/poki_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// lib/data/services/notification_center.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/poki_notification.dart';
import '../repositories/notification_repository.dart';

/// Uygulama genelinde tek bildirim akışı:
///  - [items]: son bildirimler (Aktivite Merkezi için)
///  - [unreadCount]: rozet sayısı
///  - [incoming]: oturum sırasında YENİ gelen bildirimler (canlı banner için)
class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  /// Yeniden bağlanmada gelen eski kayıtlar banner olmasın.
  static const Duration _bannerWindow = Duration(minutes: 5);

  final NotificationRepository _repo = NotificationRepository.instance;
  final SupabaseClient _db = Supabase.instance.client;
  final StreamController<PokiNotification> _incoming =
      StreamController<PokiNotification>.broadcast();

  StreamSubscription<List<PokiNotification>>? _sub;
  StreamSubscription<List<PokiMessage>>? _msgSub;
  final Set<String> _known = {};
  final Set<String> _knownMsgIds = {};
  bool _primed = false;
  bool _msgPrimed = false;
  String? _roomId;
  String? _partnerNickname;

  List<PokiNotification> items = const [];

  int get unreadCount => items.where((n) => !n.isRead).length;
  Stream<PokiNotification> get incoming => _incoming.stream;

  void start() {
    if (_sub == null) {
      _sub = _repo.watchNotifications().listen(_onData, onError: (_) {});
    }
    _autoBindRoom();
  }

  void bindRoom(String roomId, {String? partnerNickname}) {
    if (_roomId == roomId && _msgSub != null) {
      if (partnerNickname != null) _partnerNickname = partnerNickname;
      return;
    }
    _roomId = roomId;
    if (partnerNickname != null) _partnerNickname = partnerNickname;
    _startMessageWatch();
  }

  Future<void> _autoBindRoom() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;
      final row = await _db
          .from('users')
          .select('current_room_id')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && row['current_room_id'] != null) {
        bindRoom(row['current_room_id'] as String);
      }
    } catch (_) {}
  }

  void _startMessageWatch() {
    _msgSub?.cancel();
    _msgPrimed = false;
    _knownMsgIds.clear();

    if (_roomId == null) return;
    final myId = _db.auth.currentUser?.id;
    if (myId == null) return;

    _msgSub = _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', _roomId!)
        .order('created_at', ascending: false)
        .limit(10)
        .map((rows) => rows.map(PokiMessage.fromMap).toList())
        .listen((list) {
      if (!_msgPrimed) {
        _knownMsgIds.addAll(list.map((m) => m.id));
        _msgPrimed = true;
        return;
      }

      final now = DateTime.now();
      for (final msg in list.reversed) {
        final isNew = _knownMsgIds.add(msg.id);
        if (isNew && msg.senderId != myId) {
          if (now.difference(msg.createdAt).inMinutes < 2) {
            final senderNick = _partnerNickname ?? 'Partnerin';
            final notification = PokiNotification(
              id: 'msg_${msg.id}',
              roomId: _roomId,
              senderId: msg.senderId,
              receiverId: myId,
              type: NotificationType.message,
              title: '🐾 $senderNick',
              body: msg.displaySnippet,
              isRead: false,
              createdAt: msg.createdAt,
            );
            _incoming.add(notification);
          }
        }
      }
    }, onError: (_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _msgSub?.cancel();
    _msgSub = null;
    _primed = false;
    _msgPrimed = false;
    _known.clear();
    _knownMsgIds.clear();
    items = const [];
    notifyListeners();
  }

  void _onData(List<PokiNotification> list) {
    items = list;
    if (!_primed) {
      // İlk yükleme: mevcutlar bilinen sayılır, banner çıkmaz.
      _known.addAll(list.map((n) => n.id));
      _primed = true;
    } else {
      final now = DateTime.now();
      // Eskiden yeniye doğru sırayla yayınla
      for (final n in list.reversed) {
        final isNew = _known.add(n.id);
        if (isNew && !n.isRead && now.difference(n.createdAt) < _bannerWindow) {
          _incoming.add(n);
        }
      }
    }
    notifyListeners();
  }
}
