// lib/features/room/widgets/foggy_bubble.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/poki_message.dart';

/// Alıcı tarafında buğulu mesaj: parmakla silince (scratch/wipe) açılır.
/// Silme oranı eşiği geçince [onRevealed] çağrılır (mesaj okundu olur).
class FoggyBubble extends StatefulWidget {
  const FoggyBubble({
    super.key,
    required this.message,
    required this.onRevealed,
  });

  final PokiMessage message;
  final VoidCallback onRevealed;

  @override
  State<FoggyBubble> createState() => _FoggyBubbleState();
}

class _FoggyBubbleState extends State<FoggyBubble> {
  static const double _cell = 14;
  static const double _brush = 22;
  static const double _revealThreshold = 0.55;

  final List<List<Offset>> _strokes = [];
  final Set<int> _covered = {};
  Size _size = Size.zero;
  int _version = 0;
  late bool _revealed = widget.message.isRead;

  void _onDown(Offset p) {
    if (_revealed) return;
    _strokes.add([p]);
    _mark(p);
    setState(() => _version++);
  }

  void _onMove(Offset p) {
    if (_revealed || _strokes.isEmpty) return;
    _strokes.last.add(p);
    _mark(p);
    _checkReveal();
    setState(() => _version++);
  }

  void _mark(Offset p) {
    if (_size.isEmpty) return;
    final cols = (_size.width / _cell).ceil();
    final rows = (_size.height / _cell).ceil();
    final minC = ((p.dx - _brush) / _cell).floor().clamp(0, cols - 1).toInt();
    final maxC = ((p.dx + _brush) / _cell).floor().clamp(0, cols - 1).toInt();
    final minR = ((p.dy - _brush) / _cell).floor().clamp(0, rows - 1).toInt();
    final maxR = ((p.dy + _brush) / _cell).floor().clamp(0, rows - 1).toInt();
    for (var r = minR; r <= maxR; r++) {
      for (var c = minC; c <= maxC; c++) {
        final center = Offset((c + 0.5) * _cell, (r + 0.5) * _cell);
        if ((center - p).distance <= _brush) _covered.add(r * cols + c);
      }
    }
  }

  void _checkReveal() {
    if (_size.isEmpty) return;
    final total =
        (_size.width / _cell).ceil() * (_size.height / _cell).ceil();
    if (_covered.length / total >= _revealThreshold) {
      _revealed = true;
      HapticFeedback.lightImpact();
      widget.onRevealed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(minWidth: 150, maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: PokiColors.incomingBubble,
          borderRadius: PokiRadius.all,
          boxShadow: PokiShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: PokiRadius.all,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('🌫️ Buğulu mesaj', style: textTheme.labelSmall),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(widget.message.content,
                          style: textTheme.bodyLarge),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatClock(widget.message.createdAt),
                      style: textTheme.labelSmall
                          ?.copyWith(color: PokiColors.text.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _revealed ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _revealed,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        _size = Size(box.maxWidth, box.maxHeight);
                        // Eager: liste kaydırmasıyla yarışmadan parmak hareketini al.
                        return RawGestureDetector(
                          gestures: {
                            EagerGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                    EagerGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                              (_) {},
                            ),
                          },
                          child: Listener(
                            onPointerDown: (e) => _onDown(e.localPosition),
                            onPointerMove: (e) => _onMove(e.localPosition),
                            child: CustomPaint(
                              painter: _FogPainter(_strokes, _version, _brush),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter(this.strokes, this.version, this.brush);

  final List<List<Offset>> strokes;
  final int version;
  final double brush;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    // Buğu katmanı
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokiColors.surface, PokiColors.background],
        ).createShader(rect),
    );

    // Parmakla silinen yerler
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = brush * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..blendMode = BlendMode.clear;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, brush, dot);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (final p in stroke.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, eraser);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) => old.version != version;
}
