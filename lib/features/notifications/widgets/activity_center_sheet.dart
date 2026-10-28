// lib/features/notifications/widgets/activity_center_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/poki_notification.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/notification_center.dart';
import '../notification_router.dart';

/// Partnerin geçmiş hareketlerini listeleyen Aktivite Merkezi alt paneli.
class ActivityCenterSheet extends StatelessWidget {
  const ActivityCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (_) => const ActivityCenterSheet(),
    );
  }

  Future<void> _markAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationRepository.instance.markAllAsRead();
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Okundu işaretlenemedi, tekrar dener misin?'),
        ));
    }
  }

  void _open(BuildContext context, PokiNotification n) {
    Navigator.of(context).pop();
    if (!n.isRead) {
      NotificationRepository.instance.markAsRead(n.id).catchError((_) {});
    }
    NotificationRouter.open(n);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final center = NotificationCenter.instance;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Aktivite Merkezi 🐾', style: textTheme.titleLarge),
                ),
                ListenableBuilder(
                  listenable: center,
                  builder: (context, _) => TextButton(
                    onPressed:
                        center.unreadCount > 0 ? () => _markAll(context) : null,
                    child: const Text('Tümünü Okundu Say'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListenableBuilder(
                listenable: center,
                builder: (context, _) {
                  final items = center.items;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Henüz bir hareket yok 🐱\nPartnerin bir şey yapınca burada görünecek.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ActivityTile(
                      notification: items[i],
                      onTap: () => _open(context, items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.notification, required this.onTap});

  final PokiNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.isRead;
    return Material(
      color: unread
          ? PokiColors.incomingBubble.withOpacity(0.6)
          : PokiColors.surface,
      borderRadius: PokiRadius.all,
      child: InkWell(
        borderRadius: PokiRadius.all,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PokiColors.primary.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: Text(notification.type.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.body,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelative(notification.createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE85D4F),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
