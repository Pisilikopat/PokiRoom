// lib/features/room/widgets/incoming_call_sheet.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';

/// Gelen arama ekranı — tam ekran, nabız animasyonlu.
class IncomingCallSheet extends StatefulWidget {
  const IncomingCallSheet({
    super.key,
    required this.caller,
    required this.onAccept,
    required this.onReject,
  });

  final PokiUser caller;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  static Future<void> show(
    BuildContext context, {
    required PokiUser caller,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingCallSheet(
        caller: caller,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }

  @override
  State<IncomingCallSheet> createState() => _IncomingCallSheetState();
}

class _IncomingCallSheetState extends State<IncomingCallSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _ring1 = CurvedAnimation(parent: _pulse, curve: Curves.easeOut);
    _ring2 = CurvedAnimation(
      parent: _pulse,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PokiColors.darkBackground : PokiColors.background;
    final surface = isDark ? PokiColors.darkSurface : PokiColors.surface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PokiColors.textOf(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Gelen Arama 📞',
            style: TextStyle(
              fontSize: 14,
              color: PokiColors.textOf(context).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.caller.nickname,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: PokiColors.textOf(context),
            ),
          ),
          const SizedBox(height: 48),
          // Nabız halkaları + avatar
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PulseRing(animation: _ring1, color: PokiColors.primary, maxRadius: 90),
                _PulseRing(animation: _ring2, color: PokiColors.primaryButton, maxRadius: 80),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: PokiColors.primary, width: 3),
                    boxShadow: PokiShadows.soft,
                  ),
                  child: Center(
                    child: Text(
                      widget.caller.emoji ?? '🐱',
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Kabul / Reddet butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFFF5F5F),
                  label: 'Reddet',
                  onTap: widget.onReject,
                ),
                _CallButton(
                  icon: Icons.call_rounded,
                  color: const Color(0xFF6BCF7F),
                  label: 'Kabul Et',
                  onTap: widget.onAccept,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PulseRing extends AnimatedWidget {
  const _PulseRing({
    required Animation<double> animation,
    required this.color,
    required this.maxRadius,
  }) : super(listenable: animation);

  final Color color;
  final double maxRadius;

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value;
    return Container(
      width: maxRadius * 2 * value,
      height: maxRadius * 2 * value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity((1 - value) * 0.35),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: PokiColors.textOf(context).withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
