// lib/data/repositories/voice_repository.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/uuid.dart';
import '../models/poki_voice_data.dart';

/// Ses dosyalarını Supabase Storage'a yükler veya veri URI'si olarak hazırlar.
class VoiceRepository {
  VoiceRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;
  static const String _bucket = 'voice_messages';

  /// Ses baytlarını yükler; depolama yoksa veya başarısız olursa base64 veri URI ile döner.
  Future<PokiVoiceData> prepareVoiceData({
    required String roomId,
    required Uint8List bytes,
    required int durationMs,
    required List<int> waveform,
  }) async {
    final id = generateUuidV4();
    final path = '$roomId/$id.m4a';
    final base64Audio = base64Encode(bytes);

    String? storageUrl;

    try {
      await _db.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/m4a',
              upsert: true,
            ),
          );
      storageUrl = _db.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      // Storage bucket henüz oluşturulmamışsa veya izin yoksa
      // base64 data URI kullanarak mesajın kaybolmamasını garanti eder.
      storageUrl = null;
    }

    final finalUrl = (storageUrl != null && storageUrl.isNotEmpty)
        ? storageUrl
        : 'data:audio/m4a;base64,$base64Audio';

    return PokiVoiceData(
      url: finalUrl,
      durationMs: durationMs,
      waveform: waveform,
      bytesBase64: base64Audio,
    );
  }
}
