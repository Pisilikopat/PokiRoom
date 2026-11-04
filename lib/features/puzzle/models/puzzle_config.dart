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

  Map<String, dynamic> toJson() => {
        'image': image.toJson(),
        'difficulty': difficulty.name,
        'mode': mode.name,
      };

  factory PuzzleConfig.fromJson(Map<String, dynamic> json) {
    final imageMap =
        (json['image'] as Map?)?.cast<String, dynamic>() ?? {};
    final diffStr = json['difficulty'] as String? ?? 'recommended';
    final modeStr = json['mode'] as String? ?? 'coop';

    final difficulty = PuzzleDifficulty.values.firstWhere(
      (e) => e.name == diffStr,
      orElse: () => PuzzleDifficulty.recommended,
    );
    final mode = PuzzleMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => PuzzleMode.coop,
    );

    return PuzzleConfig(
      image: PuzzleImageSelection.fromJson(imageMap),
      difficulty: difficulty,
      mode: mode,
    );
  }
}
