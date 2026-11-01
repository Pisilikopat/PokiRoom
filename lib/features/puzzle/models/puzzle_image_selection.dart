// lib/features/puzzle/models/puzzle_image_selection.dart
import 'dart:typed_data';

enum PuzzleImageSourceType { gallery, cat, memory }

/// Seçilen puzzle görseli. Web + mobil uyumlu: dosya yolu yerine bayt kullanılır.
class PuzzleImageSelection {
  const PuzzleImageSelection._(
    this.type, {
    this.catId,
    this.bytes,
    this.memoryId,
  });

  factory PuzzleImageSelection.cat(String catId) =>
      PuzzleImageSelection._(PuzzleImageSourceType.cat, catId: catId);

  factory PuzzleImageSelection.gallery(Uint8List bytes) =>
      PuzzleImageSelection._(PuzzleImageSourceType.gallery, bytes: bytes);

  /// İleride: Anılar panosundaki bir görsel
  factory PuzzleImageSelection.memory(String memoryId) =>
      PuzzleImageSelection._(PuzzleImageSourceType.memory, memoryId: memoryId);

  final PuzzleImageSourceType type;
  final String? catId;
  final Uint8List? bytes;
  final String? memoryId;
}
