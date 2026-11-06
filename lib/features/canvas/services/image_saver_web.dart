// lib/features/canvas/services/image_saver_web.dart
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('pokiDownloadBytes')
external void _pokiDownloadBytes(JSString base64Data, JSString filename);

Future<void> saveImage(Uint8List bytes, String fileName) async {
  final base64Str = base64Encode(bytes);
  _pokiDownloadBytes(base64Str.toJS, fileName.toJS);
}
