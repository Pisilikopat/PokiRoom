// lib/features/canvas/logic/canvas_controller.dart
import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';

class PartnerCursor {
  const PartnerCursor({
    required this.position,
    required this.nickname,
    required this.color,
  });

  final Offset position;
  final String nickname;
  final Color color;
}

class CanvasController extends ChangeNotifier {
  CanvasController({
    required this.myId,
    required this.myNickname,
    this.isCoop = false,
  });

  final String myId;
  final String myNickname;
  final bool isCoop;

  // Çizilmiş ve tamamlanmış çizgiler
  final List<DrawingStroke> _strokes = [];
  // Geri / İleri alma yığını
  final List<DrawingStroke> _redoStack = [];

  // Kullanıcının şu an çizmekte olduğu aktif çizgi
  DrawingStroke? _currentStroke;
  // Partnerin çizmekte olduğu aktif çizgiler: partnerId -> DrawingStroke
  final Map<String, DrawingStroke> _partnerActiveStrokes = {};
  // Partnerin canlı imleci
  PartnerCursor? _partnerCursor;

  // Seçili araç ve fırça ayarları
  DrawingTool selectedTool = DrawingTool.pen;
  Color selectedColor = const Color(0xFFE88A9A); // Poki Pembesi
  double strokeWidth = 4.0;
  double opacity = 1.0;

  // Zoom & Pan Dönüşüm Kontrolcüsü
  final TransformationController transformController = TransformationController();

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  DrawingStroke? get currentStroke => _currentStroke;
  Map<String, DrawingStroke> get partnerActiveStrokes => _partnerActiveStrokes;
  PartnerCursor? get partnerCursor => _partnerCursor;

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Ekran piksel koordinatını (Screen), tuvalin dünya koordinatına (World) çevirir.
  /// Bu sayede kullanıcı ne kadar zoom yaparsa yapsın fırça kalınlığı ve çizim
  /// her zaman tam yerinde ve doğru orantıda çizilir.
  Offset toWorld(Offset screenPoint) {
    final matrix = transformController.value;
    final inv = Matrix4.tryInvert(matrix);
    if (inv == null) return screenPoint;
    return MatrixUtils.transformPoint(inv, screenPoint);
  }

  void startStroke(Offset worldPoint) {
    _redoStack.clear();
    final strokeId = '${myId}_${DateTime.now().microsecondsSinceEpoch}';
    _currentStroke = DrawingStroke(
      id: strokeId,
      authorId: myId,
      authorNickname: myNickname,
      tool: selectedTool,
      color: selectedColor,
      strokeWidth: strokeWidth,
      opacity: opacity,
      points: [DrawingPoint(x: worldPoint.dx, y: worldPoint.dy)],
    );
    notifyListeners();
  }

  void appendPoint(Offset worldPoint) {
    if (_currentStroke == null) return;
    final lastPoint = _currentStroke!.points.last;
    final dx = worldPoint.dx - lastPoint.x;
    final dy = worldPoint.dy - lastPoint.y;
    // Çok minik titremeleri filtrele (dünya koordinatında > 1.2 piksel)
    if (dx * dx + dy * dy < 1.44) return;

    _currentStroke!.points.add(DrawingPoint(x: worldPoint.dx, y: worldPoint.dy));
    notifyListeners();
  }

  DrawingStroke? endStroke() {
    if (_currentStroke == null) return null;
    final finished = _currentStroke!;
    _strokes.add(finished);
    _currentStroke = null;
    notifyListeners();
    return finished;
  }

  void cancelCurrentStroke() {
    if (_currentStroke != null) {
      _currentStroke = null;
      notifyListeners();
    }
  }

  DrawingStroke? undo() {
    if (_strokes.isEmpty) return null;
    // Ortak modda kullanıcının kendi son çizgisini veya solo modda en son çizgiyi geri alır
    final lastIndex = _strokes.lastIndexWhere((s) => !isCoop || s.authorId == myId);
    if (lastIndex == -1) return null;
    final removed = _strokes.removeAt(lastIndex);
    _redoStack.add(removed);
    notifyListeners();
    return removed;
  }

  DrawingStroke? redo() {
    if (_redoStack.isEmpty) return null;
    final restored = _redoStack.removeLast();
    _strokes.add(restored);
    notifyListeners();
    return restored;
  }

  void clearCanvas() {
    if (_strokes.isEmpty) return;
    _redoStack.clear();
    _strokes.clear();
    notifyListeners();
  }

  void resetZoom() {
    transformController.value = Matrix4.identity();
    notifyListeners();
  }

  // --- Partner Eşitleme Metotları (Co-op) ---

  void onPartnerStrokeStart(DrawingStroke stroke) {
    _partnerActiveStrokes[stroke.authorId] = stroke;
    notifyListeners();
  }

  void onPartnerStrokeChunk(String strokeId, List<DrawingPoint> newPoints) {
    for (final entry in _partnerActiveStrokes.entries) {
      if (entry.value.id == strokeId) {
        entry.value.points.addAll(newPoints);
        notifyListeners();
        break;
      }
    }
  }

  void onPartnerStrokeEnd(DrawingStroke stroke) {
    _partnerActiveStrokes.remove(stroke.authorId);
    // Eski referans varsa güncelle, yoksa ekle
    final existingIdx = _strokes.indexWhere((s) => s.id == stroke.id);
    if (existingIdx >= 0) {
      _strokes[existingIdx] = stroke;
    } else {
      _strokes.add(stroke);
    }
    notifyListeners();
  }

  void onPartnerUndo(String strokeId) {
    _strokes.removeWhere((s) => s.id == strokeId);
    notifyListeners();
  }

  void onPartnerClear() {
    _strokes.clear();
    _partnerActiveStrokes.clear();
    notifyListeners();
  }

  void onPartnerCursor(Offset worldPosition, String nickname, Color color) {
    _partnerCursor = PartnerCursor(
      position: worldPosition,
      nickname: nickname,
      color: color,
    );
    notifyListeners();
  }

  void clearPartnerCursor() {
    if (_partnerCursor != null) {
      _partnerCursor = null;
      notifyListeners();
    }
  }

  void loadInitialStrokes(List<DrawingStroke> loadedStrokes) {
    _strokes.clear();
    _strokes.addAll(loadedStrokes);
    notifyListeners();
  }
}
