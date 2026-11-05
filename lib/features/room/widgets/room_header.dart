// lib/features/room/widgets/room_header.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';
import '../../../data/services/room_presence.dart';
import '../../../main.dart';
import '../../notifications/widgets/activity_bell_button.dart';
import 'cute_bandage.dart';

/// Üst "Cep Odası": iki kedi + masa lambası, PokiPet sayacı, zengin durum ve hızlı aksiyonlar.
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
    this.onBitePartner,
    this.partnerHasBandage = false,
    this.myHasBandage = false,
    this.onBandageTap,
    this.onMyBandageTap,
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
  final VoidCallback? onBitePartner;
  final bool partnerHasBandage;
  final bool myHasBandage;
  final VoidCallback? onBandageTap;
  final VoidCallback? onMyBandageTap;

  /// Seri büyüdükçe PokiPet de büyür.
  String get _petEmoji {
    if (streak >= 30) return '🌸';
    if (streak >= 7) return '🪴';
    if (streak >= 3) return '🌿';
    return '🌱';
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

    final activity = partnerActivity;
    final actionLabel = activity.actionLabel;
    final actionType = activity.actionType;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Column(
        key: ValueKey(activity.type.name + (actionLabel ?? '')),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF81C784),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6681C784),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  activity.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: PokiColors.textOf(context).withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          if (actionLabel != null && actionType != null) ...[
            const SizedBox(height: 6),
            _QuickActionPill(
              label: actionLabel,
              onTap: () => onQuickAction?.call(actionType),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PokiRadius.card),
        ),
        boxShadow: PokiShadows.softOf(context),
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
                    tooltip: 'Geri Dön',
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  _PokiPetChip(emoji: _petEmoji, streak: streak),
                                    Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onVoiceCallTap != null)
                        IconButton(
                          tooltip: 'Sesli Ara',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          icon: const Icon(
                            Icons.call_rounded,
                            size: 20,
                            color: Color(0xFF6BCF7F),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onVoiceCallTap?.call();
                          },
                        ),
                      IconButton(
                        tooltip: isSearching ? 'Aramayı Kapat' : 'Sohbette Ara',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: Icon(
                          isSearching
                              ? Icons.search_off_rounded
                              : Icons.search_rounded,
                          size: 20,
                          color: isSearching ? PokiColors.primaryButton : null,
                        ),
                        onPressed: onSearchTap,
                      ),
                      const ActivityBellButton(),
                      PopupMenuButton<String>(
                        tooltip: 'Seçenekler',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: const Icon(Icons.more_vert_rounded, size: 22),
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
                        itemBuilder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return [
                            if (onVoiceCallTap != null)
                              const PopupMenuItem(
                                value: 'call',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.call_rounded,
                                      size: 20,
                                      color: Color(0xFF6BCF7F),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Sesli Ara 🐾',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'search',
                              child: Row(
                                children: [
                                  Icon(Icons.search_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sohbette Ara',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'toggle_theme',
                              child: Row(
                                children: [
                                  Icon(
                                    isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    size: 20,
                                    color: isDark ? PokiColors.lampOn : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isDark ? 'Gündüz Modu' : 'Gece Modu',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'close_pocket',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.door_back_door_outlined,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Cebi Kapat',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
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
                      hasBandage: myHasBandage,
                      onBandageTap: onMyBandageTap,
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
                      isPartner: true,
                      hasBandage: partnerHasBandage,
                      onBandageTap: onBandageTap,
                      onBite: onBitePartner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPartnerStatus(context, Theme.of(context).textTheme),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionPill extends StatefulWidget {
  const _QuickActionPill({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<_QuickActionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.98 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF9E80),
                Color(0xFFFF7043),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7043).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Colors.white,
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
        color: PokiColors.backgroundOf(context),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 18,
          decoration: BoxDecoration(
            color: on ? PokiColors.lampOn : Colors.grey.shade400,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: PokiColors.lampOn.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
        Container(width: 3, height: 14, color: PokiColors.text.withOpacity(0.4)),
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: PokiColors.text.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _CatColumn extends StatelessWidget {
  const _CatColumn({
    required this.name,
    required this.awake,
    this.user,
    this.isPartner = false,
    this.hasBandage = false,
    this.onBandageTap,
    this.onBite,
  });

  final String name;
  final bool awake;
  final PokiUser? user;
  final bool isPartner;
  final bool hasBandage;
  final VoidCallback? onBandageTap;
  final VoidCallback? onBite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatar = user?.avatarUrl;

    Widget avatarWidget = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PokiColors.primary.withOpacity(0.25),
        border: Border.all(
          color: awake ? PokiColors.primaryButton : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatar != null
            ? Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    awake ? '🐱' : '😴',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              )
            : Center(
                child: Text(
                  awake ? '🐱' : '😴',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
      ),
    );

    // Partnerin kedisi ise basılı tutarak ısırma etkileşimi
    if (isPartner && onBite != null) {
      avatarWidget = _HoldableCatAvatar(
        onBite: onBite!,
        child: avatarWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            avatarWidget,
            if (!awake)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: PokiColors.surfaceOf(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💤', style: TextStyle(fontSize: 12)),
                ),
              ),
            // Şirin, narin yara bandı rozeti (çok büyük değil, 22x12)
            if (hasBandage)
              Positioned(
                top: 2,
                right: 2,
                child: CuteBandageBadge(
                  onTap: onBandageTap ?? () {},
                  tooltip: isPartner
                      ? 'Partnerinin tatlı ısırık izi 🩹 Dokun ve iyileştir ✨'
                      : 'Tatlı ısırık izin 🩹 Dokun ve iyileştir ✨',
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Partnerin kedisine basılı tutunca tatlı sıkışma ve ısırma tetikleyicisi
class _HoldableCatAvatar extends StatefulWidget {
  const _HoldableCatAvatar({
    required this.child,
    required this.onBite,
  });

  final Widget child;
  final VoidCallback onBite;

  @override
  State<_HoldableCatAvatar> createState() => _HoldableCatAvatarState();
}

class _HoldableCatAvatarState extends State<_HoldableCatAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool _isPressing = false;
  bool _biteTriggered = false;

  @override
  void initState() {
    super.initState();
    _pressController.addListener(() {
      // 320ms ara haptik feedback (basılı tutarken hissedilen hafif nabız)
      if (_isPressing &&
          !_biteTriggered &&
          _pressController.value >= 0.50 &&
          _pressController.value < 0.55) {
        HapticFeedback.lightImpact();
      }
    });

    _pressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_biteTriggered) {
        _biteTriggered = true;
        HapticFeedback.heavyImpact();
        widget.onBite();
        // Hızlıca eski haline yaylan
        _pressController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _isPressing = true;
    _biteTriggered = false;
    HapticFeedback.selectionClick();
    _pressController.forward();
  }

  void _cancelPress() {
    if (!_isPressing) return;
    _isPressing = false;
    if (!_biteTriggered) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _cancelPress(),
      onTapCancel: _cancelPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final progress = _pressController.value;
          // Basılı tutarken mochi gibi tatlıca içeri büzülür (1.0 -> 0.88), ısırdıktan sonra geri yaylanır
          final scale = _biteTriggered
              ? 1.0 + (1.0 - progress) * 0.14
              : 1.0 - (progress * 0.12);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Basılı tutarken etrafta dönüp dolan pembe enerji halkası
              if (_isPressing && progress > 0.05)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChargeRingPainter(progress: progress),
                  ),
                ),

              // Kedi Avatarı
              Transform.scale(
                scale: scale,
                child: widget.child,
              ),

              // Basılı tutarken yukarıda beliren mini ipucu hapı
              if (_isPressing && progress > 0.28 && !_biteTriggered)
                Positioned(
                  top: -24,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8DA1), Color(0xFFFF6F91)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FF6F91),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🦷', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          progress > 0.80 ? 'HAM! 🐾' : 'Isırılıyor...',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChargeRingPainter extends CustomPainter {
  _ChargeRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + 4.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final activePaint = Paint()
      ..color = const Color(0xFFFF6F91)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChargeRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

