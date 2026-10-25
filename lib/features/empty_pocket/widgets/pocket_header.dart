// lib/features/empty_pocket/widgets/pocket_header.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Bağlantı yokken: kediler uyuyor, masa lambası sönük.
/// (Gerçek illüstrasyon sonra eklenecek; şimdilik ikonlarla.)
class PocketHeader extends StatelessWidget {
  const PocketHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PokiColors.surface,
        borderRadius: PokiRadius.all,
        boxShadow: PokiShadows.soft,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SleepyCat(label: 'zzz', style: textTheme.titleMedium),
              const SizedBox(width: 20),
              Icon(Icons.lightbulb_outline_rounded,
                  size: 38, color: PokiColors.text.withOpacity(0.35)),
              const SizedBox(width: 20),
              _SleepyCat(label: 'zzz', style: textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepyCat extends StatelessWidget {
  const _SleepyCat({required this.label, this.style});
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: style?.copyWith(color: PokiColors.text.withOpacity(0.5))),
        const SizedBox(height: 4),
        const Icon(Icons.pets_rounded, size: 44, color: PokiColors.primary),
      ],
    );
  }
}
