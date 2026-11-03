// lib/features/quiz/logic/quiz_deck.dart
import '../models/quiz_question.dart';

/// Karıştırılmış soru listesi — tek oturum için bir deste.
class QuizDeck {
  const QuizDeck(this.questions);
  final List<QuizQuestion> questions;
  int get length => questions.length;
}
