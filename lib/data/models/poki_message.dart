// lib/data/models/poki_message.dart
import 'dart:convert';
import 'dart:math' as math;

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

  String get cleanSnippet {
    if (snippet.contains('poki_bite')) {
      return '🦷 Tatlış bir ısırık';
    }
    return snippet;
  }

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
  bool get isBite => PokiBiteData.tryParse(cleanContent) != null || cleanContent.contains('poki_bite');

  PokiBiteData? get biteData => PokiBiteData.tryParse(cleanContent);

  String get displaySnippet {
    if (isBite) {
      return '🦷 Tatlış bir ısırık';
    }
    if (isVoice) return '🎙️ Sesli mesaj';
    if (type == 'sticker') return '🐾 Çıkartma';
    if (type == 'foggy') return '🌫️ Buğulu mesaj';
    if (type == 'doodle') return '🎨 Karalama';
    if (type == 'time_capsule') return '⏳ Zaman kapsülü';

    var text = cleanContent;
    if (text.contains('poki_bite')) {
      return '🦷 Tatlış bir ısırık';
    }
    if (text.length > 50) text = '${text.substring(0, 47)}...';
    return text;
  }

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

/// Yaratıcı tatlı ısırık senaryoları.
class PokiBiteScenario {
  const PokiBiteScenario({
    required this.emoji,
    required this.title,
    required this.phrase,
    this.spot = 'yanak',
  });

  final String emoji;
  final String title;
  final String phrase;
  final String spot;

  static const List<PokiBiteScenario> all = [
    PokiBiteScenario(
      emoji: '🥟',
      title: 'Pofuduk Yanak Isırığı',
      phrase: 'Hamur gibi yanakların varmış, dayanamadım ham yaptım!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '👃',
      title: 'Burun Ucu Kırtlaması',
      phrase: 'Boop! + Ham! Kaçamazsın, yakaladım!',
      spot: 'burun',
    ),
    PokiBiteScenario(
      emoji: '👂',
      title: 'Kulağa Fısıltılı Isırık',
      phrase: 'Kulağına "Seni çok seviyorum" diye fısıldayıp ısırdım!',
      spot: 'kulak',
    ),
    PokiBiteScenario(
      emoji: '🍞',
      title: 'Tost Ekmeği Kenarı Isırığı',
      phrase: 'Çıtır çıtır, sıcacık bir sevgi ısırığı!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🧛',
      title: 'Minik Vampir Kedi Saldırısı',
      phrase: 'Hırr... Kanını değil, sevgini emmeye geldim!',
      spot: 'boyun',
    ),
    PokiBiteScenario(
      emoji: '🍓',
      title: 'Çilekli Donut Isırığı',
      phrase: 'Aşırı tatlısın, şeker krizine girdim bir parça aldım!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🐾',
      title: 'Oyunbaz Pati Kemirmesi',
      phrase: 'Kediler gibi sevgiden delirip kıtlama anı!',
      spot: 'pati',
    ),
    PokiBiteScenario(
      emoji: '☁️',
      title: 'Bulut Gibi Hafif Isırık',
      phrase: 'Hiç acıtmayan, sadece sevgi ve öpücük bulaştıran cinsten!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🦁',
      title: 'Vahşi Aslan Yavrusu Hamlaması',
      phrase: 'Miyav dedi ama aslan gibi kükreyip ısırdı!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🍡',
      title: 'Mochi Kırtlaması',
      phrase: 'Yumuşacık uzayan yanaklarını pofudukça ısırdım!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🥷',
      title: 'Sinsi Pusu Isırığı',
      phrase: 'Arkasından sessizce yaklaşıp gafil avladı!',
      spot: 'omuz',
    ),
    PokiBiteScenario(
      emoji: '🍯',
      title: 'Ballı Lokma Isırığı',
      phrase: 'Bal damlayan yanaklarından kocaman bir ısırık!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🍉',
      title: 'Karpuz Dilimi Isırığı',
      phrase: 'Yaz günü gibi ferahlatıcı, şapır şupur bir ısırık!',
      spot: 'yanak',
    ),
    PokiBiteScenario(
      emoji: '🧸',
      title: 'Ayıcık Burnundan Ham',
      phrase: 'Peluş oyuncak gibi sevimlisin, dişlerime hakim olamadım!',
      spot: 'burun',
    ),
  ];

  static PokiBiteScenario getRandom() {
    final r = math.Random();
    return all[r.nextInt(all.length)];
  }
}

/// Tatlı ısırık (Poki-Bite) mesaj verisi.
class PokiBiteData {
  const PokiBiteData({
    required this.spot,
    required this.bittenName,
    this.senderName,
    this.title,
    this.phrase,
    this.emoji,
  });

  final String spot;
  final String bittenName;
  final String? senderName;
  final String? title;
  final String? phrase;
  final String? emoji;

  static const String prefix = '«poki_bite:';
  static const String suffix = '»';

  static String format({
    required String spot,
    required String bittenName,
    required String senderName,
    String? title,
    String? phrase,
    String? emoji,
  }) {
    final jsonStr = jsonEncode({
      'spot': spot,
      'bitten': bittenName,
      'sender': senderName,
      if (title != null) 'title': title,
      if (phrase != null) 'phrase': phrase,
      if (emoji != null) 'emoji': emoji,
    });
    return '$prefix$jsonStr$suffix ${title ?? "Tatlı bir ısırık verdi!"} 🦷';
  }

  static PokiBiteData? tryParse(String content) {
    int start = content.indexOf('«poki_bite:');
    int prefixLen = '«poki_bite:'.length;
    String endMarker = '»';
    if (start == -1) {
      start = content.indexOf('<<poki_bite:');
      prefixLen = '<<poki_bite:'.length;
      endMarker = '>>';
    }
    if (start == -1) return null;
    final end = content.indexOf(endMarker, start);
    if (end == -1) return null;
    try {
      final jsonStr = content.substring(start + prefixLen, end);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PokiBiteData(
        spot: map['spot'] as String? ?? 'yanak',
        bittenName: map['bitten'] as String? ?? 'Partner',
        senderName: map['sender'] as String?,
        title: map['title'] as String?,
        phrase: map['phrase'] as String?,
        emoji: map['emoji'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

