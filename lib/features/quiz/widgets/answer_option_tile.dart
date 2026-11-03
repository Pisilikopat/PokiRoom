// lib/features/quiz/widgets/answer_option_tile.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../theme/quiz_palette.dart';

/// Şıkkın görsel durumu.
enum OptionVisual {
  idle,
  selected, // henüz kilitlenmemiş seçimim
  lockedMine, // kilitlenmiş seçimim 🔒
  fogged, // buğulu (Ruh İkizi modunda iki taraf işaretleyene kadar)
  correct,
  wrong,
  partnerPick, // partnerin seçimi (açıklanınca)
}

class AnswerOptionTile extends StatelessWidget {
  const AnswerOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.visual,
    this.onTap,
  });

  final String letter;
  final String text;
  final OptionVisual visual;
  final VoidCallback? onTap;

  Color _color(BuildContext c) => switch (visual) {
        OptionVisual.idle || OptionVisual.fogged => QuizPalette.surface(c),
        OptionVisual.selected => QuizPalette.primary(c).withOpacity(0.55),
        OptionVisual.lockedMine => QuizPalette.primary(c).withOpacity(0.8),
        OptionVisual.correct => QuizPalette.correct(c),
        OptionVisual.wrong => QuizPalette.wrong(c),
        OptionVisual.partnerPick => QuizPalette.sage(c),
      };

  Widget? _trailing(BuildContext c) => switch (visual) {
        OptionVisual.lockedMine => const Icon(Icons.lock_rounded, size: 20),
        OptionVisual.correct => const Icon(Icons.check_circle_rounded, size: 22),
        OptionVisual.wrong => const Icon(Icons.cancel_rounded, size: 22),
        OptionVisual.partnerPick => const Icon(Icons.pets_rounded, size: 20),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final fogged = visual == OptionVisual.fogged;

    Widget content = Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: QuizPalette.background(context).withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Text(letter,
              style: QuizPalette.subtitle(context)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: QuizPalette.body(context))),
        if (_trailing(context) != null)
          IconTheme(
            data: IconThemeData(color: QuizPalette.text(context)),
            child: _trailing(context)!,
          ),
      ],
    );

    if (fogged) {
      // Buğulu: bulanık metin + sis ikonu (silme/açılma animasyonu sonraki adımda)
      content = Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: content,
          ),
          const Text('🌫️', style: TextStyle(fontSize: 22)),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _color(context),
        borderRadius: PokiRadius.all,
        boxShadow: QuizPalette.softShadow(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: PokiRadius.all,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: content,
          ),
        ),
      ),
    );
  }
}
