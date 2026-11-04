// lib/features/puzzle/widgets/cat_art_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/cat_art.dart';

/// Sevimli vektörel kedi illüstrasyonu.
/// Asset dosyası gerektirmeden Canvas ile çizilir; tüm çözünürlüklerde keskin ve pürüzsüzdür.
class CatArtWidget extends StatelessWidget {
  const CatArtWidget({
    super.key,
    required this.cat,
    this.size = 280,
  });

  final CatArt cat;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: CatArtPainter(cat: cat),
      ),
    );
  }
}

class CatArtPainter extends CustomPainter {
  const CatArtPainter({required this.cat});

  final CatArt cat;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Arka plan pastel gradyan
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cat.color,
          cat.color.withOpacity(0.55),
          const Color(0xFFFFF9F5),
        ],
      ).createShader(bgRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(w * 0.08)),
      bgPaint,
    );

    // Arka plan dekoratif minik pati / yıldız desenleri
    final decorPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.18, h * 0.18), w * 0.035, decorPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), w * 0.045, decorPaint);
    canvas.drawCircle(Offset(w * 0.14, h * 0.78), w * 0.03, decorPaint);
    canvas.drawCircle(Offset(w * 0.86, h * 0.76), w * 0.035, decorPaint);

    // 2. Kedi Gövdesi ve Başının Renkleri
    final (furColor, stripeColor, eyeColor) = switch (cat.id) {
      'pamuk' => (
          const Color(0xFFFFFFFF),
          const Color(0xFFFFD5D2),
          const Color(0xFF64B5F6),
        ),
      'seftali' => (
          const Color(0xFFFFCC80),
          const Color(0xFFFF9800),
          const Color(0xFF4CAF50),
        ),
      'fistik' => (
          const Color(0xFFFFF59D),
          const Color(0xFFFFB74D),
          const Color(0xFF43A047),
        ),
      'kakao' => (
          const Color(0xFFE0CFB8),
          const Color(0xFF5D4037),
          const Color(0xFF42A5F5),
        ),
      'bulut' => (
          const Color(0xFFCFD8DC),
          const Color(0xFF90A4AE),
          const Color(0xFF5C6BC0),
        ),
      _ => (
          const Color(0xFFFFF176),
          const Color(0xFFFFA726),
          const Color(0xFF26A69A),
        ),
    };

    final headRadius = w * 0.26;
    final headCenter = Offset(w / 2, h * 0.52);

    // Kulaklar (Sol & Sağ Üçgen)
    final earPaint = Paint()
      ..color = furColor
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFAB91).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Sol kulak
    final leftEar = Path()
      ..moveTo(headCenter.dx - headRadius * 0.82, headCenter.dy - headRadius * 0.2)
      ..lineTo(headCenter.dx - headRadius * 0.85, headCenter.dy - headRadius * 1.15)
      ..lineTo(headCenter.dx - headRadius * 0.2, headCenter.dy - headRadius * 0.75)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    final leftInnerEar = Path()
      ..moveTo(headCenter.dx - headRadius * 0.75, headCenter.dy - headRadius * 0.3)
      ..lineTo(headCenter.dx - headRadius * 0.78, headCenter.dy - headRadius * 0.98)
      ..lineTo(headCenter.dx - headRadius * 0.3, headCenter.dy - headRadius * 0.7)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    // Sağ kulak
    final rightEar = Path()
      ..moveTo(headCenter.dx + headRadius * 0.82, headCenter.dy - headRadius * 0.2)
      ..lineTo(headCenter.dx + headRadius * 0.85, headCenter.dy - headRadius * 1.15)
      ..lineTo(headCenter.dx + headRadius * 0.2, headCenter.dy - headRadius * 0.75)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    final rightInnerEar = Path()
      ..moveTo(headCenter.dx + headRadius * 0.75, headCenter.dy - headRadius * 0.3)
      ..lineTo(headCenter.dx + headRadius * 0.78, headCenter.dy - headRadius * 0.98)
      ..lineTo(headCenter.dx + headRadius * 0.3, headCenter.dy - headRadius * 0.7)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // Baş (Oval / Daire)
    final headPaint = Paint()
      ..color = furColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Baş çevresi yumuşak çizgi
    final outlinePaint = Paint()
      ..color = const Color(0xFF4A403A).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Alın çizgileri (Tekir / Şeftali deseni)
    if (cat.id == 'seftali' || cat.id == 'fistik') {
      final stripePaint = Paint()
        ..color = stripeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(headCenter.dx, headCenter.dy - headRadius * 0.85),
        Offset(headCenter.dx, headCenter.dy - headRadius * 0.55),
        stripePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx - headRadius * 0.22, headCenter.dy - headRadius * 0.75),
        Offset(headCenter.dx - headRadius * 0.15, headCenter.dy - headRadius * 0.5),
        stripePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + headRadius * 0.22, headCenter.dy - headRadius * 0.75),
        Offset(headCenter.dx + headRadius * 0.15, headCenter.dy - headRadius * 0.5),
        stripePaint,
      );
    }

    // Gözler
    final eyeRadius = headRadius * 0.18;
    final leftEyeCenter = Offset(headCenter.dx - headRadius * 0.42, headCenter.dy - headRadius * 0.05);
    final rightEyeCenter = Offset(headCenter.dx + headRadius * 0.42, headCenter.dy - headRadius * 0.05);

    if (cat.id == 'bulut') {
      // Uykucu kapalı mutlu gözler (˘ω˘)
      final sleepEyePaint = Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      final arcRectL = Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius);
      final arcRectR = Rect.fromCircle(center: rightEyeCenter, radius: eyeRadius);
      canvas.drawArc(arcRectL, math.pi * 0.15, math.pi * 0.7, false, sleepEyePaint);
      canvas.drawArc(arcRectR, math.pi * 0.15, math.pi * 0.7, false, sleepEyePaint);
    } else {
      // Büyük ışıltılı gözler
      final eyePaint = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

      // Göz bebekleri
      final pupilPaint = Paint()..color = const Color(0xFF263238);
      canvas.drawCircle(leftEyeCenter, eyeRadius * 0.65, pupilPaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius * 0.65, pupilPaint);

      // Göz ışıltısı (Beyaz parıltı)
      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(leftEyeCenter.dx - eyeRadius * 0.28, leftEyeCenter.dy - eyeRadius * 0.28),
        eyeRadius * 0.32,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(rightEyeCenter.dx - eyeRadius * 0.28, rightEyeCenter.dy - eyeRadius * 0.28),
        eyeRadius * 0.32,
        shinePaint,
      );
    }

    // Yanaklar (Pembe allık)
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.58, headCenter.dy + headRadius * 0.22),
      headRadius * 0.16,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.58, headCenter.dy + headRadius * 0.22),
      headRadius * 0.16,
      blushPaint,
    );

    // Burun (Pembe üçgen)
    final noseCenter = Offset(headCenter.dx, headCenter.dy + headRadius * 0.15);
    final nosePath = Path()
      ..moveTo(noseCenter.dx - 6, noseCenter.dy - 3)
      ..lineTo(noseCenter.dx + 6, noseCenter.dy - 3)
      ..lineTo(noseCenter.dx, noseCenter.dy + 4)
      ..close();
    final nosePaint = Paint()
      ..color = const Color(0xFFFF6E6E)
      ..style = PaintingStyle.fill;
    canvas.drawPath(nosePath, nosePaint);

    // Ağız (Kedi gülüşü: w)
    final mouthPaint = Paint()
      ..color = const Color(0xFF4A403A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(noseCenter.dx - 12, noseCenter.dy + 8)
      ..quadraticBezierTo(noseCenter.dx - 6, noseCenter.dy + 15, noseCenter.dx, noseCenter.dy + 5)
      ..quadraticBezierTo(noseCenter.dx + 6, noseCenter.dy + 15, noseCenter.dx + 12, noseCenter.dy + 8);
    canvas.drawPath(mouthPath, mouthPaint);

    // Bıyıklar (3 sol, 3 sağ)
    final whiskerPaint = Paint()
      ..color = const Color(0xFF5D4037).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Sol bıyıklar
    canvas.drawLine(
      Offset(headCenter.dx - headRadius * 0.45, headCenter.dy + headRadius * 0.18),
      Offset(headCenter.dx - headRadius * 1.05, headCenter.dy + headRadius * 0.08),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx - headRadius * 0.45, headCenter.dy + headRadius * 0.28),
      Offset(headCenter.dx - headRadius * 1.05, headCenter.dy + headRadius * 0.32),
      whiskerPaint,
    );

    // Sağ bıyıklar
    canvas.drawLine(
      Offset(headCenter.dx + headRadius * 0.45, headCenter.dy + headRadius * 0.18),
      Offset(headCenter.dx + headRadius * 1.05, headCenter.dy + headRadius * 0.08),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx + headRadius * 0.45, headCenter.dy + headRadius * 0.28),
      Offset(headCenter.dx + headRadius * 1.05, headCenter.dy + headRadius * 0.32),
      whiskerPaint,
    );

    // Alt Patiler (Masanın üzerinden bakan iki tatlı pati)
    final pawRadius = w * 0.075;
    final pawPaint = Paint()
      ..color = furColor
      ..style = PaintingStyle.fill;

    final leftPaw = Offset(w * 0.35, h * 0.88);
    final rightPaw = Offset(w * 0.65, h * 0.88);
    canvas.drawCircle(leftPaw, pawRadius, pawPaint);
    canvas.drawCircle(rightPaw, pawRadius, pawPaint);
    canvas.drawCircle(leftPaw, pawRadius, outlinePaint);
    canvas.drawCircle(rightPaw, pawRadius, outlinePaint);

    // Pati çizgileri
    final padPaint = Paint()
      ..color = const Color(0xFFFFAB91).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftPaw, pawRadius * 0.45, padPaint);
    canvas.drawCircle(rightPaw, pawRadius * 0.45, padPaint);
  }

  @override
  bool shouldRepaint(covariant CatArtPainter oldDelegate) =>
      oldDelegate.cat.id != cat.id;
}
