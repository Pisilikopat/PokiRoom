// lib/features/room/widgets/room_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';
import '../../../data/services/room_presence.dart';
import '../../../main.dart';
import '../../notifications/widgets/activity_bell_button.dart';

/// Dost "Cep Odası": iki kedi + masa lambası, PokiPet sayacı, zengin durum ve hızlı aksiyonlar.
class RoomHeader extends StatelessWidget {
  const RoomHeader({
    super.key,
    required this.me,
    required this.partner,
    required this.partnerOnline,
    this.partnerActivity = PokiActivity.offline,
    required this.streak,
    required this.onClosePocket,
    this.onQuickAction,
    this.onSearchTap,
    this.isSearching = false,
    this.onVoiceCallTap,
  });

  final PokiUser? me;
  final PokiUser? partner;
  final bool partnerOnline;
  final PokiActivity partnerActivity;
  final int streak;
  final VoidCallback onClosePocket;
  final void Function(String actionType)? onQuickAction;
  final VoidCallback? onSearchTap;
  final bool isSearching;
  final VoidCallback? onVoiceCallTap;

  /// Seri büyüdükçe PokiPet de büyür.
  String get _petEmoji {
    if (streak >= 30) return '🦁';
    if (streak >= 7) return '🦊';
    if (streak >= 3) return '🐱';
    return '🐾';
  }

  Widget _buildPartnerStatus(BuildContext context, TextTheme textTheme) {
    if (!partnerOnline) {
      return Text(
        '${partner?.nickname ?? 'Karşı taraf'} şu an uyuyor 💤',
        style: textTheme.bodySmall?.copyWith(
          color: PokiColors.textOf(context).withOpacity(0.55),
        ),
      );
    }

    if (partnerActivity.type != PokiActivityType.offline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              partnerActivity.text,
              style: textTheme.bodySmall?.copyWith(
                color: PokiColors.textOf(context).withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (partnerActivity.actionLabel != null && onQuickAction != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onQuickAction!(partnerActivity.actionType ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PokiColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PokiColors.primary.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  partnerActivity.actionLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: PokiColors.primaryButton,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      '${partner?.nickname ?? 'Karşı taraf'} odada 🕯️',
      style: textTheme.bodySmall?.copyWith(
        color: PokiColors.textOf(context).withOpacity(0.75),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context),
        boxShadow: PokiShadows.softOf(context),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PokiRadius.card),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _CatAvatar(
                    emoji: me?.moodEmoji ?? '🐱',
                    label: me?.nickname ?? 'Sen',
                    isMe: true,
                  ),
                  const SizedBox(width: 8),
                  _DeskLamp(isOnline: partnerOnline),
                  const SizedBox(width: 8),
                  _CatAvatar(
                    emoji: partner?.moodEmoji ?? '🐱',
                    label: partner?.nickname ?? 'Partnerin',
                    isMe: false,
                  ),
                  const Spacer(),
                  _PokiPetChip(emoji: _petEmoji, streak: streak),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onVoiceCallTap != null)
                        IconButton(
                          tooltip: 'Sesli Ara',
                          icon: const Icon(
                            Icons.call_rounded,
                            size: 22,
                            color: Color(0xFF6BCF7F),
                          ),
                          onPressed: onVoiceCallTap,
                        ),
                      IconButton(
                        tooltip: isSearching ? 'Aramayı Kapat' : 'Sohbette Ara',
                        icon: Icon(
                          isSearching
                              ? Icons.search_off_rounded
                              : Icons.search_rounded,
                          size: 22,
                          color: isSearching ? PokiColors.primaryButton : null,
                        ),
                        onPressed: onSearchTap,
                      ),
                      const ActivityBellButton(),
                      PopupMenuButton<String>(
                        tooltip: 'Seçenekler',
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          if (value == 'call') {
                            onVoiceCallTap?.call();
                          } else if (value == 'search') {
                            onSearchTap?.call();
                          } else if (value == 'toggle_theme') {
                            PokiRoomApp.toggleTheme();
                          } else if (value == 'close_pocket') {
                            onClosePocket();
                          }
                        },
                        itemBuilder: (context) => [
                          if (onVoiceCallTap != null)
                            const PopupMenuItem(
                              value: 'call',
                              child: Row(
                                children: [
                                  Icon(Icons.call_rounded, size: 20, color: Color(0xFF6BCF7F)),
                                  SizedBox(width: 10),
                                  Text('Sesli Ara 🐾'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'search',
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Sohbette Ara'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'toggle_theme',
                            child: Row(
                              children: [
                                Icon(Icons.brightness_medium_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Temayı Değiştir'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'close_pocket',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Cebi Kapat',
                                  style: TextStyle(color: Colors.red.shade400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildPartnerStatus(context, textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatAvatar extends StatelessWidget {
  const _CatAvatar({
    required this.emoji,
    required this.label,
    required this.isMe,
  });

  final String emoji;
  final String label;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PokiColors.backgroundOf(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe
                  ? PokiColors.primary
                  : PokiColors.primary.withOpacity(0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _DeskLamp extends StatelessWidget {
  const _DeskLamp({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? PokiColors.lampOn : Colors.grey.shade400,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: PokiColors.lampOn.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: const Text('🕯️', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 3),
        Text(
          isOnline ? 'Açık' : 'Kapalı',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ],
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
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PokiColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PokiColors.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak gün',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: PokiColors.textOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
