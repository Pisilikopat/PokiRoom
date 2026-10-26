// lib/features/home/home_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_gate.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/poki_card.dart';
import 'widgets/avatar_picker.dart';

/// Ana ekran: Profil başlığı + özellik kartları.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _users = UserRepository();
  PokiUser? _me;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await _users.fetchMe();
      final url = _users.getAvatarUrl(me.id);
      if (mounted) setState(() { _me = me; _avatarUrl = url; });
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
    await Supabase.instance.client.auth.signOut();
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nickname = _me?.nickname ?? '...';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              // ─── Profil Başlığı ───
              Row(
                children: [
                  AvatarPicker(
                    imageUrl: _avatarUrl,
                    onPicked: _onAvatarPicked,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, $nickname 🐾',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_me != null)
                          Text(
                            _me!.customTag,
                            style: textTheme.bodySmall?.copyWith(
                              color: PokiColors.text.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
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
                onTap: _openChat,
              ),

              const SizedBox(height: 16),

              _FeatureCard(
                emoji: '🎨',
                title: 'Atölye',
                subtitle: 'Yakında: doodle, çıkartma ve daha fazlası',
                color: PokiColors.incomingBubble.withOpacity(0.5),
                onTap: () => _comingSoon(context),
              ),

              const SizedBox(height: 16),

              _FeatureCard(
                emoji: '📸',
                title: 'Anılar',
                subtitle: 'Yakında: paylaşılan fotoğraflar ve anılar',
                color: PokiColors.lampOn.withOpacity(0.35),
                onTap: () => _comingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Bu özellik çok yakında geliyor 🐾')),
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
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

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
