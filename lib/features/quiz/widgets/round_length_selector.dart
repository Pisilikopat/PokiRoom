// lib/features/quiz/widgets/round_length_selector.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/quiz_round_length.dart';
import '../theme/quiz_palette.dart';

/// 5 veya 10 soru
class RoundLengthSelector extends StatelessWidget {
  const RoundLengthSelector({super.key, required this.selected, required this.onChanged});

  final QuizRoundLength selected;
  final ValueChanged<QuizRoundLength> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final l in QuizRoundLength.values) ...[
          Expanded(
            child: Material(
              color: selected == l
                  ? QuizPalette.primary(context).withOpacity(0.55)
                  : QuizPalette.surface(context),
              borderRadius: PokiRadius.all,
              child: InkWell(
                borderRadius: PokiRadius.all,
                onTap: () => onChanged(l),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: PokiRadius.all,
                    border: Border.all(
                      color: selected == l
                          ? QuizPalette.text(context)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('${l.questions}',
                          style: QuizPalette.title(context).copyWith(fontSize: 28)),
                      Text(l.label, style: QuizPalette.subtitle(context)),
                      Text(l.summary, style: QuizPalette.caption(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (l != QuizRoundLength.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
