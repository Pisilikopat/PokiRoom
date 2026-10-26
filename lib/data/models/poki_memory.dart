// lib/data/models/poki_memory.dart

class MemoryKind {
  MemoryKind._();
  static const sticker = 'sticker';
  static const foggy = 'foggy';
  static const note = 'note';
}

class PokiMemory {
  const PokiMemory({
    required this.id,
    required this.roomId,
    required this.authorId,
    required this.kind,
    required this.createdAt,
    this.content,
    this.stickerId,
  });

  final String id;
  final String roomId;
  final String authorId;

  /// 'sticker' | 'foggy' | 'note'
  final String kind;
  final String? content;
  final String? stickerId;
  final DateTime createdAt;

  factory PokiMemory.fromMap(Map<String, dynamic> m) => PokiMemory(
        id: m['id'] as String,
        roomId: m['room_id'] as String,
        authorId: m['author_id'] as String,
        kind: m['kind'] as String,
        content: m['content'] as String?,
        stickerId: m['sticker_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
