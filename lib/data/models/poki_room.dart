// lib/data/models/poki_room.dart

class PokiRoom {
  const PokiRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.streakCount,
    required this.isActive,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final int streakCount;
  final bool isActive;

  String partnerOf(String myId) => myId == user1Id ? user2Id : user1Id;

  factory PokiRoom.fromMap(Map<String, dynamic> m) => PokiRoom(
        id: m['id'] as String,
        user1Id: m['user1_id'] as String,
        user2Id: m['user2_id'] as String,
        streakCount: (m['streak_count'] as int?) ?? 1,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}
