// lib/features/puzzle/models/puzzle_config.dart
import 'puzzle_difficulty.dart';
import 'puzzle_image_selection.dart';
import 'puzzle_mode.dart';

/// Oyunu başlatan oyuncunun seçtiği ayarlar.
class PuzzleConfig {
  const PuzzleConfig({
    required this.image,
    required this.difficulty,
    required this.mode,
  });

  final PuzzleImageSelection image;
  final PuzzleDifficulty difficulty;
  final PuzzleMode mode;
}
