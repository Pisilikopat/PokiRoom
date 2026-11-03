// lib/features/quiz/models/quiz_category.dart

enum QuizCategory {
  daily('Günlük Alışkanlıklar', '☕'),
  memories('Anılar & Geçmiş', '📸'),
  dreams('Hayaller & Eğlenceli İkilemler', '✨');

  const QuizCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}
