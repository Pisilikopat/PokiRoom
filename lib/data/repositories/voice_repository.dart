import 'package:flutter/foundation.dart';
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
    final ext = kIsWeb ? 'webm' : 'm4a';
    final mime = kIsWeb ? 'audio/webm' : 'audio/m4a';
    final path = '$roomId/$id.$ext';
    final base64Audio = base64Encode(bytes);

    String? storageUrl;

    try {
      await _db.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mime,
              upsert: true,
            ),
          );
      storageUrl = _db.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      storageUrl = null;
    }

    final finalUrl = (storageUrl != null && storageUrl.isNotEmpty)
        ? storageUrl
        : 'data:$mime;base64,$base64Audio';

    return PokiVoiceData(
      url: finalUrl,
      durationMs: durationMs,
      waveform: waveform,
      bytesBase64: base64Audio,
    );
  }
}
