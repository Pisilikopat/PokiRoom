// lib/features/puzzle/widgets/puzzle_top_bar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/puzzle_mode.dart';

/// Oyun üst çubuğu: mod, ilerleme/süre ve partner durumu.
class PuzzleTopBar extends StatelessWidget {
  const PuzzleTopBar({
    super.key,
    required this.mode,
    required this.placed,
    required this.total,
    this.partnerHere = false,
  });

  final PuzzleMode mode;
  final int placed;
  final int total;
  final bool partnerHere;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context),
        borderRadius: PokiRadius.all,
        boxShadow: PokiShadows.softOf(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('${mode.emoji} ${mode.label}',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              // TODO(adım 5): yarış modunda geri sayım sayacı
              if (mode == PuzzleMode.race)
                Text('⏱️ --:--',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : placed / total,
              minHeight: 10,
              backgroundColor: PokiColors.backgroundOf(context),
              color: PokiColors.primaryButton,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$placed / $total parça', style: textTheme.bodySmall),
              const Spacer(),
              Icon(Icons.pets_rounded,
                  size: 16,
                  color: partnerHere
                      ? PokiColors.primaryButton
                      : PokiColors.textOf(context).withOpacity(0.3)),
              const SizedBox(width: 4),
              Text(partnerHere ? 'Partner masada' : 'Partner bekleniyor...',
                  style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
