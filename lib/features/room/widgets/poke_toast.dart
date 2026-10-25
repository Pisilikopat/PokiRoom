// lib/features/room/widgets/poke_toast.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// "Pıt! 🐾 [İsim] şu an seni düşünüyor" bildirimi.
class PokeToast extends StatelessWidget {
  const PokeToast({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: PokiColors.background,
        borderRadius: PokiRadius.all,
        border: Border.all(color: PokiColors.primary, width: 2),
        boxShadow: PokiShadows.soft,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
