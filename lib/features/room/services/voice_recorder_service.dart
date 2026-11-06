// lib/features/room/services/voice_recorder_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  final double amplitude;

  bool get isRecording =>
      status == RecorderStatus.recording || status == RecorderStatus.locked;
  bool get isLocked => status == RecorderStatus.locked;

  String get formattedDuration {
    final s = durationMs ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  static const VoiceRecorderState idle = VoiceRecorderState(
    status: RecorderStatus.idle,
    durationMs: 0,
    amplitude: 0.0,
  );
}

class VoiceRecorderService {
  VoiceRecorderService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final ValueNotifier<VoiceRecorderState> state =
      ValueNotifier<VoiceRecorderState>(VoiceRecorderState.idle);

  Timer? _timer;
  final BytesBuilder _bytesBuilder = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _streamSub;
  final List<double> _rawAmplitudes = [];
  DateTime? _startTime;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('[VoiceRecorder] hasPermission error: $e');
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

    final config = RecordConfig(
      encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 64000,
    );

    try {
      if (kIsWeb) {
        // Web uses MediaRecorder writing to in-memory blob URL
        await _recorder.start(config, path: '');
      } else {
        // Native mobile streams bytes directly
        final stream = await _recorder.startStream(config);
        _streamSub = stream.listen((chunk) {
          _bytesBuilder.add(chunk);
        });
      }

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
      debugPrint('[VoiceRecorder] start error: $e');
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

    final duration =
        DateTime.now().difference(_startTime ?? DateTime.now()).inMilliseconds;

    String? recordPath;
    try {
      recordPath = await _recorder.stop();
    } catch (e) {
      debugPrint('[VoiceRecorder] stop error: $e');
    }

    await _streamSub?.cancel();
    _streamSub = null;
    _timer?.cancel();
    _timer = null;

    state.value = VoiceRecorderState.idle;

    if (duration < 600) {
      // Çok kısa (< 0.6 sn) kayıtlar iptal edilir
      return null;
    }

    Uint8List bytes;
    if (kIsWeb) {
      if (recordPath == null || recordPath.isEmpty) return null;
      try {
        final res = await http.get(Uri.parse(recordPath));
        bytes = res.bodyBytes;
      } catch (e) {
        debugPrint('[VoiceRecorder] web fetch blob error: $e');
        return null;
      }
    } else {
      bytes = _bytesBuilder.toBytes();
    }

    if (bytes.isEmpty) {
      return null;
    }

    final waveform = _generateWaveform(_rawAmplitudes, targetBars: 24);

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

  List<int> _generateWaveform(List<double> samples, {int targetBars = 24}) {
    if (samples.isEmpty) {
      return List<int>.filled(targetBars, 12);
    }

    if (samples.length <= targetBars) {
      return samples
          .map((v) => (v * 100).round().clamp(6, 100))
          .toList()
        ..addAll(List<int>.filled(
            targetBars - samples.length,
            (samples.last * 100).round().clamp(6, 100)));
    }

    final result = <int>[];
    final chunkSize = samples.length / targetBars;

    for (var i = 0; i < targetBars; i++) {
      final start = (i * chunkSize).floor();
      final end = math.min(((i + 1) * chunkSize).ceil(), samples.length);
      if (start >= end) {
        result.add(12);
        continue;
      }

      var maxAmp = 0.0;
      for (var j = start; j < end; j++) {
        if (samples[j] > maxAmp) maxAmp = samples[j];
      }

      final scaled = (maxAmp * 100).round().clamp(6, 100);
      result.add(scaled);
    }

    return result;
  }

  void dispose() {
    _cleanup();
    _recorder.dispose();
    state.dispose();
  }
}
