// lib/features/puzzle/widgets/piece_tray.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../shared/widgets/poki_card.dart';

/// Parça tepsisi İSKELETİ: karışık parçaların bekleyeceği yatay şerit.
class PieceTray extends StatelessWidget {
  const PieceTray({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PokiCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parçalar ($count)',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PokiColors.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('${i + 1}',
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
