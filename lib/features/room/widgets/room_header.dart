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
                          } else if (value == 'theme_light') {
                            PokiRoomApp.setTheme(PokiThemeMode.light);
                          } else if (value == 'theme_dark') {
                            PokiRoomApp.setTheme(PokiThemeMode.dark);
                          } else if (value == 'theme_pink') {
                            PokiRoomApp.setTheme(PokiThemeMode.pink);
                          } else if (value == 'toggle_theme') {
                            PokiRoomApp.cycleTheme();
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
                              value: 'theme_light',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.light_mode_rounded,
                                    size: 20,
                                    color: Color(0xFFFFA000),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Gündüz Modu ☀️',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  if (PokiRoomApp.themeMode.value == PokiThemeMode.light)
                                    const Icon(Icons.check_rounded, size: 18, color: Color(0xFF6BCF7F)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'theme_dark',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.dark_mode_rounded,
                                    size: 20,
                                    color: PokiColors.lampOn,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Gece Modu 🌙',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  if (PokiRoomApp.themeMode.value == PokiThemeMode.dark)
                                    const Icon(Icons.check_rounded, size: 18, color: Color(0xFF6BCF7F)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'theme_pink',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 20,
                                    color: Color(0xFFFF6584),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Pembe Mod 🌸',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  if (PokiRoomApp.themeMode.value == PokiThemeMode.pink)
                                    const Icon(Icons.check_rounded, size: 18, color: Color(0xFF6BCF7F)),
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
    duration: const Duration(milliseconds: 1250), // Daha uzun ve gerilim dolu basılı tutma
  );

  bool _isPressing = false;
  bool _biteTriggered = false;
  DateTime? _downTime;
  bool _hapticStage1 = false;
  bool _hapticStage2 = false;

  @override
  void initState() {
    super.initState();
    _pressController.addListener(() {
      final progress = _pressController.value;
      // 1. Kademe haptik (%35 civarı ~430ms)
      if (_isPressing && !_biteTriggered && progress >= 0.35 && !_hapticStage1) {
        _hapticStage1 = true;
        HapticFeedback.selectionClick();
      }
      // 2. Kademe haptik (%70 civarı ~870ms)
      if (_isPressing && !_biteTriggered && progress >= 0.70 && !_hapticStage2) {
        _hapticStage2 = true;
        HapticFeedback.lightImpact();
      }
    });

    _pressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_biteTriggered) {
        _biteTriggered = true;
        HapticFeedback.heavyImpact();
        widget.onBite();
        // Hızlıca neşeyle eski haline yaylan
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
    _hapticStage1 = false;
    _hapticStage2 = false;
    _downTime = DateTime.now();
    HapticFeedback.selectionClick();
    _pressController.forward();
  }

  void _cancelPress(BuildContext context) {
    if (!_isPressing) return;
    _isPressing = false;
    final elapsed = _downTime != null
        ? DateTime.now().difference(_downTime!).inMilliseconds
        : 0;

    if (!_biteTriggered) {
      _pressController.reverse();
      // Çok kısa basıp çektiyse bilgilendirme ipucu
      if (elapsed > 100 && elapsed < 600) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
              content: Text('Isırmak için 1 saniye basılı tut 🦷🐾'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _cancelPress(context),
      onTapCancel: () => _cancelPress(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final progress = _pressController.value;
          // Basılı tutarken mochi gibi tatlıca içeri büzülür (1.0 -> 0.86), ısırdıktan sonra geri yaylanır
          final scale = _biteTriggered
              ? 1.0 + (1.0 - progress) * 0.16
              : 1.0 - (progress * 0.14);

          String hintText = 'Pusuya yattı...';
          String hintIcon = '🐾';
          if (progress >= 0.82) {
            hintText = 'HAM GELİYOR! 🐾';
            hintIcon = '🦷';
          } else if (progress >= 0.50) {
            hintText = 'Hedefe kilitlendi...';
            hintIcon = '🎯';
          }

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Basılı tutarken etrafta dönüp dolan pembe enerji halkası
              if (_isPressing && progress > 0.04)
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

              // Basılı tutarken yukarıda beliren aşamalı mini ipucu hapı
              if (_isPressing && progress > 0.20 && !_biteTriggered)
                Positioned(
                  top: -24,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: progress >= 0.82
                            ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                            : [const Color(0xFFFF8DA1), const Color(0xFFFF6F91)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (progress >= 0.82
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFFFF6F91))
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hintIcon, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          hintText,
                          style: const TextStyle(
                            fontSize: 10.5,
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

