// lib/data/models/poki_message.dart

class PokiMessage {
  const PokiMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.unlockAt,
  });

  final String id;
  final String roomId;
  final String senderId;

  /// 'text' | 'foggy' | 'doodle' | 'time_capsule'
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? unlockAt;

  bool get isText => type == 'text';

  factory PokiMessage.fromMap(Map<String, dynamic> m) => PokiMessage(
        id: m['id'] as String,
        roomId: m['room_id'] as String,
        senderId: m['sender_id'] as String,
        type: (m['message_type'] as String?) ?? 'text',
        content: (m['content'] as String?) ?? '',
        isRead: (m['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        unlockAt: m['unlock_at'] == null
            ? null
            : DateTime.parse(m['unlock_at'] as String).toLocal(),
      );
}
