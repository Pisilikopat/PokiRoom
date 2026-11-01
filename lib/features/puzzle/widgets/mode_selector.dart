// lib/features/puzzle/widgets/mode_selector.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/puzzle_mode.dart';

/// Birlikte Çöz (Co-op) / Zamana Karşı Yarış (1v1)
class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key, required this.selected, required this.onChanged});

  final PuzzleMode selected;
  final ValueChanged<PuzzleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in PuzzleMode.values) ...[
          Expanded(
            child: Material(
              color: selected == m
                  ? PokiColors.incomingBubbleOf(context)
                  : PokiColors.surfaceOf(context),
              borderRadius: PokiRadius.all,
              child: InkWell(
                borderRadius: PokiRadius.all,
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: PokiRadius.all,
                    border: Border.all(
                      color: selected == m ? PokiColors.textOf(context) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(m.label,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(m.description, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (m != PuzzleMode.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
