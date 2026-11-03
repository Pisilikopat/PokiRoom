// lib/features/quiz/models/quiz_question.dart
import 'quiz_category.dart';

/// 4 şıklı soru. [category] null ise özel (kullanıcının yazdığı) sorudur.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.category,
    this.isCustom = false,
  });

  final String id;
  final String text;

  /// Tam 4 şık (A, B, C, D)
  final List<String> options;
  final QuizCategory? category;
  final bool isCustom;
}
