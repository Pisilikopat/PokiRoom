// lib/features/home/home_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_gate.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_user.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/room_presence.dart';
import '../../main.dart';
import '../../shared/widgets/poki_card.dart';
import '../arcade/games_hub_screen.dart';
import '../memories/memories_screen.dart';
import '../notifications/widgets/activity_bell_button.dart';
import '../workshop/doodle_studio_screen.dart';
import 'widgets/avatar_picker.dart';

/// Ana ekran: Profil başlığı + özellik kartları.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _users = UserRepository();
  final _rooms = RoomRepository();
  PokiUser? _me;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    RoomPresence.current?.removeListener(_onPresenceChanged);
    super.dispose();
  }

  void _onPresenceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final me = await _users.fetchMe();
      final url = _users.getAvatarUrl(me.id);
      if (mounted) {
        setState(() {
          _me = me;
          _avatarUrl = url;
        });
      }
      NotificationService.instance.syncTokenWithSupabase();

      if (me.hasRoom && me.currentRoomId != null) {
        final room = await _rooms.fetchRoom(me.currentRoomId!);
        final partnerId = room.partnerOf(me.id);
        final presence = RoomPresence.ensure(
          roomId: me.currentRoomId!,
          myId: me.id,
          partnerId: partnerId,
        );
        presence.removeListener(_onPresenceChanged);
        presence.addListener(_onPresenceChanged);
        presence.join();
        presence.setActivity(PokiActivity.inApp);
      }
    } catch (_) {
      // Profil yüklenemezse sessizce devam et
    }
  }

  Future<void> _onAvatarPicked(Uint8List bytes) async {
    try {
      await _users.uploadAvatar(bytes);
      if (mounted) {
        setState(() {
          // Cache-buster ile yeniden yükle
          _avatarUrl = _users.getAvatarUrl(_me!.id, bust: true);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf yüklenemedi 🐾')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    RoomPresence.current?.dispose();
    RoomPresence.current = null;
    await Supabase.instance.client.auth.signOut();
  }

  void _openChat() {
    RoomPresence.current?.setActivity(PokiActivity.chatting);
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => const AppGate()),
    )
        .then((_) {
      RoomPresence.current?.setActivity(PokiActivity.inApp);
    });
  }

  void _openWorkshop() {
    if (_me == null || !_me!.hasRoom) {
      _showNeedRoomSnackBar();
      return;
    }
    RoomPresence.current?.setActivity(PokiActivity.workshop);
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => DoodleStudioScreen(roomId: _me!.currentRoomId!),
      ),
    )
        .then((_) {
      RoomPresence.current?.setActivity(PokiActivity.inApp);
    });
  }

  void _openMemories() {
    if (_me == null || !_me!.hasRoom) {
      _showNeedRoomSnackBar();
      return;
    }
    RoomPresence.current?.setActivity(PokiActivity.memories);
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => MemoriesScreen(roomId: _me!.currentRoomId!),
      ),
    )
        .then((_) {
      RoomPresence.current?.setActivity(PokiActivity.inApp);
    });
  }

  void _openArcade() {
    if (_me == null || !_me!.hasRoom) {
      _showNeedRoomSnackBar();
      return;
    }
    RoomPresence.current?.setActivity(PokiActivity.gamesHub);
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => GamesHubScreen(roomId: _me!.currentRoomId!),
      ),
    )
        .then((_) {
      RoomPresence.current?.setActivity(PokiActivity.inApp);
    });
  }

  void _showNeedRoomSnackBar() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content:
              Text('Atölye ve Anılar için önce biriyle odaya bağlanmalısın 🐾'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final presence = RoomPresence.current;
    final partnerOnline = presence?.partnerOnline ?? false;
    final activity = presence?.partnerActivity;

    String? chatStatus;
    if (partnerOnline && activity != null) {
      chatStatus = activity.text;
    }

    String? arcadeStatus;
    if (partnerOnline &&
        (activity?.type == PokiActivityType.inQuizWaiting ||
            activity?.type == PokiActivityType.inPuzzleWaiting ||
            activity?.type == PokiActivityType.inQuizPlaying ||
            activity?.type == PokiActivityType.inPuzzlePlaying)) {
      arcadeStatus = activity?.text;
    }

    return Scaffold(
      backgroundColor: PokiColors.backgroundOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Profil & Ayarlar Üst Barı ───
              Row(
                children: [
                  AvatarPicker(
                    avatarUrl: _avatarUrl,
                    onPicked: _onAvatarPicked,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba,',
                          style: textTheme.bodySmall?.copyWith(
                            color: PokiColors.textOf(context).withOpacity(0.6),
                          ),
                        ),
                        Text(
                          _me?.nickname ?? 'Poki Dostu',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ActivityBellButton(),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: PokiRoomApp.themeMode,
                    builder: (context, mode, _) {
                      final isDark = mode == ThemeMode.dark;
                      return IconButton(
                        tooltip: isDark ? 'Gündüz Modu' : 'Gece Modu',
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark ? PokiColors.lampOn : null,
                        ),
                        onPressed: PokiRoomApp.toggleTheme,
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Çıkış Yap',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: _signOut,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Özellik Kartları ───
              _FeatureCard(
                emoji: '💬',
                title: 'Patile',
                subtitle: 'Birine tıklat veya cebindeki sohbete dön',
                color: PokiColors.primary.withOpacity(0.25),
                liveStatus: chatStatus,
                onTap: _openChat,
              ),

              const SizedBox(height: 16),

              _FeatureCard(
                emoji: '🎨',
                title: 'Atölye',
                subtitle: 'Doodle çiz, çıkartma yap veya canlı çiz',
                color: PokiColors.incomingBubble.withOpacity(0.5),
                onTap: _openWorkshop,
              ),

              const SizedBox(height: 16),

              _FeatureCard(
                emoji: '📸',
                title: 'Anılar',
                subtitle: 'Ortak mantar pano ve hatıralar',
                color: PokiColors.lampOn.withOpacity(0.35),
                onTap: _openMemories,
              ),

              const SizedBox(height: 16),

              _FeatureCard(
                emoji: '🎮',
                title: 'Oyun Odası',
                subtitle: 'Birlikte mini oyunlar oyna, lobi kur veya katıl',
                color: PokiColors.primaryButton.withOpacity(0.3),
                liveStatus: arcadeStatus,
                onTap: _openArcade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.liveStatus,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? liveStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: PokiCard(
        color: color,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: PokiColors.text.withOpacity(0.6),
                    ),
                  ),
                  if (liveStatus != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF81C784),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            liveStatus!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
