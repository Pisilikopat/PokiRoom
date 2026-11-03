// lib/features/quiz/models/quiz_round_length.dart

enum QuizRoundLength {
  short(5, 'Hızlı', '5 soru'),
  long(10, 'Uzun', '10 soru');

  const QuizRoundLength(this.questions, this.label, this.summary);

  final int questions;
  final String label;
  final String summary;
}
