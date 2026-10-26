// lib/features/room/widgets/message_bubble.dart
import 'package:flutter/material.dart';

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
  });

  final PokiMessage message;
  final bool isMine;
  final VoidCallback? onFoggyRevealed;

  /// Uzun basınca (örn. "Anılara iğnele").
  final VoidCallback? onLongPress;

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
    // Alıcı tarafında buğulu mesaj: silerek açılır. (Fog üzerindeyken uzun basış
    // devre dışıdır; açıldıktan sonra üst katman çalışır.)
    if (message.type == 'foggy' && !isMine) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: FoggyBubble(
          key: ValueKey(message.id),
          message: message,
          onRevealed: onFoggyRevealed ?? () {},
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // Çıkartma mesajı: content = sticker id
    if (message.type == 'sticker') {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isMine ? PokiColors.primary : PokiColors.incomingBubble)
                  .withOpacity(0.35),
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
    }

    // doodle / time_capsule sonraki adımlarda gelecek.
    final isKnownType = message.type == 'text' || message.type == 'foggy';
    final body = isKnownType ? message.content : 'Bu mesaj türü yakında açılacak 🐾';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: BoxDecoration(
            color: isMine ? PokiColors.primary : PokiColors.incomingBubble,
            borderRadius: PokiRadius.all,
            boxShadow: PokiShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == 'foggy')
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('🌫️ Buğulu mesaj', style: textTheme.labelSmall),
                ),
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
