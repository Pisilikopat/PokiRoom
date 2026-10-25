// lib/features/room/widgets/poki_poke_menu.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

enum PokiPokeAction { thinkingOfYou, foggyMessage }

/// Poki-Poke menüsü (alt panel).
class PokiPokeMenu extends StatelessWidget {
  const PokiPokeMenu({super.key});

  static Future<PokiPokeAction?> show(BuildContext context) {
    return showModalBottomSheet<PokiPokeAction>(
      context: context,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Poki-Poke 🐾', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.favorite_rounded,
              title: 'Seni Düşünüyorum',
              subtitle: 'Karşı tarafın ekranında kalpler uçuşur',
              onTap: () => Navigator.of(context).pop(PokiPokeAction.thinkingOfYou),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.cloud_rounded,
              title: 'Buğulu Mesaj',
              subtitle: 'Karşı taraf parmağıyla silerek açar',
              onTap: () => Navigator.of(context).pop(PokiPokeAction.foggyMessage),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: PokiColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: PokiColors.background),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(subtitle, style: textTheme.bodySmall),
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
