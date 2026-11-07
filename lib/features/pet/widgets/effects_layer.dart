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

  void _showFullNoteDialog(BuildContext context, String note) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🌙', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Başucu Notu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: SelectableText(
              note,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC7D2FE),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                          color: const Color(0xC00F172A),
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
                        bottom: 40 + (t * 40),
                        left: 140 + (math.sin(t * math.pi) * 12),
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Text(
                            t < 0.33 ? 'z' : (t < 0.66 ? 'Zz' : 'Zzz...'),
                            style: TextStyle(
                              color: const Color(0xFFC7D2FE),
                              fontWeight: FontWeight.bold,
                              fontSize: 14 + (t * 12),
                              shadows: const [
                                Shadow(color: Color(0xFF6366F1), blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Başucu Notu (Uyurken alt kısımda mini dokunulabilir hap)
                      if (widget.sleepNote != null && widget.sleepNote!.isNotEmpty)
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showFullNoteDialog(context, widget.sleepNote!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xE60F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withOpacity(0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Text('🌙', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.sleepNote!,
                                      style: const TextStyle(
                                        color: Color(0xFFF1F5F9),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.touch_app_rounded,
                                    size: 14,
                                    color: Color(0xFFA5B4FC),
                                  ),
                                ],
                              ),
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
