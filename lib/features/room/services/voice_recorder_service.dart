// lib/features/room/services/voice_recorder_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class VoiceRecordResult {
  const VoiceRecordResult({
    required this.bytes,
    required this.durationMs,
    required this.waveform,
  });

  final Uint8List bytes;
  final int durationMs;
  final List<int> waveform;
}

enum RecorderStatus { idle, recording, locked, stopped }

class VoiceRecorderState {
  const VoiceRecorderState({
    required this.status,
    required this.durationMs,
    required this.amplitude,
  });

  final RecorderStatus status;
  final int durationMs;
  final double amplitude; // 0.0 - 1.0

  bool get isRecording =>
      status == RecorderStatus.recording || status == RecorderStatus.locked;
  bool get isLocked => status == RecorderStatus.locked;

  String get formattedDuration {
    final s = durationMs ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  static const idle = VoiceRecorderState(
    status: RecorderStatus.idle,
    durationMs: 0,
    amplitude: 0.0,
  );
}

/// Ses kaydı alma, mikrofon izin kontrolü, ses dalgası örnekleme ve bayt toplama servisi.
class VoiceRecorderService {
  VoiceRecorderService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  final ValueNotifier<VoiceRecorderState> state =
      ValueNotifier(VoiceRecorderState.idle);

  Timer? _timer;
  final BytesBuilder _bytesBuilder = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _streamSub;
  final List<double> _rawAmplitudes = [];
  DateTime? _startTime;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> startRecording() async {
    final permitted = await hasPermission();
    if (!permitted) return false;

    await _cleanup();

    _bytesBuilder.clear();
    _rawAmplitudes.clear();
    _startTime = DateTime.now();

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 64000,
    );

    try {
      final stream = await _recorder.startStream(config);
      _streamSub = stream.listen((chunk) {
        _bytesBuilder.add(chunk);
      });

      state.value = const VoiceRecorderState(
        status: RecorderStatus.recording,
        durationMs: 0,
        amplitude: 0.1,
      );

      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (!state.value.isRecording) return;

        final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
        var ampNormalized = 0.15;

        try {
          final amp = await _recorder.getAmplitude();
          // amp.current is usually between -60 dB (quiet) and 0 dB (loud)
          final currentDb = amp.current;
          if (currentDb > -60) {
            ampNormalized = ((currentDb + 60) / 60).clamp(0.05, 1.0);
          }
        } catch (_) {}

        _rawAmplitudes.add(ampNormalized);

        state.value = VoiceRecorderState(
          status: state.value.status,
          durationMs: elapsed,
          amplitude: ampNormalized,
        );
      });

      return true;
    } catch (e) {
      await _cleanup();
      state.value = VoiceRecorderState.idle;
      return false;
    }
  }

  void lockRecording() {
    if (state.value.status == RecorderStatus.recording) {
      state.value = VoiceRecorderState(
        status: RecorderStatus.locked,
        durationMs: state.value.durationMs,
        amplitude: state.value.amplitude,
      );
    }
  }

  Future<VoiceRecordResult?> stopRecording() async {
    if (!state.value.isRecording) return null;

    final duration = DateTime.now().difference(_startTime ?? DateTime.now()).inMilliseconds;

    try {
      await _recorder.stop();
    } catch (_) {}

    await _streamSub?.cancel();
    _streamSub = null;
    _timer?.cancel();
    _timer = null;

    final bytes = _bytesBuilder.toBytes();
    final waveform = _generateWaveform(_rawAmplitudes, targetBars: 24);

    state.value = VoiceRecorderState.idle;

    if (duration < 600 || bytes.isEmpty) {
      // Çok kısa (< 0.6 sn) kayıtlar iptal edilir
      return null;
    }

    return VoiceRecordResult(
      bytes: bytes,
      durationMs: duration,
      waveform: waveform,
    );
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    await _cleanup();
    state.value = VoiceRecorderState.idle;
  }

  Future<void> _cleanup() async {
    _timer?.cancel();
    _timer = null;
    await _streamSub?.cancel();
    _streamSub = null;
    _bytesBuilder.clear();
    _rawAmplitudes.clear();
  }

  /// Toplanan desibel örneklerini 0..100 arasında 24 adet görsel çubuğa normalize eder.
  List<int> _generateWaveform(List<double> samples, {int targetBars = 24}) {
    if (samples.isEmpty) {
      return List.filled(targetBars, 30);
    }

    final result = <int>[];
    final chunkSize = samples.length / targetBars;

    for (var i = 0; i < targetBars; i++) {
      final start = (i * chunkSize).floor();
      final end = math.min(((i + 1) * chunkSize).ceil(), samples.length);
      if (start >= end) {
        result.add(25);
        continue;
      }

      var maxAmp = 0.0;
      for (var j = start; j < end; j++) {
        if (samples[j] > maxAmp) maxAmp = samples[j];
      }

      // 15 - 95 arasında tatlı bir yükseklik değeri
      final val = (maxAmp * 85 + 15).clamp(15.0, 98.0).toInt();
      result.add(val);
    }

    return result;
  }

  void dispose() {
    _cleanup();
    _recorder.dispose();
  }
}
