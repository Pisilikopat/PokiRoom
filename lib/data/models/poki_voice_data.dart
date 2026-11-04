// lib/data/models/poki_voice_data.dart
import 'dart:convert';
import 'dart:typed_data';

/// Sesli mesajın teknik içeriği: URL, süre, dalga boyu verisi ve isteğe bağlı gömülü baytlar.
class PokiVoiceData {
  const PokiVoiceData({
    required this.url,
    required this.durationMs,
    this.waveform = const [],
    this.bytesBase64,
  });

  final String url;
  final int durationMs;
  final List<int> waveform;
  final String? bytesBase64;

  Duration get duration => Duration(milliseconds: durationMs);

  String get formattedDuration {
    final s = (durationMs ~/ 1000);
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  Uint8List? get bytes {
    if (bytesBase64 == null || bytesBase64!.isEmpty) return null;
    try {
      return base64Decode(bytesBase64!);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'durationMs': durationMs,
        'waveform': waveform,
        if (bytesBase64 != null) 'bytesBase64': bytesBase64,
      };

  String toJson() => jsonEncode(toMap());

  factory PokiVoiceData.fromMap(Map<String, dynamic> map) {
    final waveRaw = map['waveform'] as List<dynamic>? ?? [];
    final waveform = waveRaw.map((e) => (e as num).toInt()).toList();

    return PokiVoiceData(
      url: (map['url'] as String?) ?? '',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      waveform: waveform,
      bytesBase64: map['bytesBase64'] as String?,
    );
  }

  factory PokiVoiceData.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PokiVoiceData.fromMap(map);
  }
}
