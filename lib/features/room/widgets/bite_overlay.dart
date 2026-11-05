// lib/features/room/widgets/bite_overlay.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/poki_theme.dart';

/// Tatlı ısırık alındığında ekranda beliren sevimli tam ekran diş izi ve parçacık animasyonu.
class BiteOverlay extends StatefulWidget {
  const BiteOverlay({
    super.key,
    required this.senderName,
    required this.onDone,
    this.spot = 'yanak',
  });

  final String senderName;
  final VoidCallback onDone;
  final String spot;

  @override
  State<BiteOverlay> createState() => _BiteOverlayState();
}

class _BiteParticle {
  _BiteParticle(math.Random r)
      : angle = r.nextDouble() * 2 * math.pi,
        distance = 70 + r.nextDouble() * 95,
        speed = 0.8 + r.nextDouble() * 0.4,
        size = 18 + r.nextDouble() * 16,
        emoji = _emojis[r.nextInt(_emojis.length)];

  static const _emojis = ['💖', '🦷', '✨', '🐾', '🌸', '💫'];

  final double angle;
  final double distance;
  final double speed;
  final double size;
  final String emoji;
}

class _BiteOverlayState extends State<BiteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  final List<_BiteParticle> _particles = () {
    final r = math.Random();
    return List.generate(14, (_) => _BiteParticle(r));
  }();

  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      // Isırığın tam kapandığı anda (progress ~0.22) çift haptik ver
      if (!_hapticFired && _controller.value >= 0.22) {
        _hapticFired = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 90), () {
          HapticFeedback.mediumImpact();
        });
      }
    });

    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final val = _controller.value;
          // Fade-in (0 - 0.15) ve Fade-out (0.75 - 1.0)
          final opacity = val < 0.15
              ? (val / 0.15).clamp(0.0, 1.0)
              : val > 0.75
                  ? (1.0 - (val - 0.75) / 0.25).clamp(0.0, 1.0)
                  : 1.0;

          // Dişlerin kapanma animasyonu (0.0 -> 0.25 arasında hızla kapanır)
          final chompProgress = (val / 0.25).clamp(0.0, 1.0);
          final chompCurve = Curves.easeInBack.transform(chompProgress);
          // Açıkken 65px uzakta, kapanınca 0px
          final teethOffset = (1.0 - chompCurve) * 65.0;

          // Merkezdeki kutlama balonu (0.22'den sonra yaylanarak açılır)
          final bubbleProgress = ((val - 0.22) / 0.35).clamp(0.0, 1.0);
          final bubbleScale = Curves.elasticOut.transform(bubbleProgress);

          return Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arka planda hafif pembe dokunuş
                Container(
                  color: Colors.pink.withOpacity(0.08 * opacity),
                ),

                // Çevreye saçılan parçacıklar
                for (final p in _particles) _buildParticle(p, val),

                // Üst Dişler
                Transform.translate(
                  offset: Offset(0, -teethOffset - 25),
                  child: const _TeethRow(isUpper: true),
                ),

                // Alt Dişler
                Transform.translate(
                  offset: Offset(0, teethOffset + 25),
                  child: const _TeethRow(isUpper: false),
                ),

                // Ortadaki Sevimli Mesaj Rozeti
                if (val >= 0.20)
                  Transform.scale(
                    scale: bubbleScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF94B9), Color(0xFFFF6F91)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6F91).withOpacity(0.45),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🦷', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                'HAM! 🐾',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.senderName} seni tatlıca ısırdı!',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ayy acımadı ki... 🩹💖',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(_BiteParticle p, double val) {
    if (val < 0.22) return const SizedBox.shrink();
    final t = ((val - 0.22) / 0.70).clamp(0.0, 1.0);
    final distance = p.distance * Curves.easeOutCubic.transform(t);
    final x = math.cos(p.angle) * distance;
    final y = math.sin(p.angle) * distance;
    final scale = (1.0 - t * 0.4).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.scale(
        scale: scale,
        child: Text(
          p.emoji,
          style: TextStyle(fontSize: p.size),
        ),
      ),
    );
  }
}

/// Sevimli minik kedi dişleri çizimi
class _TeethRow extends StatelessWidget {
  const _TeethRow({required this.isUpper});
  final bool isUpper;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(130, 40),
      painter: _TeethPainter(isUpper: isUpper),
    );
  }
}

class _TeethPainter extends CustomPainter {
  _TeethPainter({required this.isUpper});
  final bool isUpper;

  @override
  void paint(Canvas canvas, Size size) {
    final gumPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final toothPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final toothBorder = Paint()
      ..color = const Color(0xFFFF8DA1).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Diş koordinatları: 2 yan kesici köpek dişi (sivri kedi dişi), 4 orta minik diş
    final midY = isUpper ? size.height * 0.3 : size.height * 0.7;
    final teethCount = 6;
    final toothW = size.width / (teethCount + 2);

    for (int i = 0; i < teethCount; i++) {
      final isCanine = (i == 0 || i == teethCount - 1);
      final cx = toothW * (i + 1.5);
      final h = isCanine ? 22.0 : 14.0;
      final w = isCanine ? 14.0 : 11.0;

      final path = Path();
      if (isUpper) {
        // Üst dişler aşağı doğru sarkar
        path.moveTo(cx - w / 2, midY);
        if (isCanine) {
          path.quadraticBezierTo(cx, midY + h + 4, cx, midY + h + 6);
          path.quadraticBezierTo(cx, midY + h + 4, cx + w / 2, midY);
        } else {
          path.lineTo(cx - w / 2, midY + h - 3);
          path.quadraticBezierTo(cx, midY + h, cx + w / 2, midY + h - 3);
          path.lineTo(cx + w / 2, midY);
        }
      } else {
        // Alt dişler yukarı doğru bakar
        path.moveTo(cx - w / 2, midY);
        if (isCanine) {
          path.quadraticBezierTo(cx, midY - h - 4, cx, midY - h - 6);
          path.quadraticBezierTo(cx, midY - h - 4, cx + w / 2, midY);
        } else {
          path.lineTo(cx - w / 2, midY - h + 3);
          path.quadraticBezierTo(cx, midY - h, cx + w / 2, midY - h + 3);
          path.lineTo(cx + w / 2, midY);
        }
      }
      path.close();

      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, toothPaint);
      canvas.drawPath(path, toothBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _TeethPainter oldDelegate) =>
      oldDelegate.isUpper != isUpper;
}
