// lib/features/puzzle/models/puzzle_mode.dart

enum PuzzleMode {
  coop('Birlikte Çöz', 'İkiniz de aynı tahtada, aynı anda parça yerleştirin', '🐾'),
  race('Zamana Karşı Yarış', 'Aynı parçalar, süre bitince en çok parçayı tutturan kazanır', '⏱️');

  const PuzzleMode(this.label, this.description, this.emoji);

  final String label;
  final String description;
  final String emoji;
}
