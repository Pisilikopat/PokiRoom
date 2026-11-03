// lib/features/quiz/widgets/mode_selector.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/quiz_mode.dart';
import '../theme/quiz_palette.dart';

/// "Aklımı Oku!" / "Ruh İkizi miyiz?"
class QuizModeSelector extends StatelessWidget {
  const QuizModeSelector({super.key, required this.selected, required this.onChanged});

  final QuizMode selected;
  final ValueChanged<QuizMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in QuizMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected == m
                  ? QuizPalette.sage(context)
                  : QuizPalette.surface(context),
              borderRadius: PokiRadius.all,
              child: InkWell(
                borderRadius: PokiRadius.all,
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: PokiRadius.all,
                    border: Border.all(
                      color: selected == m
                          ? QuizPalette.text(context)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.label, style: QuizPalette.subtitle(context)),
                            const SizedBox(height: 4),
                            Text(m.description, style: QuizPalette.caption(context)),
                          ],
                        ),
                      ),
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
