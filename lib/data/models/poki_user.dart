// lib/data/models/poki_user.dart

class PokiUser {
  const PokiUser({
    required this.id,
    required this.customTag,
    required this.nickname,
    this.moodEmoji,
    this.moodText,
    this.currentRoomId,
    this.isOnline = false,
    this.avatarUrl,
  });

  final String id;
  final String customTag;
  final String nickname;
  final String? moodEmoji;
  final String? moodText;
  final String? currentRoomId;
  final bool isOnline;
  final String? avatarUrl;

  bool get hasRoom => currentRoomId != null;

  factory PokiUser.fromMap(Map<String, dynamic> m) => PokiUser(
        id: m['id'] as String,
        customTag: (m['custom_tag'] as String?) ?? '#POKI-????',
        nickname: (m['nickname'] as String?) ?? 'Poki',
        moodEmoji: m['mood_emoji'] as String?,
        moodText: m['mood_text'] as String?,
        currentRoomId: m['current_room_id'] as String?,
        isOnline: (m['is_online'] as bool?) ?? false,
        avatarUrl: m['avatar_url'] as String?,
      );
}
