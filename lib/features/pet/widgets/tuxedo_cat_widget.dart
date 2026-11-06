// lib/features/pet/widgets/tuxedo_cat_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pet_state.dart';

class TuxedoCatWidget extends StatefulWidget {
  const TuxedoCatWidget({
    super.key,
    required this.action,
    required this.isSleeping,
    required this.isGrooming,
    required this.isMeowing,
  });

  final PetActionKind action;
  final bool isSleeping;
  final bool isGrooming;
  final bool isMeowing;

  /// Hibrit Görsel Mod: Sprite sheet açma/kapama bayrağı
  static const bool useSpriteSheet = false;

  @override
  State<TuxedoCatWidget> createState() => _TuxedoCatWidgetState();
}

class _TuxedoCatWidgetState extends State<TuxedoCatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = reducedMotion ? 0.0 : _anim.value;

        return CustomPaint(
          size: const Size(220, 180),
          painter: _TuxedoCatPainter(
            t: t,
            action: widget.action,
            isSleeping: widget.isSleeping,
            isGrooming: widget.isGrooming,
            isMeowing: widget.isMeowing,
          ),
        );
      },
    );
  }
}

class _TuxedoCatPainter extends CustomPainter {
  _TuxedoCatPainter({
    required this.t,
    required this.action,
    required this.isSleeping,
    required this.isGrooming,
    required this.isMeowing,
  });

