// lib/features/puzzle/models/puzzle_difficulty.dart

enum PuzzleDifficulty {
  easy(3, 'Kolay', '🌱'),
  medium(4, 'Orta', '🌿'),
  hard(5, 'Usta', '🌸');

  const PuzzleDifficulty(this.grid, this.label, this.emoji);

  /// Izgara kenar uzunluğu (3 -> 3x3)
  final int grid;
  final String label;
  final String emoji;

  int get pieceCount => grid * grid;
  String get summary => '${grid}x$grid · $pieceCount parça';

  String? get badge => switch (this) {
        PuzzleDifficulty.easy => null,
        PuzzleDifficulty.medium => 'Önerilen',
        PuzzleDifficulty.hard => 'Meydan Okuma',
      };

  static const PuzzleDifficulty recommended = PuzzleDifficulty.medium;
}
