// lib/features/room/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/poki_message.dart';
import '../../workshop/widgets/sticker_image.dart';
import 'bite_bubble.dart';
import 'foggy_bubble.dart';
import 'voice_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onFoggyRevealed,
    this.onLongPress,
    this.onSwipeReply,
    this.isHighlighted = false,
    this.onBiteBack,
    this.partnerNickname = 'Partnerin',
  });

  final PokiMessage message;
  final bool isMine;
  final VoidCallback? onFoggyRevealed;

  /// Uzun basınca (örn. "Anılara iğnele").
  final VoidCallback? onLongPress;

  /// Kaydırınca yanıtlama tetikleyicisi
  final void Function(PokiMessage message)? onSwipeReply;

  /// Arama sonucunda vurgulanıp vurgulanmadığı
  final bool isHighlighted;

  /// Karşılık ısırığı verme aksiyonu
  final VoidCallback? onBiteBack;
  final String partnerNickname;

  Widget _meta(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatClock(message.createdAt),
            style: textTheme.labelSmall
                ?.copyWith(color: PokiColors.text.withOpacity(0.6))),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.done_all_rounded,
            size: 14,
            color: PokiColors.text.withOpacity(message.isRead ? 0.9 : 0.35),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    // Tatlı ısırık mesajı
    if (message.isBite) {
      content = Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: BiteBubble(
            message: message,
            isMine: isMine,
            meta: _meta(context),
            onBiteBack: onBiteBack,
            partnerNickname: partnerNickname,
          ),
        ),
      );
    } else if (message.type == 'foggy' && !isMine) {
      content = GestureDetector(
        onLongPress: onLongPress,
        child: FoggyBubble(
          key: ValueKey(message.id),
          message: message,
          onRevealed: onFoggyRevealed ?? () {},
        ),
      );
    } else {
      final textTheme = Theme.of(context).textTheme;
      final maxWidth = MediaQuery.of(context).size.width * 0.75;

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bubbleColor = isMine
          ? (isDark ? PokiColors.darkPrimary : PokiColors.primary)
          : (isDark ? PokiColors.darkIncomingBubble : PokiColors.incomingBubble);

      // Sesli mesaj
      if (message.type == 'voice') {
        final voiceData = message.voiceData;
        if (voiceData != null) {
          content = Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: onLongPress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: PokiRadius.all,
                  border: isHighlighted
                      ? Border.all(color: const Color(0xFFFFB74D), width: 2.2)
                      : null,
                  boxShadow: isHighlighted
                      ? [
                          ...PokiShadows.softOf(context),
                          const BoxShadow(
                            color: Color(0x77FFB74D),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ]
                      : PokiShadows.softOf(context),
                ),
                child: VoiceMessageBubble(
                  voice: voiceData,
                  isMine: isMine,
                  meta: _meta(context),
                ),
              ),
            ),
          );
        } else {
          content = const SizedBox.shrink();
        }
      } else if (message.type == 'sticker') {
        content = Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bubbleColor.withOpacity(0.35),
                borderRadius: PokiRadius.all,
                border: isHighlighted
                    ? Border.all(color: const Color(0xFFFFB74D), width: 2.2)
                    : null,
                boxShadow: isHighlighted
                    ? [
                        ...PokiShadows.softOf(context),
                        const BoxShadow(
                          color: Color(0x77FFB74D),
                          blurRadius: 14,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StickerImage(stickerId: message.content, size: 150),
                  const SizedBox(height: 2),
                  _meta(context),
                ],
              ),
            ),
          ),
        );
      } else {
        final isKnownType = message.type == 'text' || message.type == 'foggy';
        final body = isKnownType
            ? message.cleanContent
            : 'Bu mesaj türü yakında açılacak 🐾';
        final reply = message.replyInfo;

        content = Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              constraints: BoxConstraints(maxWidth: maxWidth),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: PokiRadius.all,
                border: isHighlighted
                    ? Border.all(color: const Color(0xFFFFB74D), width: 2.2)
                    : null,
                boxShadow: isHighlighted
                    ? [
                        ...PokiShadows.softOf(context),
                        const BoxShadow(
                          color: Color(0x77FFB74D),
                          blurRadius: 14,
                          spreadRadius: 3,
                        ),
                      ]
                    : PokiShadows.softOf(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.type == 'foggy')
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text('🌫️ Buğulu mesaj', style: textTheme.labelSmall),
                    ),
                  if (reply != null) ...[
                    _QuotedReplyBox(reply: reply, isDark: isDark),
                    const SizedBox(height: 6),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(body, style: textTheme.bodyLarge),
                  ),
                  const SizedBox(height: 4),
                  _meta(context),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Henüz açılmamış buğulu mesajlarda silme hareketine öncelik verilir
    if (onSwipeReply == null ||
        (message.type == 'foggy' && !isMine && !message.isRead)) {
      return content;
    }

    // Özelleştirilmiş Swipe to Reply sarmalayıcısı
    return _SwipeToReplyWrapper(
      key: ValueKey('reply_swipe_${message.id}'),
      isMine: isMine,
      onTrigger: () => onSwipeReply!(message),
      child: content,
    );
  }
}

