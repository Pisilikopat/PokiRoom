// lib/features/canvas/services/image_saver.dart
import 'dart:typed_data';

import 'image_saver_stub.dart'
    if (dart.library.js_interop) 'image_saver_web.dart' as saver;

class CanvasImageSaver {
  CanvasImageSaver._();

  static Future<void> save(Uint8List bytes, String fileName) async {
    await saver.saveImage(bytes, fileName);
  }
}
