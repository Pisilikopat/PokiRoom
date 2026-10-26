// lib/features/room/widgets/typing_paws.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Karşı taraf yazarken zıplayan üç pati.
class TypingPaws extends StatefulWidget {
  const TypingPaws({super.key, required this.name});
  final String name;

  @override
  State<TypingPaws> createState() => _TypingPawsState();
}

class _TypingPawsState extends State<TypingPaws>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (_controller.value - i * 0.15) * 2 * math.pi;
                  final dy = -math.max(0.0, math.sin(phase)) * 8.0;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.pets_rounded,
                          size: 18, color: PokiColors.primary),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 6),
          Text('${widget.name} yazıyor...',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