  final double t; // 0.0 .. 1.0 (4 seconds loop)
  final PetActionKind action;
  final bool isSleeping;
  final bool isGrooming;
  final bool isMeowing;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.72);

    // ──────────────── 1. GÖLGE VE POFUDUK MAVİ MİNDER ────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 22), width: w * 0.88, height: 42),
      shadowPaint,
    );

    // Minder dış tabanı (Koyu pastel mavi gölge)
    final cushionBasePaint = Paint()..color = const Color(0xFF7FA8D0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 16), width: w * 0.86, height: 48),
        const Radius.circular(26),
      ),
      cushionBasePaint,
    );

    // Minder üst pofuduk kısmı (Açık pastel mavi)
    final cushionTopPaint = Paint()..color = const Color(0xFFA2CAEF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 10), width: w * 0.84, height: 46),
        const Radius.circular(24),
      ),
      cushionTopPaint,
    );

    // Minder dikiş / püskül detayları
    final stitchPaint = Paint()
      ..color = const Color(0xFF8BB5DF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center.translate(-w * 0.32, 10), 3, stitchPaint);
    canvas.drawCircle(center.translate(w * 0.32, 10), 3, stitchPaint);
    canvas.drawCircle(center.translate(0, 18), 3, stitchPaint);

    // ──────────────── 2. KEDİ ANİMASYON MATEMATİĞİ ────────────────
    // Nefes alma (3-4 sn döngü)
    final breath = math.sin(t * 2 * math.pi) * 3.0;
    // Kuyruk salınımı
    final tailSway = math.sin(t * 2 * math.pi) * 0.22;
    // Göz kırpma (4 saniyede bir kısa kırpış)
    final isBlinking = !isSleeping && (t > 0.92 && t < 0.98);

    // Çizim durumuna göre parametreler
    final catCenter = center.translate(0, isSleeping ? 0 : -breath);

    // ──────────────── 3. KUYRUK (Siyah + Beyaz Uç) ────────────────
    final tailPaint = Paint()
      ..color = const Color(0xFF222428)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final tailPath = Path();
    if (isSleeping) {
      // Uyurken kuyruk patilerin etrafına sarılır
      tailPath.moveTo(catCenter.dx - 35, catCenter.dy + 8);
      tailPath.quadraticBezierTo(
        catCenter.dx - 65,
        catCenter.dy + 16,
        catCenter.dx - 20,
        catCenter.dy + 18,
      );
    } else {
      // Uyanıkken kuyruk yukarı doğru kıvrılır ve sallanır
      final tailAngle = tailSway;
      tailPath.moveTo(catCenter.dx + 40, catCenter.dy - 2);
      tailPath.cubicTo(
        catCenter.dx + 65 + tailAngle * 30,
        catCenter.dy - 10,
        catCenter.dx + 70 + tailAngle * 45,
        catCenter.dy - 45,
        catCenter.dx + 55 + tailAngle * 35,
        catCenter.dy - 55,
      );
    }
    canvas.drawPath(tailPath, tailPaint);

    // Kuyruğun beyaz ucu
    if (!isSleeping) {
      final tailTipPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final tipPath = Path();
      tipPath.moveTo(catCenter.dx + 60 + tailSway * 38, catCenter.dy - 50);
      tipPath.lineTo(catCenter.dx + 55 + tailSway * 35, catCenter.dy - 55);
      canvas.drawPath(tipPath, tailTipPaint);
    }

    // ──────────────── 4. GÖVDE (Siyah Tuxedo) ────────────────
    final blackFurPaint = Paint()..color = const Color(0xFF222428);

    if (isSleeping) {
      // Uyku modu: Kıvrılmış yuvarlak gövde
      canvas.drawOval(
        Rect.fromCenter(center: catCenter.translate(-4, -6), width: 94, height: 62),
        blackFurPaint,
      );
    } else {
      // Oturur pozisyon: armut biçimli tombul gövde
      final bodyPath = Path();
      bodyPath.moveTo(catCenter.dx - 38, catCenter.dy + 14);
      bodyPath.cubicTo(
        catCenter.dx - 48,
        catCenter.dy - 15,
        catCenter.dx - 32,
        catCenter.dy - 52,
        catCenter.dx,
        catCenter.dy - 52,
      );
      bodyPath.cubicTo(
        catCenter.dx + 32,
        catCenter.dy - 52,
        catCenter.dx + 48,
        catCenter.dy - 15,
        catCenter.dx + 38,
        catCenter.dy + 14,
      );
      bodyPath.close();
      canvas.drawPath(bodyPath, blackFurPaint);
    }

    // ──────────────── 5. BEYAZ TUXEDO ÖNLÜĞÜ (GÖĞÜS) ────────────────
    final whiteFurPaint = Paint()..color = Colors.white;

    if (!isSleeping) {
      final bibPath = Path();
      bibPath.moveTo(catCenter.dx - 16, catCenter.dy - 35);
      bibPath.quadraticBezierTo(
        catCenter.dx - 22,
        catCenter.dy - 10,
        catCenter.dx,
        catCenter.dy + 8,
      );
      bibPath.quadraticBezierTo(
        catCenter.dx + 22,
        catCenter.dy - 10,
        catCenter.dx + 16,
        catCenter.dy - 35,
      );
      bibPath.close();
      canvas.drawPath(bibPath, whiteFurPaint);
    }

    // ──────────────── 6. PATİLER (Beyaz Çoraplı) ────────────────
    if (!isSleeping) {
      // Sol Pati
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: catCenter.translate(-16, 12), width: 18, height: 16),
          const Radius.circular(8),
        ),
        whiteFurPaint,
      );
      // Sağ Pati (Grooming sırasında yüzüne doğru kalkar)
      if (isGrooming) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: catCenter.translate(18, -26), width: 16, height: 18),
            const Radius.circular(8),
          ),
          whiteFurPaint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: catCenter.translate(16, 12), width: 18, height: 16),
            const Radius.circular(8),
          ),
          whiteFurPaint,
        );
      }
    }

    // ──────────────── 7. KAFA VE KULAKLAR ────────────────
    final headCenter = isSleeping
        ? catCenter.translate(16, -10)
        : catCenter.translate(0, -56);

    // Kulaklar (Siyah üçgen)
    final earPathLeft = Path();
    earPathLeft.moveTo(headCenter.dx - 28, headCenter.dy - 10);
    earPathLeft.lineTo(headCenter.dx - 34, headCenter.dy - 44);
    earPathLeft.lineTo(headCenter.dx - 10, headCenter.dy - 24);
    earPathLeft.close();
    canvas.drawPath(earPathLeft, blackFurPaint);

    final earPathRight = Path();
    earPathRight.moveTo(headCenter.dx + 10, headCenter.dy - 24);
    earPathRight.lineTo(headCenter.dx + 34, headCenter.dy - 44);
    earPathRight.lineTo(headCenter.dx + 28, headCenter.dy - 10);
    earPathRight.close();
    canvas.drawPath(earPathRight, blackFurPaint);

    // Pembe kulak içi
    final innerEarPaint = Paint()..color = const Color(0xFFFFA8B8);
    final innerEarL = Path();
    innerEarL.moveTo(headCenter.dx - 25, headCenter.dy - 12);
    innerEarL.lineTo(headCenter.dx - 30, headCenter.dy - 38);
    innerEarL.lineTo(headCenter.dx - 13, headCenter.dy - 22);
    innerEarL.close();
    canvas.drawPath(innerEarL, innerEarPaint);

    final innerEarR = Path();
    innerEarR.moveTo(headCenter.dx + 13, headCenter.dy - 22);
    innerEarR.lineTo(headCenter.dx + 30, headCenter.dy - 38);
    innerEarR.lineTo(headCenter.dx + 25, headCenter.dy - 12);
    innerEarR.close();
    canvas.drawPath(innerEarR, innerEarPaint);

    // Kafa yuvarlağı
    canvas.drawCircle(headCenter, 32, blackFurPaint);

    // Yüzde beyaz üçgen tuxedo maskesi
    final faceWhite = Path();
    faceWhite.moveTo(headCenter.dx - 14, headCenter.dy + 8);
    faceWhite.quadraticBezierTo(
      headCenter.dx,
      headCenter.dy - 14,
      headCenter.dx + 14,
      headCenter.dy + 8,
    );
    faceWhite.quadraticBezierTo(
      headCenter.dx,
      headCenter.dy + 26,
      headCenter.dx - 14,
      headCenter.dy + 8,
    );
    faceWhite.close();
    canvas.drawPath(faceWhite, whiteFurPaint);

    // ──────────────── 8. GÖZLER, BURUN, AĞIZ ────────────────
    final pinkNosePaint = Paint()..color = const Color(0xFFFF859E);

    // Burun
    final nosePath = Path();
    nosePath.moveTo(headCenter.dx - 4, headCenter.dy + 4);
    nosePath.lineTo(headCenter.dx + 4, headCenter.dy + 4);
    nosePath.lineTo(headCenter.dx, headCenter.dy + 8);
    nosePath.close();
    canvas.drawPath(nosePath, pinkNosePaint);

    // Ağız çizgisi
    final mouthPaint = Paint()
      ..color = const Color(0xFF222428)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    if (isMeowing) {
      // Miyavlama: Ağız açık
      final openMouth = Paint()..color = const Color(0xFFFF6B88);
      canvas.drawOval(
        Rect.fromCenter(center: headCenter.translate(0, 13), width: 9, height: 11),
        openMouth,
      );
    } else {
      // Tatlı kedi ağzı :3
      canvas.drawArc(
        Rect.fromCenter(center: headCenter.translate(-4, 10), width: 8, height: 6),
        0,
        math.pi,
        false,
        mouthPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: headCenter.translate(4, 10), width: 8, height: 6),
        0,
        math.pi,
        false,
        mouthPaint,
      );
    }

    // Bıyıklar
    final whiskerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    // Sol bıyıklar
    canvas.drawLine(headCenter.translate(-16, 7), headCenter.translate(-38, 4), whiskerPaint);
    canvas.drawLine(headCenter.translate(-16, 11), headCenter.translate(-36, 15), whiskerPaint);
    // Sağ bıyıklar
    canvas.drawLine(headCenter.translate(16, 7), headCenter.translate(38, 4), whiskerPaint);
    canvas.drawLine(headCenter.translate(16, 11), headCenter.translate(36, 15), whiskerPaint);

    // Gözler
    final eyesClosed = isSleeping || isBlinking || action == PetActionKind.petting;

    if (eyesClosed) {
      // Mutlu kapalı gözler: ^ ^
      final closedEyePaint = Paint()
        ..color = isSleeping ? const Color(0xFF4B4D52) : const Color(0xFF222428)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Sol göz
      canvas.drawArc(
        Rect.fromCenter(center: headCenter.translate(-13, -3), width: 12, height: 8),
        math.pi,
        math.pi,
        false,
        closedEyePaint,
      );
      // Sağ göz
      canvas.drawArc(
        Rect.fromCenter(center: headCenter.translate(13, -3), width: 12, height: 8),
        math.pi,
        math.pi,
        false,
        closedEyePaint,
      );
    } else {
      // Parlak iri gözler (Zümrüt Yeşili kedi gözü)
      final eyeGreen = Paint()..color = const Color(0xFF43B581);
      final pupilPaint = Paint()..color = const Color(0xFF14171A);
      final shinePaint = Paint()..color = Colors.white;

      for (final eyeX in [-13.0, 13.0]) {
        final eyeCenter = headCenter.translate(eyeX, -3);
        // İris
        canvas.drawOval(
          Rect.fromCenter(center: eyeCenter, width: 13, height: 15),
          eyeGreen,
        );
        // Gözbebeği
        canvas.drawOval(
          Rect.fromCenter(center: eyeCenter, width: 8, height: 12),
          pupilPaint,
        );
        // Işıltı / Parıltı (Anime parıltısı)
        canvas.drawCircle(eyeCenter.translate(-2, -3), 2.5, shinePaint);
        canvas.drawCircle(eyeCenter.translate(2, 2), 1.2, shinePaint);
      }
    }

    // ──────────────── 9. YEMEK KABI / BALIK (BESLEME MODUNDA) ────────────────
    if (action == PetActionKind.eating) {
      final bowlCenter = center.translate(38, 8);
      // Mama kasesi
      final bowlPaint = Paint()..color = const Color(0xFFFFB347);
      canvas.drawArc(
        Rect.fromCenter(center: bowlCenter, width: 28, height: 22),
        0,
        math.pi,
        true,
        bowlPaint,
      );
      // İçindeki lezzetli balık
      final fishPaint = Paint()..color = const Color(0xFFFF6961);
      canvas.drawOval(
        Rect.fromCenter(center: bowlCenter.translate(0, -2), width: 16, height: 8),
        fishPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TuxedoCatPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.action != action ||
        oldDelegate.isSleeping != isSleeping ||
        oldDelegate.isGrooming != isGrooming ||
        oldDelegate.isMeowing != isMeowing;
  }
}
