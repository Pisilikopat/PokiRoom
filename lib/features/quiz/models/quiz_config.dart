// lib/features/quiz/models/quiz_config.dart
import 'quiz_category.dart';
import 'quiz_mode.dart';
import 'quiz_question.dart';
import 'quiz_round_length.dart';

/// Oyunu başlatan oyuncunun lobide seçtiği ayarlar.
class QuizConfig {
  const QuizConfig({
    required this.mode,
    required this.categories,
    required this.length,
    this.customQuestions = const [],
  });

  final QuizMode mode;
  final Set<QuizCategory> categories;
  final QuizRoundLength length;
  final List<QuizQuestion> customQuestions;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'categories': categories.map((c) => c.name).toList(),
        'length': length.name,
        'customQuestions': customQuestions.map((q) => q.toJson()).toList(),
      };

  factory QuizConfig.fromJson(Map<String, dynamic> json) {
    QuizMode mode = QuizMode.readMyMind;
    final modeName = json['mode'] as String?;
    if (modeName != null) {
      for (final m in QuizMode.values) {
        if (m.name == modeName) {
          mode = m;
          break;
        }
      }
    }

    final cats = <QuizCategory>{};
    final catList = json['categories'] as List?;
    if (catList != null) {
      for (final item in catList) {
        for (final c in QuizCategory.values) {
          if (c.name == item.toString()) {
            cats.add(c);
            break;
          }
        }
      }
    }

    QuizRoundLength len = QuizRoundLength.short;
    final lenName = json['length'] as String?;
    if (lenName != null) {
      for (final l in QuizRoundLength.values) {
        if (l.name == lenName) {
          len = l;
          break;
        }
      }
    }

    final customs = <QuizQuestion>[];
    final customList = json['customQuestions'] as List?;
    if (customList != null) {
      for (final q in customList) {
        if (q is Map<String, dynamic>) {
          customs.add(QuizQuestion.fromJson(q));
        } else if (q is Map) {
          customs.add(QuizQuestion.fromJson(q.cast<String, dynamic>()));
        }
      }
    }

    return QuizConfig(
      mode: mode,
      categories: cats,
      length: len,
      customQuestions: customs,
    );
  }
}
