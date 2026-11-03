// lib/features/quiz/widgets/reaction_cat.dart
import 'package:flutter/material.dart';

import '../theme/quiz_palette.dart';

enum CatReaction { correct, wrong, soulmates, opposites }

/// Sonuç tepkisi kedisi. (Emoji + zıplama animasyonu.
/// Konfeti/kalp ve gerçek kedi çizimi sonraki adımlarda.)
class ReactionCat extends StatelessWidget {
  const ReactionCat({super.key, required this.reaction, this.caption});

  final CatReaction reaction;

  /// Verilmezse tepkiye göre varsayılan yazı kullanılır.
  final String? caption;

  (String, String) get _content => switch (reaction) {
        CatReaction.correct => ('😻', 'Doğru bildin! +10 Pati Puanı 🐾'),
        CatReaction.wrong => ('🙈', 'Hmm... kafamı kaşıyorum 🤔'),
        CatReaction.soulmates => ('💖🐱', 'Ruh İkizi 💖'),
        CatReaction.opposites => ('🐱↔️🐱', 'Zıt Kutuplar 🐱'),
      };

  @override
  Widget build(BuildContext context) {
    final (emoji, defaultCaption) = _content;
    return TweenAnimationBuilder<double>(
      key: ValueKey(reaction),
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 6),
          Text(caption ?? defaultCaption,
              textAlign: TextAlign.center, style: QuizPalette.subtitle(context)),
        ],
      ),
    );
  }
}
