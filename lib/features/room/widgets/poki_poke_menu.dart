// lib/features/room/widgets/poki_poke_menu.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

enum PokiPokeAction {
  thinkingOfYou,
  foggyMessage,
  sticker,
  liveDoodle,
  workshop,
  memories,
}

/// Poki-Poke menüsü (alt panel, 2 sütunlu ızgara).
class PokiPokeMenu extends StatelessWidget {
  const PokiPokeMenu({super.key});

  static Future<PokiPokeAction?> show(BuildContext context) {
    return showModalBottomSheet<PokiPokeAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.background,
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
          'Seni Düşünüyorum', 'Kalpler uçuşsun'),
      const _MenuItem(PokiPokeAction.foggyMessage, Icons.cloud_rounded,
          'Buğulu Mesaj', 'Silerek açılır'),
      const _MenuItem(PokiPokeAction.sticker, Icons.emoji_emotions_rounded,
          'Çıkartma Gönder', 'Kendi çizimlerin'),
      const _MenuItem(PokiPokeAction.liveDoodle, Icons.people_alt_rounded,
          'Birlikte Çiz', 'Canlı ortak tuval'),
      const _MenuItem(PokiPokeAction.workshop, Icons.brush_rounded, 'Atölye',
          'Çiz, çıkartma yap'),
      const _MenuItem(PokiPokeAction.memories, Icons.push_pin_rounded, 'Anılar',
          'Mantar panomuz'),
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                for (final item in items)
                  _MenuTile(
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: PokiColors.surface,
      borderRadius: PokiRadius.all,
      child: InkWell(
        borderRadius: PokiRadius.all,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: PokiColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: PokiColors.background),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
