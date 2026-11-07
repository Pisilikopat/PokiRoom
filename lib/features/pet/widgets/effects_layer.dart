// lib/features/pet/widgets/effects_layer.dart

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/theme/poki_theme.dart';

/// Tek bir uçuşan efekt (kalp ya da parıltı).
class _Particle {
  _Particle({
    required this.birth,
    required this.life,
    required this.dx,
    required this.rise,
    required this.phase,
    required this.size,
    required this.glyph,
    required this.fromBowl,
  });

  final double birth; // saniye
  final double life; // saniye
  final double dx; // yatay başlangıç sapması
  final double rise; // toplam yükselme mesafesi
  final double phase; // yan salınım fazı
  final double size;
  final String glyph;
  final bool fromBowl; // true: mama kabından, false: kafadan
}

class EffectsLayer extends StatefulWidget {
  const EffectsLayer({
    super.key,
    required this.isSleeping,
    this.sleepNote,
    this.speechBubble,
    required this.heartBurstCount,
    required this.sparkleCount,
    this.headAnchor,
    this.catOrigin,
  });

  final bool isSleeping;
  final String? sleepNote;
  final String? speechBubble;
  final int heartBurstCount;
  final int sparkleCount;

  /// TuxedoCatWidget.headAnchor ile AYNI notifier. Kedinin kafası (yerel
  /// koordinat) buradan okunur; efektler kediyle birlikte hareket eder.
  final ValueNotifier<Offset>? headAnchor;

  /// Kedi widget'ının sol-üst köşesinin bu katman içindeki konumu.
  /// Verilmezse kedi (220x180) katmanın ortasında kabul edilir.
  final Offset? catOrigin;

  static const Size catSize = Size(220, 180);

  /// Mama kabının kedi-yerel konumu (painter'daki center + (38, 8)).
  static const Offset bowlLocal = Offset(148, 138);

  @override
  State<EffectsLayer> createState() => _EffectsLayerState();
}

