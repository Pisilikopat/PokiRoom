// lib/features/canvas/widgets/poki_canvas_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../logic/canvas_controller.dart';
import '../models/drawing_stroke.dart';

class PokiCanvasPainter extends CustomPainter {
  PokiCanvasPainter({
    required this.transformMatrix,
    required this.strokes,
    required this.currentStroke,
    required this.partnerStrokes,
    required this.partnerCursor,
    required this.paperWidth,
    required this.paperHeight,
  });

  final Matrix4 transformMatrix;
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Map<String, DrawingStroke> partnerStrokes;
  final PartnerCursor? partnerCursor;
  final double paperWidth;
  final double paperHeight;

  static const Color paperBg = Color(0xFFFFFDF8);
  static const Color paperBorder = Color(0xFFF0EBE1);
  static const Color dotColor = Color(0xFFEADFD2);

  @override
  void paint(Canvas canvas, Size size) {
    // Tüm tuvali zoom / pan matrisine göre dönüştür
    canvas.save();
    canvas.transform(transformMatrix.storage);

    // 1. Kağıt / Çalışma Alanı Arka Planı (Cozy Sketchbook Paper)
    final paperRect = Rect.fromLTWH(0, 0, paperWidth, paperHeight);
    final paperRRect = RRect.fromRectAndRadius(paperRect, const Radius.circular(16));

    // Yumuşak kağıt gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(paperRRect.shift(const Offset(0, 4)), shadowPaint);

    // Kağıt tabanı
    final bgPaint = Paint()..color = paperBg;
    canvas.drawRRect(paperRRect, bgPaint);

    // Kağıt sınır çizgisi
    final borderPaint = Paint()
      ..color = paperBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(paperRRect, borderPaint);

    // 2. Izgara Noktaları (Kılavuz Çizgiler)
    _drawGridDots(canvas, paperRect);

    // Kağıt sınırları dışına taşan çizimleri kırp
    canvas.save();
    canvas.clipRRect(paperRRect);

    // 3. Tamamlanmış Çizgileri Çiz
    for (final stroke in strokes) {
      drawStrokeDirect(canvas, stroke, paperBg);
    }

    // 4. Kullanıcının Kendi Aktif Çizgisini Çiz
    if (currentStroke != null) {
      drawStrokeDirect(canvas, currentStroke!, paperBg);
    }

    // 5. Partnerin Aktif Çizgilerini Çiz (Canlı ortak mod)
    for (final partnerStroke in partnerStrokes.values) {
      drawStrokeDirect(canvas, partnerStroke, paperBg);
    }

    // 6. Partner Canlı İmleci
    if (partnerCursor != null) {
      _drawPartnerCursor(canvas, partnerCursor!);
    }

    canvas.restore(); // clip
    canvas.restore(); // transform
  }

