// lib/features/room/widgets/poki_poke_menu.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

enum PokiPokeAction {
  thinkingOfYou,
  voiceCall,
  foggyMessage,
  sticker,
  liveDoodle,
  workshop,
  memories,
  arcade,
}

/// Poki-Poke menüsü (alt panel, 2 sütunlu ızgara).
class PokiPokeMenu extends StatelessWidget {
  const PokiPokeMenu({super.key});

  static Future<PokiPokeAction?> show(BuildContext context) {
    return showModalBottomSheet<PokiPokeAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (_) => const PokiPokeMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = <_MenuItem>[
      const _MenuItem(PokiPokeAction.thinkingOfYou, Icons.favorite_rounded,
          'Seni Düşünüyorum', 'Kalpler uçuşsun 💖'),
      const _MenuItem(PokiPokeAction.voiceCall, Icons.call_rounded,
          'Sesli Arama', 'Canlı 1-e-1 sohbet 📞'),
      const _MenuItem(PokiPokeAction.foggyMessage, Icons.cloud_rounded,
          'Buğulu Mesaj', 'Silerek açılır 🌫️'),
      const _MenuItem(PokiPokeAction.sticker, Icons.emoji_emotions_rounded,
          'Çıkartma Gönder', 'Kendi çizimlerin 🐾'),
      const _MenuItem(PokiPokeAction.liveDoodle, Icons.people_alt_rounded,
          'Birlikte Çiz', 'Canlı ortak tuval 🎨'),
      const _MenuItem(PokiPokeAction.workshop, Icons.brush_rounded, 'Atölye',
          'Çiz, çıkartma yap ✨'),
      const _MenuItem(PokiPokeAction.memories, Icons.push_pin_rounded, 'Anılar',
          'Mantar panomuz 📌'),
      const _MenuItem(PokiPokeAction.arcade, Icons.sports_esports_rounded,
          'Oyun Odası', 'Quiz, Puzzle & fazlası 🎮'),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Poki-Poke 🐾', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                for (final item in items)
                  _ActionTile(
                    item: item,
                    onTap: () => Navigator.of(context).pop(item.action),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.action, this.icon, this.title, this.subtitle);

  final PokiPokeAction action;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: PokiColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PokiColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: PokiColors.primaryButton, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: PokiColors.textOf(context).withOpacity(0.6),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
