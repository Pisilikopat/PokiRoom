// lib/features/room/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/poki_message.dart';
import '../../workshop/widgets/sticker_image.dart';
import 'foggy_bubble.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onFoggyRevealed,
    this.onLongPress,
    this.onSwipeReply,
  });

  final PokiMessage message;
  final bool isMine;
  final VoidCallback? onFoggyRevealed;

  /// Uzun basınca (örn. "Anılara iğnele").
  final VoidCallback? onLongPress;

  /// Sağdan sola kaydırınca yanıtlama tetikleyicisi
  final void Function(PokiMessage message)? onSwipeReply;

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

    // Alıcı tarafında buğulu mesaj: silerek açılır.
    if (message.type == 'foggy' && !isMine) {
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

      // Çıkartma mesajı
      if (message.type == 'sticker') {
        content = Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bubbleColor.withOpacity(0.35),
                borderRadius: PokiRadius.all,
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
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: PokiRadius.all,
                boxShadow: PokiShadows.softOf(context),
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

    if (onSwipeReply == null) return content;

    // Sağdan sola kaydırarak yanıtlama (Swipe to Reply)
    return Dismissible(
      key: ValueKey('reply_dismiss_${message.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        onSwipeReply!(message);
        return false; // Mesaj silinmez, yay gibi geri yerine oturur
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PokiColors.primaryButton.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.reply_rounded,
            color: PokiColors.primaryButton,
            size: 22,
          ),
        ),
      ),
      child: content,
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
