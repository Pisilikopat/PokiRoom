// lib/features/workshop/sticker_exporter.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'doodle_controller.dart';

typedef ExportedSticker = ({Uint8List bytes, int width, int height});

/// RepaintBoundary'yi şeffaf arka planlı PNG baytlarına çevirir ve çizime göre kırpar.
/// dart:io kullanmaz; web + mobil uyumludur.
class StickerExporter {
  StickerExporter._();

  static const double _pixelRatio = 3;

  static Future<ExportedSticker?> capture(
    GlobalKey boundaryKey,
    DoodleController controller,
  ) async {
    final bounds = controller.contentBounds;
    if (bounds == null) return null;

    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final ui.Image full = await boundary.toImage(pixelRatio: _pixelRatio);
    try {
      final src = ui.Rect.fromLTRB(
        bounds.left * full.width,
        bounds.top * full.height,
        bounds.right * full.width,
        bounds.bottom * full.height,
      );
      final w = src.width.round().clamp(1, full.width).toInt();
      final h = src.height.round().clamp(1, full.height).toInt();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        full,
        src,
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(w, h);
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      picture.dispose();
      if (data == null) return null;
      return (bytes: data.buffer.asUint8List(), width: w, height: h);
    } finally {
      full.dispose();
    }
  }
}
