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
}
