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
  final StreamController<PokiNotification> _incoming =
      StreamController<PokiNotification>.broadcast();

  StreamSubscription<List<PokiNotification>>? _sub;
  final Set<String> _known = {};
  bool _primed = false;

  List<PokiNotification> items = const [];

  int get unreadCount => items.where((n) => !n.isRead).length;
  Stream<PokiNotification> get incoming => _incoming.stream;

  void start() {
    if (_sub != null) return;
    _sub = _repo.watchNotifications().listen(_onData, onError: (_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _primed = false;
    _known.clear();
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
