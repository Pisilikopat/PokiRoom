// lib/features/quiz/widgets/category_selector.dart
import 'package:flutter/material.dart';

import '../models/quiz_category.dart';
import '../theme/quiz_palette.dart';

/// Çoklu kategori seçimi (en az 1 kategori seçili kalır).
class QuizCategorySelector extends StatelessWidget {
  const QuizCategorySelector({super.key, required this.selected, required this.onChanged});

  final Set<QuizCategory> selected;
  final ValueChanged<Set<QuizCategory>> onChanged;

  void _toggle(QuizCategory c) {
    final next = {...selected};
    if (next.contains(c)) {
      if (next.length == 1) return; // en az bir kategori
      next.remove(c);
    } else {
      next.add(c);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in QuizCategory.values)
          FilterChip(
            selected: selected.contains(c),
            onSelected: (_) => _toggle(c),
            showCheckmark: false,
            label: Text('${c.emoji} ${c.label}'),
            labelStyle: QuizPalette.body(context).copyWith(fontWeight: FontWeight.w700),
            backgroundColor: QuizPalette.surface(context),
            selectedColor: QuizPalette.primary(context).withOpacity(0.6),
            side: BorderSide(
              color: selected.contains(c)
                  ? QuizPalette.text(context)
                  : Colors.transparent,
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
      ],
    );
  }
}
