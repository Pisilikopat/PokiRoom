// lib/features/pet/models/pet_event.dart

class PetEvent {
  const PetEvent({
    required this.id,
    required this.roomId,
    this.actorId,
    required this.type,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String? actorId;
  final String type; // 'feed', 'pet', 'sleep', 'wake'
  final String? note;
  final DateTime createdAt;

  factory PetEvent.fromMap(Map<String, dynamic> m) {
    DateTime parsedDate;
    try {
      final raw = m['created_at'];
      if (raw != null) {
        parsedDate = DateTime.parse(raw.toString()).toLocal();
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return PetEvent(
      id: m['id'] as String? ?? '',
      roomId: m['room_id'] as String? ?? '',
      actorId: m['actor_id'] as String?,
      type: m['type'] as String? ?? 'feed',
      note: m['note'] as String?,
      createdAt: parsedDate,
    );
  }

  String formattedActor(String myId, String? myNickname, String? partnerNickname) {
    if (actorId == null) return 'Biri';
    if (actorId == myId) {
      if (myNickname != null && myNickname.isNotEmpty && myNickname != 'Sen') {
        return '$myNickname (Sen)';
      }
      return 'Sen';
    }
    if (partnerNickname != null && partnerNickname.isNotEmpty) {
      return partnerNickname;
    }
    return 'Partnerin';
  }

  String get actionTitle {
    switch (type) {
      case 'feed':
        return 'Besledi';
      case 'pet':
        return 'Sevdi';
      case 'sleep':
        return 'Uyuttu';
      case 'wake':
        return 'Uyandırdı';
      default:
        return 'İlgilendi';
    }
  }

  String get actionEmoji {
    switch (type) {
      case 'feed':
        return '🐟';
      case 'pet':
        return '💖';
      case 'sleep':
        return '🌙';
      case 'wake':
        return '☀️';
      default:
        return '🐾';
    }
  }

  String get effectBadge {
    switch (type) {
      case 'feed':
        return 'Tokluk +25';
      case 'pet':
        return 'Mutluluk +20';
      case 'sleep':
        return 'Dinleniyor 💤';
      case 'wake':
        return 'Güne Başladı ☀️';
      default:
        return '';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 45) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    return '${diff.inDays} gün önce';
  }

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
