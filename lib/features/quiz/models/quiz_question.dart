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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'category': category?.name,
        'isCustom': isCustom,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    QuizCategory? cat;
    final catName = json['category'] as String?;
    if (catName != null) {
      for (final c in QuizCategory.values) {
        if (c.name == catName) {
          cat = c;
          break;
        }
      }
    }
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      category: cat,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
