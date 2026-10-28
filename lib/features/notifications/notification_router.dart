// lib/features/notifications/notification_router.dart
import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../data/models/poki_notification.dart';
import '../memories/memories_screen.dart';
import '../workshop/doodle_studio_screen.dart';

/// Bildirime dokununca ilgili ekrana götürür.
///  - memory_pinned  -> Anılar
///  - sticker_created -> Atölye (Çıkartmalarım)
///  - poke / foggy_revealed / knock -> Sohbet (ana ekran)
class NotificationRouter {
  NotificationRouter._();

  static void open(PokiNotification n) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    final roomId = n.roomId;

    switch (n.type) {
      case NotificationType.memoryPinned:
        if (roomId != null) {
          nav.push(MaterialPageRoute<void>(
            builder: (_) => MemoriesScreen(roomId: roomId),
          ));
        }
      case NotificationType.stickerCreated:
        if (roomId != null) {
          nav.push(MaterialPageRoute<void>(
            builder: (_) => DoodleStudioScreen(roomId: roomId),
          ));
        }
      case NotificationType.poke:
      case NotificationType.foggyRevealed:
      case NotificationType.knock:
        nav.popUntil((route) => route.isFirst);
    }
  }
}
