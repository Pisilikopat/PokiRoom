// lib/data/models/poki_sticker.dart

class PokiSticker {
  const PokiSticker({
    required this.id,
    required this.roomId,
    required this.creatorId,
    required this.storagePath,
    required this.width,
    required this.height,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String creatorId;
  final String storagePath;
  final int width;
  final int height;
  final DateTime createdAt;

  factory PokiSticker.fromMap(Map<String, dynamic> m) => PokiSticker(
        id: m['id'] as String,
        roomId: m['room_id'] as String,
        creatorId: m['creator_id'] as String,
        storagePath: m['storage_path'] as String,
        width: (m['width'] as num).toInt(),
        height: (m['height'] as num).toInt(),
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
