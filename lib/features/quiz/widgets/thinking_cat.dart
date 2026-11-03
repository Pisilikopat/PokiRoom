// lib/features/quiz/widgets/thinking_cat.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/quiz_palette.dart';

/// "Düşünen Kedi": karşı taraf şık seçerken kafasında soru işaretleri dönen kedi.
/// (İSKELET: emoji tabanlı. Çenesini sıvazlayan çizim bir sonraki adımda.)
class ThinkingCat extends StatefulWidget {
  const ThinkingCat({super.key, this.label = 'Partner düşünüyor...'});

  final String label;

  @override
  State<ThinkingCat> createState() => _ThinkingCatState();
}

class _ThinkingCatState extends State<ThinkingCat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          width: 160,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: math.sin(t) * 0.08,
                    child: const Text('🐱', style: TextStyle(fontSize: 56)),
                  ),
                  for (var i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(t + i * 2 * math.pi / 3) * 44,
                        math.sin(t + i * 2 * math.pi / 3) * 12 - 40,
                      ),
                      child: Text('?',
                          style: QuizPalette.title(context)
                              .copyWith(color: QuizPalette.accent(context))),
                    ),
                ],
              );
            },
          ),
        ),
        Text(widget.label, style: QuizPalette.caption(context)),
      ],
    );
  }
}
