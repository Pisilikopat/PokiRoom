// lib/features/pet/widgets/tuxedo_cat_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/pet_state.dart';

class TuxedoCatWidget extends StatefulWidget {
  const TuxedoCatWidget({
    super.key,
    required this.action,
    required this.isSleeping,
    required this.isGrooming,
    required this.isMeowing,
    this.onReaction,
    this.headAnchor,
  });

  /// Kedinin kafa merkezini (widget-yerel koordinat, 220x180 alan) her karede
  /// buraya yazar. EffectsLayer kalp/Zzz/balon efektlerini bununla kediye bağlar.
  final ValueNotifier<Offset>? headAnchor;

  final PetActionKind action;
  final bool isSleeping;
  final bool isGrooming;
  final bool isMeowing;

  /// Kediye 3 kez üst üste dokunulunca "Mrrp! 🐾" gibi bir metinle çağrılır.
  /// Üst widget bunu EffectsLayer.speechBubble olarak gösterebilir.
  final ValueChanged<String>? onReaction;

  /// Hibrit Görsel Mod: Sprite sheet açma/kapama bayrağı
  static const bool useSpriteSheet = false;

  @override
  State<TuxedoCatWidget> createState() => _TuxedoCatWidgetState();
}

/// Painter'ın okuduğu, her karede güncellenen değişken durum.
/// ChangeNotifier olduğu için CustomPainter(repaint: frame) ile
/// widget ağacını yeniden kurmadan sadece çizim tazelenir.
class _CatFrame extends ChangeNotifier {
  double time = 0; // saniye (sadece hareket açıkken ilerler)

  // Yumuşatılmış (blend) değerler, hepsi 0..1
  double sleep = 0; // 0 = oturuyor, 1 = kıvrılmış uyuyor
  double eat = 0; // yemek kabı belirme + kafa eğme
  double knead = 0; // sevilirken yoğurma + mırıldanma
  double tailCurl = 0; // mutluyken kuyruk ucu "?" kıvrımı
  double groom = 0; // pati yüze çıkma
  double eyeClose = 0; // 0 açık, 1 kapalı
  double mouth = 0; // ağız açıklığı
  double earFlat = 0; // kulaklar yatık
  double fidget = 0; // uyku seğirmesi

  // Göz takibi (-1..1)
  double lookX = 0;
  double lookY = 0;

  // Zıplama / ezilme
  double hopY = 0;
  double squash = 1;

  // Painter'ın her çizimde yazdığı güncel kafa merkezi (yerel koordinat)
  Offset headPos = const Offset(110, 73);

  void bump() => notifyListeners();
}