  static void _drawGridDots(Canvas canvas, Rect bounds) {
    final dotPaint = Paint()..color = dotColor;
    const double step = 40.0;
    for (double x = step; x < bounds.width; x += step) {
      for (double y = step; y < bounds.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  static void drawStrokeDirect(Canvas canvas, DrawingStroke stroke, Color paperBg) {
    if (stroke.points.isEmpty) return;

    if (stroke.tool == DrawingTool.bucket) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = stroke.color.withOpacity(stroke.opacity);
      for (int i = 0; i < stroke.points.length - 1; i += 2) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawRect(Rect.fromLTRB(p1.x, p1.y, p2.x, p2.y), fillPaint);
      }
      return;
    }

    if (stroke.tool == DrawingTool.pawStamp) {
      _drawPawStamps(canvas, stroke);
      return;
    }

    if (stroke.tool == DrawingTool.heartStamp) {
      _drawHeartStamps(canvas, stroke);
      return;
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.isEraser) {
      paint
        ..color = paperBg
        ..strokeWidth = stroke.strokeWidth * 2.2;
    } else if (stroke.tool == DrawingTool.highlighter) {
      paint
        ..color = stroke.color.withOpacity(stroke.opacity * 0.45)
        ..strokeWidth = stroke.strokeWidth * 1.8;
    } else if (stroke.tool == DrawingTool.brush) {
      paint
        ..color = stroke.color.withOpacity(stroke.opacity * 0.88)
        ..strokeWidth = stroke.strokeWidth;
    } else {
      // Standart Kalem
      paint
        ..color = stroke.color.withOpacity(stroke.opacity)
        ..strokeWidth = stroke.strokeWidth;
    }

    if (stroke.points.length == 1) {
      // Tek dokunuş (Nokta)
      final p = stroke.points[0];
      canvas.drawCircle(p.offset, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }

    // Yumuşak Bézier eğrisi
    final path = Path();
    path.moveTo(stroke.points[0].x, stroke.points[0].y);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }
    path.lineTo(stroke.points.last.x, stroke.points.last.y);

    canvas.drawPath(path, paint);
  }

  static void _drawPawStamps(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity * 0.9)
      ..style = PaintingStyle.fill;

    const double minSpacing = 28.0;
    Offset? lastDrawn;

    for (final p in stroke.points) {
      if (lastDrawn != null) {
        final dist = (p.offset - lastDrawn).distance;
        if (dist < minSpacing) continue;
      }
      lastDrawn = p.offset;

      final s = stroke.strokeWidth * 1.6;
      // Ana pati tabanı
      canvas.drawOval(
        Rect.fromCenter(center: p.offset, width: s * 1.25, height: s * 0.95),
        paint,
      );
      // 3 parmak pedi
      canvas.drawCircle(Offset(p.x - s * 0.52, p.y - s * 0.65), s * 0.28, paint);
      canvas.drawCircle(Offset(p.x, p.y - s * 0.85), s * 0.30, paint);
      canvas.drawCircle(Offset(p.x + s * 0.52, p.y - s * 0.65), s * 0.28, paint);
    }
  }

  static void _drawHeartStamps(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity * 0.9)
      ..style = PaintingStyle.fill;

    const double minSpacing = 26.0;
    Offset? lastDrawn;

    for (final p in stroke.points) {
      if (lastDrawn != null) {
        final dist = (p.offset - lastDrawn).distance;
        if (dist < minSpacing) continue;
      }
      lastDrawn = p.offset;

      final s = stroke.strokeWidth * 1.4;
      final path = Path();
      path.moveTo(p.x, p.y + s * 0.6);
      path.cubicTo(
        p.x - s * 1.0, p.y - s * 0.2,
        p.x - s * 0.6, p.y - s * 0.9,
        p.x, p.y - s * 0.4,
      );
      path.cubicTo(
        p.x + s * 0.6, p.y - s * 0.9,
        p.x + s * 1.0, p.y - s * 0.2,
        p.x, p.y + s * 0.6,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawPartnerCursor(Canvas canvas, PartnerCursor cursor) {
    final p = cursor.position;

    // İmleç noktası dalgası
    final pulsePaint = Paint()
      ..color = cursor.color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, 10.0, pulsePaint);

    final dotPaint = Paint()
      ..color = cursor.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, 4.0, dotPaint);

    // Sevimli Kedi Etiketi: 🐾 [Partner Nick]
    final label = '🐾 ${cursor.nickname}';
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 16;
    final pillHeight = textPainter.height + 8;
    final pillRect = Rect.fromLTWH(p.dx + 12, p.dy - pillHeight - 4, pillWidth, pillHeight);
    final pillRRect = RRect.fromRectAndRadius(pillRect, const Radius.circular(12));

    final pillPaint = Paint()..color = cursor.color.withOpacity(0.92);
    canvas.drawRRect(pillRRect, pillPaint);

    textPainter.paint(canvas, Offset(p.dx + 20, p.dy - pillHeight));
  }

  @override
  bool shouldRepaint(covariant PokiCanvasPainter oldDelegate) {
    return true; // Akıcı 60fps çizim deneyimi için her karede çiz
  }
}
