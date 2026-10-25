// lib/shared/widgets/poki_card.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';

class PokiCard extends StatelessWidget {
  const PokiCard({
    super.key,
    required this.child,
    this.color = PokiColors.surface,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: PokiRadius.all,
        boxShadow: PokiShadows.soft,
      ),
      child: child,
    );
  }
}
