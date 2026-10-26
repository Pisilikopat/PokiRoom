// lib/features/workshop/doodle_controller.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../core/theme/poki_theme.dart';
import '../../core/utils/uuid.dart';
import '../../data/models/doodle_stroke.dart';

/// Poki pastel fırça renkleri.
class DoodlePalette {
  DoodlePalette._();

  static const List<Color> colors = [
    PokiColors.text, // kakao kahvesi
    PokiColors.primary, // Poki Pink
    PokiColors.primaryButton,
    PokiColors.lampOn,
    Color(0xFFB5E48C), // nane
    Color(0xFFA2D2FF), // gökyüzü
    Color(0xFFCDB4DB), // lavanta
    Color(0xFFFFAFCC), // gül
  ];
}

/// Hem Atölye hem Canlı Doodle tuvali için ortak çizim durumu.
/// Koordinatlar ve kalınlık normalize (0..1) tutulur.
class DoodleController extends ChangeNotifier {
  DoodleController({required this.ownerId});

  static const double minWidth = 0.006;
  static const double maxWidth = 0.06;

  final String ownerId;
  final List<DoodleStroke> strokes = [];

  Color color = DoodlePalette.colors[1];
  double width = 0.014;

  DoodleStroke? _active;

  // Canlı senkronizasyon kancaları
  void Function(DoodleStroke stroke)? onStrokeStart;
  void Function(DoodleStroke stroke, List<Offset> added)? onStrokePoints;
  void Function(DoodleStroke stroke)? onStrokeEnd;
  void Function(String strokeId)? onUndo;
  VoidCallback? onClear;

  bool get isEmpty => strokes.isEmpty;
  bool get canUndo => strokes.any((s) => s.ownerId == ownerId);

  void setColor(Color c) {
    color = c;
    notifyListeners();
  }

  void setWidth(double w) {
    width = w.clamp(minWidth, maxWidth).toDouble();
    notifyListeners();
  }

  // --------------------------------------------------------- yerel çizim

  void beginStroke(Offset p) {
    final stroke = DoodleStroke(
      id: generateUuidV4(),
      color: color.toARGB32(),
      width: width,
      ownerId: ownerId,
      points: [p],
    );
    _active = stroke;
    strokes.add(stroke);
    onStrokeStart?.call(stroke);
    notifyListeners();
  }

  void extendStroke(Offset p) {
    final a = _active;
    if (a == null) return;
    if ((a.points.last - p).distance < 0.0025) return;
    a.points.add(p);
    onStrokePoints?.call(a, [p]);
    notifyListeners();
  }

  void endStroke() {
    final a = _active;
    if (a == null) return;
    _active = null;
    onStrokeEnd?.call(a);
    notifyListeners();
  }

  /// Sadece kendi son çizgini geri alır.
  void undo() {
    final i = strokes.lastIndexWhere((s) => s.ownerId == ownerId);
    if (i < 0) return;
    final s = strokes.removeAt(i);
    onUndo?.call(s.id);
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    _active = null;
    onClear?.call();
    notifyListeners();
  }

  // ------------------------------------------------------- uzaktan gelen

  DoodleStroke? _byId(String id) {
    for (final s in strokes) {
      if (s.id == id) return s;
    }
    return null;
  }

  void remoteStart(DoodleStroke s) {
    if (_byId(s.id) != null) return;
    strokes.add(s);
    notifyListeners();
  }

  void remoteAppend(String id, List<Offset> pts) {
    final s = _byId(id);
    if (s == null) return;
    s.points.addAll(pts);
    notifyListeners();
  }

  void removeStroke(String id) {
    strokes.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void remoteClear() {
    strokes.clear();
    _active = null;
    notifyListeners();
  }

  /// Geç katılan taraf için tam durum eşitleme (id'ye göre birleştirir).
  void mergeStrokes(Iterable<DoodleStroke> incoming) {
    var changed = false;
    for (final s in incoming) {
      if (_byId(s.id) == null) {
        strokes.add(s);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Çizimin normalize sınırları (çıkartmayı kırpmak için). Boşsa null.
  Rect? get contentBounds {
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    var pad = 0.0;
    for (final s in strokes) {
      pad = math.max(pad, s.width / 2);
      for (final p in s.points) {
        l = math.min(l, p.dx);
        t = math.min(t, p.dy);
        r = math.max(r, p.dx);
        b = math.max(b, p.dy);
      }
    }
    if (l == double.infinity) return null;
    final inflate = pad + 0.02;
    return Rect.fromLTRB(
      (l - inflate).clamp(0.0, 1.0).toDouble(),
      (t - inflate).clamp(0.0, 1.0).toDouble(),
      (r + inflate).clamp(0.0, 1.0).toDouble(),
      (b + inflate).clamp(0.0, 1.0).toDouble(),
    );
  }
}
