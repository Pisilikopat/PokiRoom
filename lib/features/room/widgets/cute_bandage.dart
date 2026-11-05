// lib/features/room/widgets/cute_bandage.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kedinin yanağında/kulağında beliren minik, şirin yara bandı.
/// Dokunulduğunda ışıltılı bir efektle iyileşip kaybolur.
class CuteBandageBadge extends StatefulWidget {
  const CuteBandageBadge({
    super.key,
    required this.onTap,
    this.tooltip = 'Tatlı ısırık izi 🩹 Dokun ve iyileştir ✨',
  });

  final VoidCallback onTap;
  final String tooltip;

  @override
  State<CuteBandageBadge> createState() => _CuteBandageBadgeState();
}

class _CuteBandageBadgeState extends State<CuteBandageBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final Animation<double> _wobble = Tween<double>(begin: -0.05, end: 0.05).animate(
    CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
  );

  bool _isHealing = false;

  void _handleTap() {
    if (_isHealing) return;
    setState(() => _isHealing = true);
    HapticFeedback.lightImpact();
    // 300ms sonra callback'i çağır
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isHealing ? 1.4 : 1.0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _isHealing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 240),
            child: AnimatedBuilder(
              animation: _wobble,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -0.22 + _wobble.value,
                  child: child,
                );
              },
              child: Container(
                width: 22,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAB9), // Pastel şeftali bej
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFFF4A460).withOpacity(0.55),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Sol mini gözenek noktası
                    Container(
                      width: 1.5,
                      height: 1.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD29367),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Ortadaki minik pembe kalp/artı
                    const Icon(
                      Icons.favorite_rounded,
                      size: 6.5,
                      color: Color(0xFFFF6F91),
                    ),
                    // Sağ mini gözenek noktası
                    Container(
                      width: 1.5,
                      height: 1.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD29367),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
