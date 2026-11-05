// lib/data/models/poki_message.dart
import 'dart:convert';

import 'poki_voice_data.dart';

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

  /// 'text' | 'foggy' | 'doodle' | 'time_capsule' | 'sticker' | 'voice'
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? unlockAt;

  bool get isText => type == 'text';
  bool get isVoice => type == 'voice';
  bool get isBite => PokiBiteData.tryParse(cleanContent) != null;

  PokiBiteData? get biteData => PokiBiteData.tryParse(cleanContent);

  PokiVoiceData? get voiceData {
    if (!isVoice) return null;
    try {
      return PokiVoiceData.fromJson(cleanContent);
    } catch (_) {
      return null;
    }
  }

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

/// Tatlı ısırık (Poki-Bite) mesaj verisi.
class PokiBiteData {
  const PokiBiteData({
    required this.spot,
    required this.bittenName,
    this.senderName,
  });

  final String spot;
  final String bittenName;
  final String? senderName;

  static const String prefix = '«poki_bite:';
  static const String suffix = '»';

  static String format({
    required String spot,
    required String bittenName,
    required String senderName,
  }) {
    final jsonStr = jsonEncode({
      'spot': spot,
      'bitten': bittenName,
      'sender': senderName,
    });
    return '$prefix$jsonStr$suffix Tatlı bir ısırık verdi! 🦷 Ham!';
  }

  static PokiBiteData? tryParse(String content) {
    final start = content.indexOf(prefix);
    if (start == -1) return null;
    final end = content.indexOf(suffix, start);
    if (end == -1) return null;
    try {
      final jsonStr = content.substring(start + prefix.length, end);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PokiBiteData(
        spot: map['spot'] as String? ?? 'yanak',
        bittenName: map['bitten'] as String? ?? 'Partner',
        senderName: map['sender'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

