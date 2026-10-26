// lib/data/models/doodle_stroke.dart
import 'dart:ui';

double _r(double v) => (v * 10000).roundToDouble() / 10000;

/// Tek bir çizgi. Tüm koordinatlar ve kalınlık tuvale göre NORMALİZE (0..1) tutulur;
/// böylece farklı ekran boyutlarında aynı çizim görünür.
class DoodleStroke {
  DoodleStroke({
    required this.id,
    required this.color,
    required this.width,
    required this.ownerId,
    List<Offset>? points,
  }) : points = points ?? <Offset>[];

  final String id;

  /// ARGB int
  final int color;

  /// Tuval genişliğinin oranı (örn. 0.012)
  final double width;
  final String ownerId;
  final List<Offset> points;

  Map<String, dynamic> toMap() => {
        'id': id,
        'c': color,
        'w': _r(width),
        'o': ownerId,
        'p': [
          for (final p in points) ...[_r(p.dx), _r(p.dy)],
        ],
      };

  factory DoodleStroke.fromMap(Map<String, dynamic> m) {
    final flat = (m['p'] as List).map((e) => (e as num).toDouble()).toList();
    return DoodleStroke(
      id: m['id'] as String,
      color: (m['c'] as num).toInt(),
      width: (m['w'] as num).toDouble(),
      ownerId: (m['o'] as String?) ?? '',
      points: [
        for (var i = 0; i + 1 < flat.length; i += 2) Offset(flat[i], flat[i + 1]),
      ],
    );
  }
}
