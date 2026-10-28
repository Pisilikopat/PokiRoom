// lib/features/notifications/widgets/activity_bell_button.dart
import 'package:flutter/material.dart';

import '../../../data/services/notification_center.dart';
import 'activity_center_sheet.dart';

/// Okunmamış sayaç rozetli çan butonu. Dokununca Aktivite Merkezi açılır.
/// HomeScreen AppBar'ına ve RoomHeader'a doğrudan konabilir.
class ActivityBellButton extends StatelessWidget {
  const ActivityBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationCenter.instance,
      builder: (context, _) {
        final count = NotificationCenter.instance.unreadCount;
        return IconButton(
          tooltip: 'Aktivite Merkezi',
          onPressed: () => ActivityCenterSheet.show(context),
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFE85D4F),
            textColor: Colors.white,
            label: Text(count > 9 ? '9+' : '$count'),
            child: const Icon(Icons.notifications_rounded),
          ),
        );
      },
    );
  }
}
