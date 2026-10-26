// lib/features/memories/widgets/memory_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/poki_memory.dart';
import '../../workshop/widgets/sticker_image.dart';

/// Mantar panoya iğnelenmiş polaroid / not kartı.
class MemoryCard extends StatelessWidget {
  const MemoryCard({
    super.key,
    required this.memory,
    this.onLongPress,
  });

  final PokiMemory memory;
  final VoidCallback? onLongPress;

  int get _seed => memory.id.codeUnits
      .fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    final seed = _seed;
    final angle = ((seed % 9) - 4) * 0.014;
    final useTape = seed.isEven;

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _body(context),
            ),
            useTape ? const _Tape() : const _Pin(),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stamp = Text(
      formatStamp(memory.createdAt),
      textAlign: TextAlign.center,
      style: textTheme.labelSmall?.copyWith(
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
        color: PokiColors.text.withOpacity(0.6),
      ),
    );

    switch (memory.kind) {
      case MemoryKind.sticker:
        return _Frame(
          color: PokiColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PokiColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: memory.stickerId == null
                      ? const SizedBox.shrink()
                      : StickerImage(stickerId: memory.stickerId!),
                ),
              ),
              const SizedBox(height: 10),
              stamp,
            ],
          ),
        );
      case MemoryKind.foggy:
        return _Frame(
          color: PokiColors.incomingBubble,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌫️ Buğulu mesaj', style: textTheme.labelSmall),
              const SizedBox(height: 6),
              Text(memory.content ?? '', style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: stamp),
            ],
          ),
        );
      default:
        return _Frame(
          color: Color.alphaBlend(
            PokiColors.primary.withOpacity(0.35),
            PokiColors.background,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📝 Not', style: textTheme.labelSmall),
              const SizedBox(height: 6),
              Text(memory.content ?? '', style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: stamp),
            ],
          ),
        );
    }
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: PokiRadius.all,
        boxShadow: [
          BoxShadow(
            color: PokiColors.text.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: PokiColors.primaryButton,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PokiColors.text.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Tape extends StatelessWidget {
  const _Tape();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: 72,
        height: 22,
        decoration: BoxDecoration(
          color: PokiColors.lampOn.withOpacity(0.7),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
