// lib/features/puzzle/widgets/cat_art_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/cat_art.dart';

/// Sevimli vektörel kedi illüstrasyonu.
/// Asset dosyası gerektirmeden Canvas ile çizilir; tüm çözünürlüklerde keskin ve pürüzsüzdür.
/// 3x3, 4x4 ve 5x5 puzzle dilimlerinde her parçanın görsel detayı olacak şekilde zenginleştirilmiştir.
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

    // 1. Arka plan pastel gradyan (Full bleed)
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cat.color,
          cat.color.withOpacity(0.65),
          const Color(0xFFFFF9F5),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Alt Kısım: Ahşap Masa / Masa Kenarı (Alt sıra parçalarına zemin detayı verir)
    final tableTop = h * 0.81;
    final tableRect = Rect.fromLTWH(0, tableTop, w, h - tableTop);
    final tablePaint = Paint()..color = const Color(0xFFE1C6A8);
    canvas.drawRect(tableRect, tablePaint);

    final woodLinePaint = Paint()
      ..color = const Color(0xFFB49169)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.008);
    canvas.drawLine(Offset(0, tableTop), Offset(w, tableTop), woodLinePaint);

    // Ahşap damarları
    final grainPaint = Paint()
      ..color = const Color(0xFFCDB08C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.005);
    canvas.drawLine(
        Offset(w * 0.08, h * 0.90), Offset(w * 0.40, h * 0.90), grainPaint);
    canvas.drawLine(
        Offset(w * 0.58, h * 0.93), Offset(w * 0.92, h * 0.93), grainPaint);

    // 3. Sol Üst: Sevimli Yün Yumağı (Sol üst parçalar için renkli görsel detay)
    final yarnCenter = Offset(w * 0.16, h * 0.18);
    final yarnRadius = w * 0.08;
    final yarnPaint = Paint()
      ..color = const Color(0xFFFF8A80)
      ..style = PaintingStyle.fill;
    final yarnBorder = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.006);
    canvas.drawCircle(yarnCenter, yarnRadius, yarnPaint);
    canvas.drawCircle(yarnCenter, yarnRadius, yarnBorder);

    // Yün sarım çizgileri & ip kuyruğu
    final yarnThreadPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.006);
    canvas.drawArc(
      Rect.fromCircle(center: yarnCenter, radius: yarnRadius * 0.72),
      math.pi * 0.2,
      math.pi * 1.2,
      false,
      yarnThreadPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: yarnCenter, radius: yarnRadius * 0.45),
      math.pi * 0.9,
      math.pi * 1.1,
      false,
      yarnThreadPaint,
    );
    // Yünden sarkan sevimli ip
    final yarnString = Path()
      ..moveTo(yarnCenter.dx + yarnRadius * 0.8, yarnCenter.dy + yarnRadius * 0.3)
      ..quadraticBezierTo(w * 0.24, h * 0.22, w * 0.27, h * 0.28);
    canvas.drawPath(yarnString, yarnBorder);

    // 4. Sağ Üst: Uçuşan Kalp & Parıltılı Yıldız (Sağ üst parçalar için)
    final heartCenter = Offset(w * 0.83, h * 0.17);
    final heartPaint = Paint()
      ..color = const Color(0xFFF06292).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    _drawHeart(canvas, heartCenter, w * 0.048, heartPaint);

    // Küçük sarı parıltı yıldız
    final starCenter = Offset(w * 0.70, h * 0.21);
    final starPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    _drawSparkle(canvas, starCenter, w * 0.032, starPaint);
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.26), w * 0.022, starPaint);

    // 5. Sol Alt: Masadaki Balık Kraker (Sol alt parçalar için)
    final fishCenter = Offset(w * 0.15, h * 0.89);
    final fishPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    final fishBorder = Paint()
      ..color = const Color(0xFFF57C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fishBody = Rect.fromCenter(
        center: fishCenter, width: w * 0.11, height: w * 0.055);
    canvas.drawOval(fishBody, fishPaint);
    canvas.drawOval(fishBody, fishBorder);
    // Kuyruk
    final tail = Path()
      ..moveTo(fishCenter.dx - w * 0.05, fishCenter.dy)
      ..lineTo(fishCenter.dx - w * 0.08, fishCenter.dy - w * 0.025)
      ..lineTo(fishCenter.dx - w * 0.08, fishCenter.dy + w * 0.025)
      ..close();
    canvas.drawPath(tail, fishPaint);
    canvas.drawPath(tail, fishBorder);
    // Göz noktası
    canvas.drawCircle(Offset(fishCenter.dx + w * 0.03, fishCenter.dy - 1), 1.8,
        Paint()..color = const Color(0xFF5D4037));

    // 6. Sağ Alt: Pati İzi (Sağ alt parçalar için)
    final pawCenter = Offset(w * 0.85, h * 0.90);
    final pawMarkPaint = Paint()
      ..color = const Color(0xFFFFAB91).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final pR = w * 0.032;
    canvas.drawCircle(pawCenter, pR, pawMarkPaint);
    canvas.drawCircle(Offset(pawCenter.dx - pR * 0.7, pawCenter.dy - pR * 0.9),
        pR * 0.36, pawMarkPaint);
    canvas.drawCircle(Offset(pawCenter.dx, pawCenter.dy - pR * 1.15),
        pR * 0.36, pawMarkPaint);
    canvas.drawCircle(Offset(pawCenter.dx + pR * 0.7, pawCenter.dy - pR * 0.9),
        pR * 0.36, pawMarkPaint);

    // 7. Kedi Renkleri
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

    final furPaint = Paint()
      ..color = furColor
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF4A403A).withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, w * 0.007);

    // 8. Kedi Gövdesi (Alt-Orta)
    final bodyRect =
        Rect.fromLTWH(w * 0.20, h * 0.54, w * 0.60, h * 0.36);
    canvas.drawOval(bodyRect, furPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // 9. Kedi Başı ve Kulaklar
    final headRadius = w * 0.30;
    final headCenter = Offset(w * 0.50, h * 0.45);

    // Kulaklar
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFAB91).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Sol kulak
    final leftEar = Path()
      ..moveTo(headCenter.dx - headRadius * 0.85, headCenter.dy - headRadius * 0.20)
      ..lineTo(headCenter.dx - headRadius * 0.85, headCenter.dy - headRadius * 1.15)
      ..lineTo(headCenter.dx - headRadius * 0.20, headCenter.dy - headRadius * 0.75)
      ..close();
    canvas.drawPath(leftEar, furPaint);
    canvas.drawPath(leftEar, outlinePaint);

    final leftInnerEar = Path()
      ..moveTo(headCenter.dx - headRadius * 0.80, headCenter.dy - headRadius * 0.28)
      ..lineTo(headCenter.dx - headRadius * 0.80, headCenter.dy - headRadius * 0.98)
      ..lineTo(headCenter.dx - headRadius * 0.30, headCenter.dy - headRadius * 0.70)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    // Sağ kulak
    final rightEar = Path()
      ..moveTo(headCenter.dx + headRadius * 0.85, headCenter.dy - headRadius * 0.20)
      ..lineTo(headCenter.dx + headRadius * 0.85, headCenter.dy - headRadius * 1.15)
      ..lineTo(headCenter.dx + headRadius * 0.20, headCenter.dy - headRadius * 0.75)
      ..close();
    canvas.drawPath(rightEar, furPaint);
    canvas.drawPath(rightEar, outlinePaint);

    final rightInnerEar = Path()
      ..moveTo(headCenter.dx + headRadius * 0.80, headCenter.dy - headRadius * 0.28)
      ..lineTo(headCenter.dx + headRadius * 0.80, headCenter.dy - headRadius * 0.98)
      ..lineTo(headCenter.dx + headRadius * 0.30, headCenter.dy - headRadius * 0.70)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // Baş Çemberi
    canvas.drawCircle(headCenter, headRadius, furPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Alın çizgileri (Tekir kediler için)
    if (cat.id == 'seftali' || cat.id == 'fistik' || cat.id == 'limon') {
      final stripePaint = Paint()
        ..color = stripeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.5, w * 0.012)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(headCenter.dx, headCenter.dy - headRadius * 0.85),
        Offset(headCenter.dx, headCenter.dy - headRadius * 0.55),
        stripePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx - headRadius * 0.22, headCenter.dy - headRadius * 0.75),
        Offset(headCenter.dx - headRadius * 0.15, headCenter.dy - headRadius * 0.50),
        stripePaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + headRadius * 0.22, headCenter.dy - headRadius * 0.75),
        Offset(headCenter.dx + headRadius * 0.15, headCenter.dy - headRadius * 0.50),
        stripePaint,
      );
    }

    // 10. Tasma & Parlak Altın Çan (Göğüs hizası detayı)
    final collarY = h * 0.73;
    final collarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(headCenter.dx, collarY),
          width: w * 0.26,
          height: w * 0.038),
      const Radius.circular(6),
    );
    canvas.drawRRect(collarRect, Paint()..color = const Color(0xFFFF7043));

    final bellCenter = Offset(headCenter.dx, collarY + w * 0.024);
    final bellRadius = w * 0.038;
    final bellPaint = Paint()..color = const Color(0xFFFFD54F);
    final bellBorder = Paint()
      ..color = const Color(0xFFF57F17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(bellCenter, bellRadius, bellPaint);
    canvas.drawCircle(bellCenter, bellRadius, bellBorder);
    // Çan yarığı
    canvas.drawLine(
      Offset(bellCenter.dx - bellRadius * 0.6, bellCenter.dy + bellRadius * 0.3),
      Offset(bellCenter.dx + bellRadius * 0.6, bellCenter.dy + bellRadius * 0.3),
      bellBorder,
    );
    canvas.drawCircle(Offset(bellCenter.dx, bellCenter.dy + bellRadius * 0.3),
        1.6, Paint()..color = const Color(0xFFF57F17));

    // 11. Masaya Dayalı Sevimli Ön Patiler
    final pawRadius = w * 0.065;
    final leftPawCenter = Offset(w * 0.34, tableTop + pawRadius * 0.15);
    final rightPawCenter = Offset(w * 0.66, tableTop + pawRadius * 0.15);
    canvas.drawCircle(leftPawCenter, pawRadius, furPaint);
    canvas.drawCircle(leftPawCenter, pawRadius, outlinePaint);
    canvas.drawCircle(rightPawCenter, pawRadius, furPaint);
    canvas.drawCircle(rightPawCenter, pawRadius, outlinePaint);

    // Pati iç pembe pedleri
    canvas.drawCircle(leftPawCenter, pawRadius * 0.45, innerEarPaint);
    canvas.drawCircle(rightPawCenter, pawRadius * 0.45, innerEarPaint);

    // 12. Gözler
    final eyeRadius = headRadius * 0.19;
    final leftEyeCenter =
        Offset(headCenter.dx - headRadius * 0.42, headCenter.dy - headRadius * 0.05);
    final rightEyeCenter =
        Offset(headCenter.dx + headRadius * 0.42, headCenter.dy - headRadius * 0.05);

    if (cat.id == 'bulut') {
      // Uykucu kapalı mutlu gözler (˘ω˘)
      final sleepEyePaint = Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.8, w * 0.011)
        ..strokeCap = StrokeCap.round;
      final arcRectL = Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius);
      final arcRectR = Rect.fromCircle(center: rightEyeCenter, radius: eyeRadius);
      canvas.drawArc(arcRectL, math.pi * 0.15, math.pi * 0.7, false, sleepEyePaint);
      canvas.drawArc(arcRectR, math.pi * 0.15, math.pi * 0.7, false, sleepEyePaint);
    } else {
      // Büyük ışıldayan gözler
      final eyePaint = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

      // Göz bebekleri
      final pupilPaint = Paint()..color = const Color(0xFF263238);
      canvas.drawCircle(leftEyeCenter, eyeRadius * 0.65, pupilPaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius * 0.65, pupilPaint);

      // Çift beyaz ışık yansıması
      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(leftEyeCenter.dx - eyeRadius * 0.32,
            leftEyeCenter.dy - eyeRadius * 0.32),
        eyeRadius * 0.32,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(rightEyeCenter.dx - eyeRadius * 0.32,
            rightEyeCenter.dy - eyeRadius * 0.32),
        eyeRadius * 0.32,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(leftEyeCenter.dx + eyeRadius * 0.28,
            leftEyeCenter.dy + eyeRadius * 0.25),
        eyeRadius * 0.16,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(rightEyeCenter.dx + eyeRadius * 0.28,
            rightEyeCenter.dy + eyeRadius * 0.25),
        eyeRadius * 0.16,
        shinePaint,
      );
    }

    // 13. Yanaklar (Pembe tatlı allık)
    final blushRadius = headRadius * 0.18;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.60, headCenter.dy + headRadius * 0.22),
      blushRadius,
      innerEarPaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.60, headCenter.dy + headRadius * 0.22),
      blushRadius,
      innerEarPaint,
    );

    // 14. Burun (Pembe üçgen)
    final noseCenter = Offset(headCenter.dx, headCenter.dy + headRadius * 0.16);
    final nW = math.max(6.0, w * 0.022);
    final nH = math.max(4.0, w * 0.015);
    final nosePath = Path()
      ..moveTo(noseCenter.dx - nW, noseCenter.dy - nH * 0.6)
      ..lineTo(noseCenter.dx + nW, noseCenter.dy - nH * 0.6)
      ..lineTo(noseCenter.dx, noseCenter.dy + nH)
      ..close();
    canvas.drawPath(
        nosePath,
        Paint()
          ..color = const Color(0xFFFF6E6E)
          ..style = PaintingStyle.fill);

    // 15. Ağız (Kedi gülüşü: w)
    final mouthPaint = Paint()
      ..color = const Color(0xFF4A403A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.008)
      ..strokeCap = StrokeCap.round;

    final mW = math.max(10.0, w * 0.038);
    final mouthPath = Path()
      ..moveTo(noseCenter.dx - mW * 2, noseCenter.dy + nH * 1.5)
      ..quadraticBezierTo(noseCenter.dx - mW, noseCenter.dy + nH * 3.0,
          noseCenter.dx, noseCenter.dy + nH * 1.2)
      ..quadraticBezierTo(noseCenter.dx + mW, noseCenter.dy + nH * 3.0,
          noseCenter.dx + mW * 2, noseCenter.dy + nH * 1.5);
    canvas.drawPath(mouthPath, mouthPaint);

    // 16. Bıyıklar (Sol & Sağ 3'er adet)
    final whiskerPaint = Paint()
      ..color = const Color(0xFF5D4037).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.006)
      ..strokeCap = StrokeCap.round;

    final whiskerOffsets = [
      -headRadius * 0.06,
      headRadius * 0.06,
      headRadius * 0.18
    ];
    for (final dy in whiskerOffsets) {
      // Sol bıyıklar
      canvas.drawLine(
        Offset(headCenter.dx - headRadius * 0.65, headCenter.dy + headRadius * 0.20 + dy),
        Offset(headCenter.dx - headRadius * 1.18, headCenter.dy + headRadius * 0.15 + dy * 1.4),
        whiskerPaint,
      );
      // Sağ bıyıklar
      canvas.drawLine(
        Offset(headCenter.dx + headRadius * 0.65, headCenter.dy + headRadius * 0.20 + dy),
        Offset(headCenter.dx + headRadius * 1.18, headCenter.dy + headRadius * 0.15 + dy * 1.4),
        whiskerPaint,
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.7);
    path.cubicTo(
      center.dx - size * 1.2,
      center.dy - size * 0.3,
      center.dx - size * 0.6,
      center.dy - size * 1.1,
      center.dx,
      center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 0.6,
      center.dy - size * 1.1,
      center.dx + size * 1.2,
      center.dy - size * 0.3,
      center.dx,
      center.dy + size * 0.7,
    );
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CatArtPainter oldDelegate) =>
      oldDelegate.cat.id != cat.id;
}
