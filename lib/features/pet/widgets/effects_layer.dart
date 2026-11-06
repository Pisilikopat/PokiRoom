// lib/features/pet/widgets/effects_layer.dart

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/theme/poki_theme.dart';

class EffectsLayer extends StatefulWidget {
  const EffectsLayer({
    super.key,
    required this.isSleeping,
    this.sleepNote,
    this.speechBubble,
    required this.heartBurstCount,
    required this.sparkleCount,
  });

  final bool isSleeping;
  final String? sleepNote;
  final String? speechBubble;
  final int heartBurstCount;
  final int sparkleCount;

  @override
  State<EffectsLayer> createState() => _EffectsLayerState();
}

class _EffectsLayerState extends State<EffectsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ─────────────── 1. GECE KATMANI VE YILDIZLAR ───────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 700),
              opacity: widget.isSleeping ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !widget.isSleeping,
                child: ClipRRect(
                  borderRadius: PokiRadius.all,
                  child: Stack(
                    children: [
                      // Gece rengi ve hafif blur
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                        child: Container(
                          color: const Color(0xC00F172A), // rgba(15,23,42,0.75)
                        ),
                      ),

                      // Parlayan Hilal (Sağ Üst)
                      Positioned(
                        top: 14,
                        right: 18,
                        child: Text(
                          '🌙',
                          style: TextStyle(
                            fontSize: 26,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFD166).withOpacity(0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Yanıp sönen küçük yıldızlar
                      Positioned(
                        top: 22,
                        right: 56,
                        child: Opacity(
                          opacity: 0.4 + 0.6 * math.sin(t * 2 * math.pi),
                          child: const Text('✨', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      Positioned(
                        top: 48,
                        right: 32,
                        child: Opacity(
                          opacity: 0.4 + 0.6 * math.cos(t * 2 * math.pi),
                          child: const Text('⭐', style: TextStyle(fontSize: 12)),
                        ),
                      ),

                      // Zzz... yükselen uyku harfleri
                      Positioned(
                        bottom: 80,
                        left: 90 + math.sin(t * 2 * math.pi) * 8,
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.8 + t * 0.6,
                            child: const Text(
                              'Zzz...',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Başucu Notu (Görünür halde)
                      if (widget.sleepNote != null && widget.sleepNote!.isNotEmpty)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xDD1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF94A3B8).withOpacity(0.3),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text('🌙', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.sleepNote!,
                                    style: const TextStyle(
                                      color: Color(0xFFF1F5F9),
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────── 2. KONUŞMA BALONU ───────────────
            if (widget.speechBubble != null)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.speechBubble!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ),

            // ─────────────── 3. SEVME KALP PARTİKÜLLERİ ───────────────
            if (widget.heartBurstCount > 0)
              ...List.generate(4, (i) {
                final angle = (i * 0.8) - 1.2;
                final dist = 40.0 + (t * 60.0);
                final dx = math.sin(angle) * dist;
                final dy = -math.cos(angle).abs() * dist;

                return Positioned(
                  top: 70 + dy,
                  left: 100 + dx,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Text(
                      i.isEven ? '💖' : '💕',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              }),

            // ─────────────── 4. BESLEME PARILTI PARTİKÜLLERİ ───────────────
            if (widget.sparkleCount > 0)
              ...List.generate(4, (i) {
                final angle = (i * 0.9) - 1.4;
                final dist = 35.0 + (t * 50.0);
                final dx = math.cos(angle) * dist;
                final dy = -math.sin(angle).abs() * dist;

                return Positioned(
                  top: 80 + dy,
                  left: 130 + dx,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Text(
                      i.isEven ? '✨' : '⭐',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
