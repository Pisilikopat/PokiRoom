// lib/shared/widgets/poki_card.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';

class PokiCard extends StatelessWidget {
  const PokiCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? PokiColors.surfaceOf(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: PokiRadius.all,
        boxShadow: PokiShadows.softOf(context),
      ),
      child: child,
    );
  }
}
