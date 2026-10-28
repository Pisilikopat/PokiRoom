// lib/shared/widgets/poki_notification_overlay.dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_center.dart';

/// Uygulamanın TÜM ekranlarının üstünde, partnerin hareketlerini
/// yukarıdan kayan sevimli bir kartla gösterir.
///
/// Kullanım (MaterialApp içinde):
/// ```dart
/// builder: (context, child) => PokiNotificationOverlay(
///   onTap: NotificationRouter.open,
///   child: child ?? const SizedBox.shrink(),
/// ),
/// ```
class PokiNotificationOverlay extends StatefulWidget {
  const PokiNotificationOverlay({
    super.key,
    required this.child,
    required this.onTap,
    this.displayDuration = const Duration(seconds: 4),
  });

  final Widget child;

  /// Banner'a dokunulunca ilgili ekrana yönlendirme.
  final void Function(PokiNotification notification) onTap;
  final Duration displayDuration;

  @override
  State<PokiNotificationOverlay> createState() =>
      _PokiNotificationOverlayState();
}

class _PokiNotificationOverlayState extends State<PokiNotificationOverlay> {
  final Queue<PokiNotification> _queue = Queue();
  StreamSubscription<PokiNotification>? _sub;
  Timer? _timer;
  PokiNotification? _current;

  @override
  void initState() {
    super.initState();
    _sub = NotificationCenter.instance.incoming.listen(_enqueue);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _enqueue(PokiNotification n) {
    _queue.add(n);
    if (_current == null) _showNext();
  }

  void _showNext() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    setState(() => _current = _queue.removeFirst());
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _timer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _current = null);
    if (_queue.isNotEmpty) {
      // Kapanış animasyonunun bitmesini bekle, sonra sıradakini göster.
      Timer(const Duration(milliseconds: 350), _showNext);
    }
  }

  void _handleTap() {
    final n = _current;
    if (n == null) return;
    _dismiss();
    NotificationRepository.instance.markAsRead(n.id).catchError((_) {});
    widget.onTap(n);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: current == null
                    ? const SizedBox.shrink(key: ValueKey('none'))
                    : _Banner(
                        key: ValueKey(current.id),
                        notification: current,
                        onTap: _handleTap,
                        onDismiss: _dismiss,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final PokiNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        // Yukarı kaydırarak kapat
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -200) onDismiss();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: PokiColors.background,
            borderRadius: PokiRadius.all,
            border: Border.all(color: PokiColors.primary, width: 2),
            boxShadow: PokiShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PokiColors.primary.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: Text(notification.type.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
