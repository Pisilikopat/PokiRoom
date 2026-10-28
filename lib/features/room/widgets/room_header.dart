// lib/features/room/widgets/room_header.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';
import '../../notifications/widgets/activity_bell_button.dart';

/// Üst "Cep Odası": iki kedi + masa lambası, PokiPet sayacı, durum rozetleri.
class RoomHeader extends StatelessWidget {
  const RoomHeader({
    super.key,
    required this.me,
    required this.partner,
    required this.partnerOnline,
    required this.streak,
    required this.onClosePocket,
  });

  final PokiUser? me;
  final PokiUser? partner;
  final bool partnerOnline;
  final int streak;
  final VoidCallback onClosePocket;

  /// Seri büyüdükçe PokiPet de büyür.
  String get _petEmoji {
    if (streak >= 30) return '🌸';
    if (streak >= 7) return '🪴';
    if (streak >= 3) return '🌿';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PokiColors.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PokiRadius.card),
        ),
        boxShadow: PokiShadows.soft,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Cebi Kapat',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: onClosePocket,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ActivityBellButton(),
                      const SizedBox(width: 4),
                      _PokiPetChip(emoji: _petEmoji, streak: streak),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CatColumn(
                      name: me?.nickname ?? 'Sen',
                      awake: true,
                      user: me,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: _Lamp(on: partnerOnline),
                  ),
                  Expanded(
                    child: _CatColumn(
                      name: partner?.nickname ?? '...',
                      awake: partnerOnline,
                      user: partner,
                    ),
                  ),
                ],
              ),
              if (!partnerOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${partner?.nickname ?? 'Karşı taraf'} şu an uyuyor 💤',
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokiPetChip extends StatelessWidget {
  const _PokiPetChip({required this.emoji, required this.streak});
  final String emoji;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PokiColors.background,
        borderRadius: PokiRadius.all,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$streak gün',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Lamp extends StatelessWidget {
  const _Lamp({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? PokiColors.lampOn.withOpacity(0.45) : Colors.transparent,
        boxShadow: on
            ? [
                BoxShadow(
                  color: PokiColors.lampOn.withOpacity(0.7),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: Icon(
        on ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
        size: 36,
        color: on ? PokiColors.lampOn : PokiColors.text.withOpacity(0.35),
      ),
    );
  }
}

class _CatColumn extends StatelessWidget {
  const _CatColumn({
    required this.name,
    required this.awake,
    required this.user,
  });

  final String name;
  final bool awake;
  final PokiUser? user;

  String? get _badge {
    final emoji = user?.moodEmoji ?? '';
    final text = user?.moodText ?? '';
    final combined = '$emoji $text'.trim();
    return combined.isEmpty ? null : combined;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badge = _badge;
    return Column(
      children: [
        SizedBox(
          height: 22,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: awake ? 0 : 1,
            child: Text('zzz',
                style: textTheme.titleSmall
                    ?.copyWith(color: PokiColors.text.withOpacity(0.5))),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: awake ? 1 : 0.45,
          child: const Icon(Icons.pets_rounded,
              size: 52, color: PokiColors.primary),
        ),
        const SizedBox(height: 4),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PokiColors.background,
              borderRadius: PokiRadius.all,
            ),
            child: Text(badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall),
          ),
      ],
    );
  }
}
