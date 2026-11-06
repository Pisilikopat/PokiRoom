// lib/features/canvas/models/drawing_stroke.dart
import 'dart:ui';
import 'package:flutter/material.dart';

enum DrawingTool {
  pen, // İnce tükenmez / kurşun kalem
  brush, // Yumuşak fırça / suluboya
  highlighter, // Yarı saydam fosforlu kalem
  pawStamp, // Pati damgası 🐾
  heartStamp, // Kalp damgası 💖
  eraser, // Silgi (Klasik alan/piksel silgisi)
  strokeEraser, // Çizgi Silgisi (Dokunulan çizgiyi tamamen siler)
  hand, // El / Kaydır (Ekranda gezinme / pan aracı)
}

extension DrawingToolExt on DrawingTool {
  bool get isEraser => this == DrawingTool.eraser;
  bool get isStrokeEraser => this == DrawingTool.strokeEraser;
  bool get isHand => this == DrawingTool.hand;
  bool get isAnyEraser => isEraser || isStrokeEraser;

  String get label {
    switch (this) {
      case DrawingTool.pen:
        return 'Kalem';
      case DrawingTool.brush:
        return 'Fırça';
      case DrawingTool.highlighter:
        return 'Fosforlu';
      case DrawingTool.pawStamp:
        return 'Pati İzi';
      case DrawingTool.heartStamp:
        return 'Kalp';
      case DrawingTool.eraser:
        return 'Alan Silgi';
      case DrawingTool.strokeEraser:
        return 'Çizgi Sil';
      case DrawingTool.hand:
        return 'Kaydır';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingTool.pen:
        return Icons.edit_rounded;
      case DrawingTool.brush:
        return Icons.brush_rounded;
      case DrawingTool.highlighter:
        return Icons.format_paint_rounded;
      case DrawingTool.pawStamp:
        return Icons.pets_rounded;
      case DrawingTool.heartStamp:
        return Icons.favorite_rounded;
      case DrawingTool.eraser:
        return Icons.auto_fix_normal_rounded;
      case DrawingTool.strokeEraser:
        return Icons.delete_sweep_rounded;
      case DrawingTool.hand:
        return Icons.pan_tool_rounded;
    }
  }
}

class DrawingPoint {
  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  final double x;
  final double y;
  final double pressure;

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toMap() => {
        'x': double.parse(x.toStringAsFixed(1)),
        'y': double.parse(y.toStringAsFixed(1)),
        'p': double.parse(pressure.toStringAsFixed(2)),
      };

  factory DrawingPoint.fromMap(Map<String, dynamic> map) => DrawingPoint(
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        pressure: (map['p'] as num?)?.toDouble() ?? 1.0,
      );
}

class DrawingStroke {
  DrawingStroke({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    List<DrawingPoint>? points,
  }) : points = points ?? [];

  final String id;
  final String authorId;
  final String authorNickname;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final List<DrawingPoint> points;

  bool get isEraser => tool == DrawingTool.eraser;

  DrawingStroke copyWith({
    List<DrawingPoint>? points,
  }) {
    return DrawingStroke(
      id: id,
      authorId: authorId,
      authorNickname: authorNickname,
      tool: tool,
      color: color,
      strokeWidth: strokeWidth,
      opacity: opacity,
      points: points ?? List.from(this.points),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorNickname': authorNickname,
        'tool': tool.name,
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'opacity': opacity,
        'points': points.map((p) => p.toMap()).toList(),
      };

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    final toolStr = map['tool'] as String? ?? 'brush';
    final tool = DrawingTool.values.firstWhere(
      (t) => t.name == toolStr,
      orElse: () => DrawingTool.brush,
    );

    final pointsList = (map['points'] as List?) ?? [];
    final points = pointsList
        .map((p) => DrawingPoint.fromMap((p as Map).cast<String, dynamic>()))
        .toList();

    final colorVal = (map['color'] as num?)?.toInt() ?? 0xFF4A403A;

    return DrawingStroke(
      id: map['id'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorNickname: map['authorNickname'] as String? ?? 'Partner',
      tool: tool,
      color: Color(colorVal),
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 4.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      points: points,
    );
  }
}