class _TuxedoCatWidgetState extends State<TuxedoCatWidget>
    with SingleTickerProviderStateMixin {
  static const Size _size = Size(220, 180);

  late final Ticker _ticker;
  final _CatFrame _f = _CatFrame();
  final math.Random _rng = math.Random();

  bool _reduced = false;
  double _lastT = 0; // ticker saati (hareket kısıtlı olsa bile ilerler)

  // Hedefler / zamanlayıcılar
  double _lookTX = 0, _lookTY = 0, _lookIdle = 99;
  double _meowLeft = 0, _earLeft = 0, _happyLeft = 0;
  double _hopElapsed = 0, _hopDur = 0, _hopH = 0;
  double _fidgetP = -1; // -1 = yok, 0..1 = oynuyor
  double _nextFidget = 3;
  final List<double> _taps = [];

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
  void dispose() {
    _ticker.dispose();
    _f.dispose();
    super.dispose();
  }

  // ───────────────────────── ETKİLEŞİM ─────────────────────────

  void _pointAt(Offset p) {
    if (_reduced) return;
    // Kafa merkezi yaklaşık (110, 73)
    _lookTX = ((p.dx - 110) / 110).clamp(-1.0, 1.0);
    _lookTY = ((p.dy - 73) / 90).clamp(-1.0, 1.0);
    _lookIdle = 0;
  }

  void _hop(double height, double duration) {
    if (_reduced) return;
    _hopH = height;
    _hopDur = duration;
    _hopElapsed = 0;
  }

  void _onTap(Offset pos) {
    _pointAt(pos);

    // Uyuyan kediye dokunulursa sadece rüyada seğirir
    if (widget.isSleeping) {
      _fidgetP = 0;
      return;
    }

    _taps.removeWhere((t) => _lastT - t > 2.5);
    _taps.add(_lastT);

    if (_taps.length == 1) {
      _meowLeft = 0.9; // 1. dokunuş: miyav + minik zıplama
      _hop(5, 0.35);
    } else if (_taps.length == 2) {
      _earLeft = 1.6; // 2. dokunuş: kulaklar yatar
      _hop(3, 0.30);
    } else {
      _meowLeft = 0.7; // 3. dokunuş: büyük sıçrama + mrrp
      _happyLeft = 2.5;
      _hop(12, 0.55);
      _taps.clear();
      widget.onReaction?.call('Mrrp! 🐾');
    }
  }

  // ───────────────────────── KARE GÜNCELLEME ─────────────────────────

  void _onTick(Duration elapsed) {
    final nowT = elapsed.inMicroseconds / 1e6;
    var dt = nowT - _lastT;
    _lastT = nowT;
    if (dt < 0) dt = 0;
    if (dt > 0.1) dt = 0.1; // arka plandan dönünce sıçrama olmasın

    final f = _f;
    final reduced = _reduced;
    double k(double rate) => reduced ? 1.0 : 1 - math.exp(-rate * dt);

    if (!reduced) f.time += dt;

    final sleeping = widget.isSleeping;
    final eating = widget.action == PetActionKind.eating && !sleeping;
    final petting = widget.action == PetActionKind.petting && !sleeping;

    // Zamanlayıcılar
    _meowLeft = math.max(0, _meowLeft - dt);
    _earLeft = math.max(0, _earLeft - dt);
    _happyLeft = math.max(0, _happyLeft - dt);
    _lookIdle += dt;
    if (_lookIdle > 2.5) {
      _lookTX = 0;
      _lookTY = 0;
    }

    // 3. Yumuşak geçişler (blending)
    f.sleep += ((sleeping ? 1.0 : 0.0) - f.sleep) * k(3);
    f.eat += ((eating ? 1.0 : 0.0) - f.eat) * k(5);
    f.knead += ((petting ? 1.0 : 0.0) - f.knead) * k(5);
    final happy = petting || eating || _happyLeft > 0;
    f.tailCurl += ((happy ? 1.0 : 0.0) - f.tailCurl) * k(4);
    f.groom += ((widget.isGrooming && !sleeping ? 1.0 : 0.0) - f.groom) * k(8);
    f.earFlat += ((_earLeft > 0 ? 1.0 : 0.0) - f.earFlat) * k(12);
    f.lookX += (_lookTX - f.lookX) * k(10);
    f.lookY += (_lookTY - f.lookY) * k(10);

    // Göz kırpma (4 sn'de bir ~0.24 sn)
    final b = f.time % 4.0;
    final blinking = !reduced && !sleeping && b > 3.68 && b < 3.92;
    final closeT = (sleeping || blinking || petting) ? 1.0 : 0.0;
    f.eyeClose += (closeT - f.eyeClose) * k(25);

    // Ağız: miyav = açık, yemek = çiğneme (saniyede 3 kez)
    double mouthT = 0;
    if (widget.isMeowing || _meowLeft > 0) {
      mouthT = 1;
    } else if (eating && !reduced) {
      mouthT = math.sin(f.time * 2 * math.pi * 3) > 0 ? 0.7 : 0.0;
    }
    f.mouth += (mouthT - f.mouth) * k(20);

    // Zıplama
    if (_hopDur > 0) {
      _hopElapsed += dt;
      final p = (_hopElapsed / _hopDur).clamp(0.0, 1.0);
      f.hopY = -_hopH * math.sin(math.pi * p);
      f.squash = 1 + 0.06 * math.sin(math.pi * p);
      if (p >= 1) {
        _hopDur = 0;
        f.hopY = 0;
        f.squash = 1;
      }
    }

    // 4. Uyku seğirmesi (rüya görme): 3-7 sn'de bir, 0.6 sn
    if (sleeping && f.sleep > 0.8 && !reduced) {
      _nextFidget -= dt;
      if (_nextFidget <= 0 && _fidgetP < 0) {
        _fidgetP = 0;
        _nextFidget = 3 + _rng.nextDouble() * 4;
      }
    }
    if (_fidgetP >= 0) {
      _fidgetP += dt / 0.6;
      if (_fidgetP >= 1) _fidgetP = -1;
    }
    f.fidget = _fidgetP >= 0
        ? math.sin(math.pi * _fidgetP) *
            (0.5 + 0.5 * math.sin(_fidgetP * 12)).clamp(0.0, 1.0)
        : 0;

    f.bump();

    // Efekt katmanına kafa konumunu bildir (küçük titreşimleri yok say)
    final anchor = widget.headAnchor;
    if (anchor != null && (anchor.value - f.headPos).distance > 0.4) {
      anchor.value = f.headPos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _pointAt(e.localPosition),
      onExit: (_) => _lookIdle = 2.5,
      // Listener kullanıyoruz: üst ScrollView ile jest kavgası yapmaz.
      child: Listener(
        onPointerDown: (e) => _pointAt(e.localPosition),
        onPointerMove: (e) => _pointAt(e.localPosition),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTap(d.localPosition),
          child: CustomPaint(
            size: _size,
            painter: _TuxedoCatPainter(_f),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── YARDIMCILAR ─────────────────────────

double _ease(double x) => x * x * (3 - 2 * x);
Offset _lo(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

void _star(Canvas c, Offset p, double r, Paint paint) {
  final path = Path()
    ..moveTo(p.dx, p.dy - r)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
    ..close();
  c.drawPath(path, paint);
}

// ───────────────────────── PAINTER ─────────────────────────

class _TuxedoCatPainter extends CustomPainter {
  _TuxedoCatPainter(this.f) : super(repaint: f);

  final _CatFrame f;

  static const _black = Color(0xFF222428);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.72);

    final s = _ease(f.sleep.clamp(0.0, 1.0)); // 1 = uyuyor
    final awake = 1 - s;

    _paintCushion(canvas, center, w);

    // Nefes + mırıldanma titremesi + zıplama
    final breath = math.sin(f.time * 2 * math.pi / 4) * 3.0 * (1 - 0.8 * s);
    final purrDx = math.sin(f.time * 2 * math.pi * 14) * 0.7 * f.knead;
    final catCenter = center.translate(purrDx, -breath + f.hopY);
    Offset o(double x, double y) => catCenter.translate(x, y);

    // Ezilme/uzama minder hizasından yapılır
    canvas.save();
    final pivot = center.translate(0, 14);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(1 / f.squash, f.squash);
    canvas.translate(-pivot.dx, -pivot.dy);

    final blackFur = Paint()..color = _black;
    final whiteFur = Paint()..color = Colors.white.withOpacity(awake);

    // ───────── KUYRUK ─────────
    final sway =
        math.sin(f.time * 2 * math.pi / 2.5) * 0.22 * (1 + 1.2 * f.tailCurl);
    final tStart = _lo(o(40, -2), o(-35, 8), s);
    final tC1 = _lo(o(65 + sway * 30, -10), o(-55, 13), s);
    final tC2 = _lo(o(70 + sway * 45, -45), o(-60, 17), s);
    final tEnd = _lo(o(55 + sway * 35, -55), o(-20, 18 - f.fidget * 4), s);
    final curl = f.tailCurl * awake; // 1. kuyruk ucu "?" kıvrımı

    final tailPath = Path()
      ..moveTo(tStart.dx, tStart.dy)
      ..cubicTo(tC1.dx, tC1.dy, tC2.dx, tC2.dy, tEnd.dx, tEnd.dy);
    if (curl > 0.01) {
      tailPath.quadraticBezierTo(
        tEnd.dx - 2,
        tEnd.dy - 14 * curl,
        tEnd.dx - 14 * curl,
        tEnd.dy - 14 * curl,
      );
    }
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = _black
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (awake > 0.02) {
      final hookEnd = tEnd.translate(-14 * curl, -14 * curl);
      final hookMid = tEnd.translate(-1 - 3.5 * curl, -10.5 * curl);
      final tipA = _lo(tEnd.translate(5, 5), hookMid, curl);
      final tipB = _lo(tEnd, hookEnd, curl);
      canvas.drawPath(
        Path()
          ..moveTo(tipA.dx, tipA.dy)
          ..lineTo(tipB.dx, tipB.dy),
        Paint()
          ..color = Colors.white.withOpacity(awake)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // ───────── GÖVDE (oturma ↔ kıvrılma morph) ─────────
    final b0 = _lo(o(-38, 14), o(-50, 20), s);
    final l1 = _lo(o(-48, -15), o(-56, -20), s);
    final l2 = _lo(o(-32, -52), o(-30, -37), s);
    final top = _lo(o(0, -52), o(-4, -37), s);
    final r1 = _lo(o(32, -52), o(24, -37), s);
    final r2 = _lo(o(48, -15), o(46, -20), s);
    final b1 = _lo(o(38, 14), o(42, 20), s);
    final bodyPath = Path()
      ..moveTo(b0.dx, b0.dy)
      ..cubicTo(l1.dx, l1.dy, l2.dx, l2.dy, top.dx, top.dy)
      ..cubicTo(r1.dx, r1.dy, r2.dx, r2.dy, b1.dx, b1.dy)
      ..close();
    canvas.drawPath(bodyPath, blackFur);

    // ───────── ÖNLÜK + PATİLER (uyurken solar) ─────────
    if (awake > 0.02) {
      final bib = Path()
        ..moveTo(o(-16, -35).dx, o(-16, -35).dy)
        ..quadraticBezierTo(o(-22, -10).dx, o(-22, -10).dy, o(0, 8).dx, o(0, 8).dy)
        ..quadraticBezierTo(o(22, -10).dx, o(22, -10).dy, o(16, -35).dx, o(16, -35).dy)
        ..close();
      canvas.drawPath(bib, whiteFur);

      // 6. Yoğurma: sevilirken iki pati sırayla yukarı-aşağı
      final ph = math.sin(f.time * 2 * math.pi * 2.5);
      final kneadL = -5.0 * math.max(0.0, ph) * f.knead;
      final kneadR = -5.0 * math.max(0.0, -ph) * f.knead;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o(-16, 12 + kneadL), width: 18, height: 16),
          const Radius.circular(8),
        ),
        whiteFur,
      );

      // Sağ pati: dinlenme ↔ yüze çıkma (grooming), sürtme titreşimiyle
      final rest = o(16, 12 + kneadR);
      final raised = o(18, -26 + math.sin(f.time * 2 * math.pi * 3) * 2);
      final pawC = _lo(rest, raised, f.groom);
      final pawW = 18 - 2 * f.groom;
      final pawH = 16 + 2 * f.groom;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pawC, width: pawW, height: pawH),
          const Radius.circular(8),
        ),
        whiteFur,
      );
    }

    // Uyurken yüzün önüne kıvrılmış küçük pati (rüyada seğirir)
    if (s > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: o(26 + f.fidget * 1.5, 14 - f.fidget * 3),
            width: 16,
            height: 12,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = Colors.white.withOpacity(s),
      );
    }

    // ───────── KAFA ─────────
    // 5. Yeme: kafa kaseye doğru eğilir, çiğnerken hafif sallanır
    final chewBob = math.sin(f.time * 2 * math.pi * 3) * 2 * f.eat;
    final eatOffset = Offset(16 * f.eat, 20 * f.eat + chewBob);
    final headCenter = catCenter +
        _lo(const Offset(0, -56), const Offset(16, -10), s) +
        eatOffset * awake;
    Offset hc(double x, double y) => headCenter.translate(x, y);

    // Squash dönüşümünü hesaba katarak kafa konumunu yayınla
    f.headPos = Offset(
      pivot.dx + (headCenter.dx - pivot.dx) / f.squash,
      pivot.dy + (headCenter.dy - pivot.dy) * f.squash,
    );

    // Kulaklar: idle seğirme + yatma (dokunma) + uyku seğirmesi
    double twitch(double offset) {
      final p = (f.time + offset) % 7.0;
      return p < 0.3 ? math.sin(p / 0.3 * math.pi * 4) * (1 - p / 0.3) : 0.0;
    }

    final twL = twitch(0) * awake + f.fidget * s;
    final twR = twitch(2.3) * awake - f.fidget * s * 0.6;
    final flat = f.earFlat;

    final tipL = hc(-34 - 8 * flat + twL * 2, -44 + 16 * flat - f.fidget * 2);
    final tipR = hc(34 + 8 * flat + twR * 2, -44 + 16 * flat);
    final earL = Path()
      ..moveTo(hc(-28, -10).dx, hc(-28, -10).dy)
      ..lineTo(tipL.dx, tipL.dy)
      ..lineTo(hc(-10, -24).dx, hc(-10, -24).dy)
      ..close();
    final earR = Path()
      ..moveTo(hc(10, -24).dx, hc(10, -24).dy)
      ..lineTo(tipR.dx, tipR.dy)
      ..lineTo(hc(28, -10).dx, hc(28, -10).dy)
      ..close();
    canvas.drawPath(earL, blackFur);
    canvas.drawPath(earR, blackFur);

    final innerPaint = Paint()..color = const Color(0xFFFFA8B8);
    final inTipL = hc(-30 - 6 * flat + twL * 2, -38 + 12 * flat - f.fidget * 2);
    final inTipR = hc(30 + 6 * flat + twR * 2, -38 + 12 * flat);
    canvas.drawPath(
      Path()
        ..moveTo(hc(-25, -12).dx, hc(-25, -12).dy)
        ..lineTo(inTipL.dx, inTipL.dy)
        ..lineTo(hc(-13, -22).dx, hc(-13, -22).dy)
        ..close(),
      innerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hc(13, -22).dx, hc(13, -22).dy)
        ..lineTo(inTipR.dx, inTipR.dy)
        ..lineTo(hc(25, -12).dx, hc(25, -12).dy)
        ..close(),
      innerPaint,
    );

    canvas.drawCircle(headCenter, 32, blackFur);

    // Beyaz yüz maskesi
    final faceWhite = Path()
      ..moveTo(hc(-14, 8).dx, hc(-14, 8).dy)
      ..quadraticBezierTo(hc(0, -14).dx, hc(0, -14).dy, hc(14, 8).dx, hc(14, 8).dy)
      ..quadraticBezierTo(hc(0, 26).dx, hc(0, 26).dy, hc(-14, 8).dx, hc(-14, 8).dy)
      ..close();
    canvas.drawPath(faceWhite, Paint()..color = Colors.white);

    // Burun
    canvas.drawPath(
      Path()
        ..moveTo(hc(-4, 4).dx, hc(-4, 4).dy)
        ..lineTo(hc(4, 4).dx, hc(4, 4).dy)
        ..lineTo(hc(0, 8).dx, hc(0, 8).dy)
        ..close(),
      Paint()..color = const Color(0xFFFF859E),
    );

    // Ağız: miyav/çiğneme açık, değilse :3
    if (f.mouth > 0.35) {
      canvas.drawOval(
        Rect.fromCenter(
          center: hc(0, 12 + 1 * f.mouth),
          width: 9,
          height: 11 * f.mouth,
        ),
        Paint()..color = const Color(0xFFFF6B88),
      );
    } else {
      final mouthPaint = Paint()
        ..color = _black
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCenter(center: hc(-4, 10), width: 8, height: 6), 0, math.pi, false, mouthPaint);
      canvas.drawArc(Rect.fromCenter(center: hc(4, 10), width: 8, height: 6), 0, math.pi, false, mouthPaint);
    }

    // Bıyıklar
    final whisker = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(hc(-16, 7), hc(-38, 4), whisker);
    canvas.drawLine(hc(-16, 11), hc(-36, 15), whisker);
    canvas.drawLine(hc(16, 7), hc(38, 4), whisker);
    canvas.drawLine(hc(16, 11), hc(36, 15), whisker);

    // ───────── GÖZLER ─────────
    if (f.eyeClose > 0.6) {
      final closed = Paint()
        ..color = Color.lerp(_black, const Color(0xFF4B4D52), s)!
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCenter(center: hc(-13, -3), width: 12, height: 8), math.pi, math.pi, false, closed);
      canvas.drawArc(Rect.fromCenter(center: hc(13, -3), width: 12, height: 8), math.pi, math.pi, false, closed);
    } else {
      final open = 1 - f.eyeClose; // kırparken göz yavaşça kapanır
      final eyeGreen = Paint()..color = const Color(0xFF43B581);
      final pupilPaint = Paint()..color = const Color(0xFF14171A);
      final shine = Paint()..color = Colors.white;

      // 2. Göz takibi: iris ve gözbebeği bakış yönüne kayar
      final irisShift = Offset(f.lookX * 1.2, f.lookY * 1.0);
      final pupilShift = Offset(f.lookX * 2.5, f.lookY * 2.0);

      for (final eyeX in [-13.0, 13.0]) {
        final ec = hc(eyeX, -3);
        canvas.drawOval(
          Rect.fromCenter(center: ec + irisShift, width: 13, height: 15 * open),
          eyeGreen,
        );
        canvas.drawOval(
          Rect.fromCenter(center: ec + pupilShift, width: 8, height: 12 * open),
          pupilPaint,
        );
        if (open > 0.7) {
          canvas.drawCircle(ec + pupilShift + const Offset(-2, -3), 2.5, shine);
          canvas.drawCircle(ec + pupilShift + const Offset(2, 2), 1.2, shine);
        }
      }
    }

    canvas.restore();

    // ───────── YEMEK KABI (belirir + zıplar + parıltı) ─────────
    if (f.eat > 0.02) {
      final e = f.eat.clamp(0.0, 1.0);
      final pop = _ease(e) * (1 + 0.15 * math.sin(math.pi * e));
      final bob = -2 * math.sin(f.time * 2 * math.pi * 3).abs() * e;
      final bowlCenter = center.translate(38, 8 + bob);

      canvas.save();
      canvas.translate(bowlCenter.dx, bowlCenter.dy);
      canvas.scale(pop);
      canvas.translate(-bowlCenter.dx, -bowlCenter.dy);

      canvas.drawArc(
        Rect.fromCenter(center: bowlCenter, width: 28, height: 22),
        0,
        math.pi,
        true,
        Paint()..color = const Color(0xFFFFB347),
      );
      canvas.drawOval(
        Rect.fromCenter(center: bowlCenter.translate(0, -2), width: 16, height: 8),
        Paint()..color = const Color(0xFFFF6961),
      );
      canvas.restore();

      // Kasenin etrafında yanıp sönen parıltılar
      const spots = [Offset(-14, -16), Offset(16, -20), Offset(4, -28)];
      for (var i = 0; i < spots.length; i++) {
        final a = math.max(0.0, math.sin(f.time * 2 * math.pi * 1.5 + i * 2.1)) * e;
        if (a < 0.02) continue;
        _star(
          canvas,
          bowlCenter + spots[i],
          3 + 3 * a,
          Paint()..color = const Color(0xFFFFE08A).withOpacity(a),
        );
      }
    }
  }

  void _paintCushion(Canvas canvas, Offset center, double w) {
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 22), width: w * 0.88, height: 42),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 16), width: w * 0.86, height: 48),
        const Radius.circular(26),
      ),
      Paint()..color = const Color(0xFF7FA8D0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 10), width: w * 0.84, height: 46),
        const Radius.circular(24),
      ),
      Paint()..color = const Color(0xFFA2CAEF),
    );
    final stitch = Paint()
      ..color = const Color(0xFF8BB5DF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center.translate(-w * 0.32, 10), 3, stitch);
    canvas.drawCircle(center.translate(w * 0.32, 10), 3, stitch);
    canvas.drawCircle(center.translate(0, 18), 3, stitch);
  }

  // Tüm hareket _CatFrame üzerinden repaint ile tetiklenir.
  @override
  bool shouldRepaint(covariant _TuxedoCatPainter oldDelegate) => false;
}
