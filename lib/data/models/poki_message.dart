// lib/data/models/poki_message.dart
import 'dart:convert';

/// Yanıtlanan mesaja dair özet bilgi.
class PokiReplyInfo {
  const PokiReplyInfo({
    required this.messageId,
    required this.senderNickname,
    required this.snippet,
  });

  final String messageId;
  final String senderNickname;
  final String snippet;

  Map<String, dynamic> toMap() => {
        'id': messageId,
        'name': senderNickname,
        'snippet': snippet,
      };

  factory PokiReplyInfo.fromMap(Map<String, dynamic> map) => PokiReplyInfo(
        messageId: (map['id'] as String?) ?? '',
        senderNickname: (map['name'] as String?) ?? '',
        snippet: (map['snippet'] as String?) ?? '',
      );
}

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

  /// 'text' | 'foggy' | 'doodle' | 'time_capsule' | 'sticker'
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? unlockAt;

  bool get isText => type == 'text';

  static const String replyDelimiter = '\n«poki_reply:';

  static String formatWithReply(String text, PokiReplyInfo reply) {
    final jsonStr = jsonEncode(reply.toMap());
    return '$text$replyDelimiter$jsonStr»';
  }

  PokiReplyInfo? get replyInfo {
    final idx = content.lastIndexOf(replyDelimiter);
    if (idx == -1) return null;
    final endIdx = content.lastIndexOf('»');
    if (endIdx <= idx) return null;
    try {
      final jsonStr = content.substring(idx + replyDelimiter.length, endIdx);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PokiReplyInfo.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String get cleanContent {
    final idx = content.lastIndexOf(replyDelimiter);
    if (idx == -1) return content;
    return content.substring(0, idx).trimRight();
  }

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
