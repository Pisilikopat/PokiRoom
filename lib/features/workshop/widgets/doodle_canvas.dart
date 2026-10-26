// lib/features/workshop/widgets/doodle_canvas.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../doodle_controller.dart';

/// Kare, parmakla/fareyle çizilen tuval. Arka plan (nokta ızgarası) RepaintBoundary'nin
/// DIŞINDA olduğu için dışa aktarılan PNG şeffaf kalır.
class DoodleCanvas extends StatefulWidget {
  const DoodleCanvas({
    super.key,
    required this.controller,
    this.captureKey,
    this.enabled = true,
  });

  final DoodleController controller;

  /// PNG dışa aktarımı için RepaintBoundary anahtarı.
  final GlobalKey? captureKey;
  final bool enabled;

  @override
  State<DoodleCanvas> createState() => _DoodleCanvasState();
}

class _DoodleCanvasState extends State<DoodleCanvas> {
  int? _pointer;

  Offset _norm(Offset local, Size size) => Offset(
        (local.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (local.dy / size.height).clamp(0.0, 1.0).toDouble(),
      );

  void _down(PointerDownEvent e, Size size) {
    if (!widget.enabled || _pointer != null) return;
    _pointer = e.pointer;
    widget.controller.beginStroke(_norm(e.localPosition, size));
  }

  void _move(PointerMoveEvent e, Size size) {
    if (e.pointer != _pointer) return;
    widget.controller.extendStroke(_norm(e.localPosition, size));
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.controller.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PokiColors.background,
          borderRadius: PokiRadius.all,
          boxShadow: PokiShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: PokiRadius.all,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _DotGridPainter()),
              LayoutBuilder(
                builder: (context, box) {
                  final size = box.biggest;
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _down(e, size),
                    onPointerMove: (e) => _move(e, size),
                    onPointerUp: _up,
                    onPointerCancel: _up,
                    child: RepaintBoundary(
                      key: widget.captureKey,
                      child: CustomPaint(
                        painter: DoodleStrokesPainter(widget.controller),
                        size: Size.infinite,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoodleStrokesPainter extends CustomPainter {
  DoodleStrokesPainter(this.controller) : super(repaint: controller);

  final DoodleController controller;

  @override
  void paint(Canvas canvas, Size size) {
    Offset scale(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    for (final s in controller.strokes) {
      final pts = s.points;
      if (pts.isEmpty) continue;
      final color = Color(s.color);
      final stroke = s.width * size.width;

      if (pts.length == 1) {
        canvas.drawCircle(
          scale(pts.first),
          stroke / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
        continue;
      }

      final first = scale(pts.first);
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < pts.length - 1; i++) {
        final p0 = scale(pts[i]);
        final p1 = scale(pts[i + 1]);
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      final last = scale(pts.last);
      path.lineTo(last.dx, last.dy);

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DoodleStrokesPainter old) =>
      old.controller != controller;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = PokiColors.text.withOpacity(0.08);
    const step = 24.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