class _EffectsLayerState extends State<EffectsLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  final math.Random _rng = math.Random();
  final List<_Particle> _ps = [];

  bool _reduced = false;
  double _time = 0;
  double _lastElapsed = 0;

  double _heartUntil = -1, _sparkUntil = -1;
  double _nextHeart = 0, _nextSpark = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.of(context).disableAnimations;
  }

  @override
  void didUpdateWidget(covariant EffectsLayer old) {
    super.didUpdateWidget(old);
    if (widget.heartBurstCount > 0 &&
        widget.heartBurstCount != old.heartBurstCount) {
      _heartUntil = _time + 3.5;
      _nextHeart = _time + 0.22;
      for (var i = 0; i < (_reduced ? 2 : 5); i++) {
        _spawn(heart: true);
      }
    }
    if (widget.sparkleCount > 0 &&
        widget.sparkleCount != old.sparkleCount) {
      _sparkUntil = _time + 3.5;
      _nextSpark = _time + 0.18;
      for (var i = 0; i < (_reduced ? 2 : 4); i++) {
        _spawn(heart: false);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _spawn({required bool heart}) {
    if (heart) {
      const glyphs = ['❤️', '💕', '💖'];
      _ps.add(_Particle(
        birth: _time,
        life: 1.5 + _rng.nextDouble() * 0.6,
        dx: (_rng.nextDouble() - 0.5) * 48,
        rise: 50 + _rng.nextDouble() * 30,
        phase: _rng.nextDouble() * math.pi * 2,
        size: 16 + _rng.nextDouble() * 8,
        glyph: glyphs[_rng.nextInt(glyphs.length)],
        fromBowl: false,
      ));
    } else {
      const glyphs = ['✨', '⭐', '✨'];
      _ps.add(_Particle(
        birth: _time,
        life: 1.0 + _rng.nextDouble() * 0.5,
        dx: (_rng.nextDouble() - 0.5) * 40,
        rise: 30 + _rng.nextDouble() * 25,
        phase: _rng.nextDouble() * math.pi * 2,
        size: 14 + _rng.nextDouble() * 6,
        glyph: glyphs[_rng.nextInt(glyphs.length)],
        fromBowl: true,
      ));
    }
  }

  void _onTick(Duration elapsed) {
    final e = elapsed.inMicroseconds / 1e6;
    var dt = e - _lastElapsed;
    _lastElapsed = e;
    if (dt < 0) dt = 0;
    if (dt > 0.1) dt = 0.1;
    _time += dt;

    if (!_reduced) {
      if (widget.heartBurstCount > 0 &&
          _time < _heartUntil &&
          _time >= _nextHeart) {
        _spawn(heart: true);
        _nextHeart = _time + 0.22;
      }
      if (widget.sparkleCount > 0 &&
          _time < _sparkUntil &&
          _time >= _nextSpark) {
        _spawn(heart: false);
        _nextSpark = _time + 0.18;
      }
    }

    _ps.removeWhere((p) => _time - p.birth > p.life);
    _clock.value = _time;
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

  Widget _particleWidget(_Particle p, Offset origin, Offset head) {
    final age = _time - p.birth;
    final prog = (age / p.life).clamp(0.0, 1.0);

    final opacity = prog < 0.15
        ? prog / 0.15
        : (prog > 0.6 ? (1 - prog) / 0.4 : 1.0);
    final scale = 0.6 + 0.4 * math.min(1.0, age / 0.2);

    final Offset pos;
    if (p.fromBowl) {
      // Mama kabından yukarı doğru dağılan parıltı
      final bowl = origin + EffectsLayer.bowlLocal;
      pos = bowl +
          Offset(
            p.dx * 0.8 + math.sin(age * 4 + p.phase) * 4,
            -14 - p.rise * prog,
          );
    } else {
      // Kafanın üstünden süzülen kalp (kafa hareket ettikçe başlangıç da kayar,
      // ama parçacık doğduğu andaki yatay sapmayı korur)
      pos = origin +
          head +
          Offset(
            p.dx + math.sin(age * 3 + p.phase) * 8,
            -40 - p.rise * prog,
          );
    }

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: IgnorePointer(
        child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Text(p.glyph, style: TextStyle(fontSize: p.size)),
          ),
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layerW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : EffectsLayer.catSize.width;
        final layerH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : EffectsLayer.catSize.height;

        final origin = widget.catOrigin ??
            Offset(
              (layerW - EffectsLayer.catSize.width) / 2,
              (layerH - EffectsLayer.catSize.height) / 2,
            );

        return ValueListenableBuilder<double>(
          valueListenable: _clock,
          builder: (context, time, _) {
            final t = (time % 3.0) / 3.0; // 3 sn'lik döngü (yıldız, Zzz)
            final headLocal =
                widget.headAnchor?.value ?? const Offset(110, 73);
            final headAbs = origin + headLocal;

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
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                            child: Container(color: const Color(0xC00F172A)),
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
                              opacity: (0.4 + 0.6 * math.sin(t * 2 * math.pi)).clamp(0.0, 1.0),
                              child: const Text('✨', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          Positioned(
                            top: 48,
                            right: 32,
                            child: Opacity(
                              opacity: (0.4 + 0.6 * math.cos(t * 2 * math.pi)).clamp(0.0, 1.0),
                              child: const Text('⭐', style: TextStyle(fontSize: 12)),
                            ),
                          ),

                          // Zzz... kedinin kafasından yükselir
                          Positioned(
                            left: headAbs.dx + 18 + math.sin(t * math.pi) * 12,
                            top: headAbs.dy - 34 - t * 40,
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

                          // Başucu Notu
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

                // ─────────────── 2. KALP + PARILTI PARÇACIKLARI ───────────────
                ..._ps.map((p) => _particleWidget(p, origin, headLocal)),

                // ─────────────── 3. KONUŞMA BALONU (kafanın üstünde) ───────────────
                if (widget.speechBubble != null)
                  Positioned(
                    left: headAbs.dx.clamp(60.0, math.max(60.0, layerW - 60.0)),
                    top: headAbs.dy - 50 + math.sin(time * 3) * 2,
                    child: IgnorePointer(
                      child: FractionalTranslation(
                      translation: const Offset(-0.5, -1),
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
                ),
              ],
            );
          },
        );
      },
    );
  }
}
