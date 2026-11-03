// lib/features/quiz/models/quiz_side.dart

/// Oyundaki iki taraf: bu cihazdaki oyuncu (me) ve karşı taraf (partner).
enum QuizSide {
  me,
  partner;

  QuizSide get other => this == QuizSide.me ? QuizSide.partner : QuizSide.me;
}
