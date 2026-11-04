// lib/features/puzzle/models/puzzle_image_selection.dart
import 'dart:convert';
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

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'catId': catId,
        'memoryId': memoryId,
        if (bytes != null) 'bytesBase64': base64Encode(bytes!),
      };

  factory PuzzleImageSelection.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'cat';
    final type = PuzzleImageSourceType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => PuzzleImageSourceType.cat,
    );
    final catId = json['catId'] as String?;
    final memoryId = json['memoryId'] as String?;
    final bytesStr = json['bytesBase64'] as String?;
    Uint8List? bytes;
    if (bytesStr != null) {
      try {
        bytes = base64Decode(bytesStr);
      } catch (_) {}
    }
    return PuzzleImageSelection._(
      type,
      catId: catId,
      bytes: bytes,
      memoryId: memoryId,
    );
  }
}
