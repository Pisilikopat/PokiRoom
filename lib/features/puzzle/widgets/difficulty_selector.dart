// lib/features/puzzle/widgets/difficulty_selector.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/puzzle_difficulty.dart';

/// Kolay (3x3) / Orta (4x4, önerilen) / Usta (5x5).
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PuzzleDifficulty selected;
  final ValueChanged<PuzzleDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final d in PuzzleDifficulty.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected == d
                  ? PokiColors.primary.withOpacity(0.45)
                  : PokiColors.surfaceOf(context),
              borderRadius: PokiRadius.all,
              child: InkWell(
                borderRadius: PokiRadius.all,
                onTap: () => onChanged(d),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: PokiRadius.all,
                    border: Border.all(
                      color: selected == d ? PokiColors.textOf(context) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CustomPaint(painter: _GridPreviewPainter(d.grid)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${d.emoji} ${d.label}',
                                    style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                if (d.badge != null) ...[
                                  const SizedBox(width: 8),
                                  _Badge(text: d.badge!),
                                ],
                              ],
                            ),
                            Text(d.summary, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (selected == d)
                        const Icon(Icons.check_circle_rounded,
                            color: PokiColors.primaryButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PokiColors.lampOn,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

/// n x n ızgaranın küçük önizlemesi
class _GridPreviewPainter extends CustomPainter {
  _GridPreviewPainter(this.n);
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 2.0;
    final cell = (size.width - gap * (n - 1)) / n;
    final paint = Paint()..color = PokiColors.primaryButton.withOpacity(0.7);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * (cell + gap), r * (cell + gap), cell, cell);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPreviewPainter old) => old.n != n;
}
