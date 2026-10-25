// lib/features/room/widgets/hearts_burst.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Poki-Poke geldiğinde ekranın altından yukarı uçuşan kalpler.
class HeartsBurst extends StatefulWidget {
  const HeartsBurst({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<HeartsBurst> createState() => _HeartsBurstState();
}

class _Heart {
  _Heart(math.Random r)
      : x = 0.05 + r.nextDouble() * 0.9,
        delay = r.nextDouble() * 0.4,
        size = 18 + r.nextDouble() * 24,
        drift = 12 + r.nextDouble() * 24,
        freq = 1 + r.nextDouble() * 1.5,
        color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    PokiColors.primary,
    PokiColors.primaryButton,
    Color(0xFFFFC8BD),
    PokiColors.lampOn,
  ];

  final double x;
  final double delay;
  final double size;
  final double drift;
  final double freq;
  final Color color;
}

class _HeartsBurstState extends State<HeartsBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  final _hearts = () {
    final r = math.Random();
    return List.generate(16, (_) => _Heart(r));
  }();

  @override
  void initState() {
    super.initState();
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
      child: LayoutBuilder(
        builder: (context, box) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: [
                  for (final h in _hearts) _buildHeart(h, box),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeart(_Heart h, BoxConstraints box) {
    final t = ((_controller.value - h.delay) / (1 - h.delay)).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final fadeIn = (t / 0.1).clamp(0.0, 1.0);
    final fadeOut = 1 - ((t - 0.6) / 0.4).clamp(0.0, 1.0);

    return Positioned(
      left: h.x * box.maxWidth + math.sin(t * math.pi * 2 * h.freq) * h.drift,
      top: box.maxHeight - t * (box.maxHeight * 0.95),
      child: Opacity(
        opacity: fadeIn * fadeOut,
        child: Icon(Icons.favorite_rounded, size: h.size, color: h.color),
      ),
    );
  }
}
