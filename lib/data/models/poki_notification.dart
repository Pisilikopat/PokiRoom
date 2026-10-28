// lib/data/models/poki_notification.dart

/// Partnerin hareketlerini temsil eden bildirim türleri.
enum NotificationType {
  poke('poke', '🐾'),
  stickerCreated('sticker_created', '🎨'),
  memoryPinned('memory_pinned', '📌'),
  foggyRevealed('foggy_revealed', '👀'),
  knock('knock', '🚪');

  const NotificationType(this.wire, this.emoji);

  /// Veritabanındaki `type` değeri
  final String wire;
  final String emoji;

  static NotificationType? fromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }

  /// Gönderenin adına göre başlık + metin üretir.
  ({String title, String body}) compose(String senderName) {
    final n = senderName.length > 40
        ? '${senderName.substring(0, 40)}…'
        : senderName;
    return switch (this) {
      NotificationType.poke =>
        (title: 'Pıt!', body: '🐾 $n seni düşünüyor! (Pıt)'),
      NotificationType.stickerCreated =>
        (title: 'Yeni çıkartma', body: '🎨 $n yeni bir çıkartma çizdi!'),
      NotificationType.memoryPinned =>
        (title: 'Yeni hatıra', body: '📌 $n anılara yeni bir hatıra iğneledi.'),
      NotificationType.foggyRevealed => (
          title: 'Buğu silindi',
          body: '👀 $n gönderdiğin buğulu mesajı kazıyıp okudu!'
        ),
      NotificationType.knock =>
        (title: 'Tık tık!', body: '🚪 $n odanın kapısını tıklattı!'),
    };
  }
}

class PokiNotification {
  const PokiNotification({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.roomId,
  });

  final String id;

  /// 'knock' bildirimlerinde null olabilir (henüz oda yok).
  final String? roomId;
  final String senderId;
  final String receiverId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory PokiNotification.fromJson(Map<String, dynamic> m) {
    final type = NotificationType.fromWire(m['type'] as String?);
    if (type == null) {
      throw FormatException('Bilinmeyen bildirim türü: ${m['type']}');
    }
    return PokiNotification(
      id: m['id'] as String,
      roomId: m['room_id'] as String?,
      senderId: m['sender_id'] as String,
      receiverId: m['receiver_id'] as String,
      type: type,
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      isRead: (m['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    );
  }

  /// Bilinmeyen/bozuk satırlarda null döner (akışı bozmaz).
  static PokiNotification? tryParse(Map<String, dynamic> m) {
    try {
      return PokiNotification.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'type': type.wire,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