/// Mesajı kaydırarak yanıtlama sarmalayıcısı (Swipe to Reply).
/// - Karşı tarafın mesajı: Soldan sağa kaydırılır.
/// - Kendi mesajımız: Sağdan sola kaydırılır.
/// - Düşük çekme eşiği (~46px) ile konforlu ve hızlı tetiklenir.
/// - Eşik aşıldığında görsel geri bildirim (büyüme, parıltı, renk değişimi) ve haptik titreşim verir.
class _SwipeToReplyWrapper extends StatefulWidget {
  const _SwipeToReplyWrapper({
    super.key,
    required this.child,
    required this.isMine,
    required this.onTrigger,
  });

  final Widget child;
  final bool isMine;
  final VoidCallback onTrigger;

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  static const double _threshold = 46.0;
  static const double _maxDrag = 74.0;

  late final AnimationController _animController;
  Animation<double>? _slideAnimation;
  double _dragOffset = 0.0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animController.addListener(() {
      if (_slideAnimation != null) {
        setState(() {
          _dragOffset = _slideAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;

    if (!widget.isMine) {
      // Karşı tarafın mesajı: Soldan sağa çekilir (delta > 0)
      double next = _dragOffset + delta;
      if (next < 0) next = 0;
      if (next > _maxDrag) {
        next = _maxDrag + (next - _maxDrag) * 0.2;
      }
      _dragOffset = next;
    } else {
      // Kendi mesajımız: Sağdan sola çekilir (delta < 0)
      double next = _dragOffset + delta;
      if (next > 0) next = 0;
      if (next < -_maxDrag) {
        next = -_maxDrag + (next - (-_maxDrag)) * 0.2;
      }
      _dragOffset = next;
    }

    final distance = _dragOffset.abs();
    final reached = distance >= _threshold;
    if (reached != _triggered) {
      setState(() => _triggered = reached);
      if (reached) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    } else {
      setState(() {});
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_triggered) {
      widget.onTrigger();
      HapticFeedback.lightImpact();
    }
    _reset();
  }

  void _onHorizontalDragCancel() {
    _reset();
  }

  void _reset() {
    if (_dragOffset == 0.0) {
      if (_triggered) setState(() => _triggered = false);
      return;
    }
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _triggered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final distance = _dragOffset.abs();
    final progress = (distance / _threshold).clamp(0.0, 1.0);
    final isVisible = distance > 0.5 || _animController.isAnimating;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragDown: _onHorizontalDragDown,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragCancel: _onHorizontalDragCancel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:
            widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (isVisible)
            Positioned.fill(
              child: Align(
                alignment: widget.isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.isMine ? 0 : 2.0 + progress * 6.0,
                    right: widget.isMine ? 2.0 + progress * 6.0 : 0,
                  ),
                  child: _SwipeReplyIndicator(
                    isMine: widget.isMine,
                    progress: progress,
                    triggered: _triggered,
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Yanıtlama tetikleyici ikon göstergesi.
/// Kullanıcı mesajı çektikçe belirir, eşiğe ulaştığında büyüyüp renkle parlayarak
/// kullanıcıya yanıt modunun aktifleştiğini kesin olarak bildirir.
class _SwipeReplyIndicator extends StatelessWidget {
  const _SwipeReplyIndicator({
    required this.isMine,
    required this.progress,
    required this.triggered,
  });

  final bool isMine;
  final double progress;
  final bool triggered;

  @override
  Widget build(BuildContext context) {
    final opacity = (progress * 1.8).clamp(0.0, 1.0);
    final scale = triggered ? 1.25 : (0.75 + 0.25 * progress);

    return Opacity(
      opacity: opacity,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: triggered
                ? PokiColors.primaryButton
                : PokiColors.primaryButton.withOpacity(0.18 + 0.15 * progress),
            shape: BoxShape.circle,
            border: Border.all(
              color: triggered
                  ? Colors.white
                  : PokiColors.primaryButton
                      .withOpacity(0.35 + 0.25 * progress),
              width: triggered ? 2.0 : 1.2,
            ),
            boxShadow: triggered
                ? [
                    BoxShadow(
                      color: PokiColors.primaryButton.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Transform.flip(
              // Karşı tarafın mesajında soldan sağa çekildiğinde ok mesaj yönüne (sağa) bakar
              // Kendi mesajımızda sağdan sola çekildiğinde ok mesaj yönüne (sola) bakar
              flipX: !isMine,
              child: Icon(
                Icons.reply_rounded,
                size: 19,
                color: triggered
                    ? Colors.white
                    : PokiColors.primaryButton.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuotedReplyBox extends StatelessWidget {
  const _QuotedReplyBox({required this.reply, required this.isDark});
  final PokiReplyInfo reply;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isDark ? PokiColors.lampOn : PokiColors.primaryButton,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderNickname,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? PokiColors.lampOn : PokiColors.primaryButton,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: PokiColors.textOf(context).withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}
