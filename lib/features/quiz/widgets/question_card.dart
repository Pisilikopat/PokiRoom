// lib/features/quiz/widgets/question_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/quiz_question.dart';
import '../theme/quiz_palette.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
  });

  final QuizQuestion question;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = question.isCustom
        ? '✍️ Özel soru'
        : '${question.category?.emoji ?? ''} ${question.category?.label ?? ''}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizPalette.surface(context),
        borderRadius: PokiRadius.all,
        boxShadow: QuizPalette.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(categoryLabel, style: QuizPalette.caption(context))),
              Text('Soru $index / $total', style: QuizPalette.caption(context)),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.text, style: QuizPalette.title(context)),
        ],
      ),
    );
  }
}
