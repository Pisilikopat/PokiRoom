// lib/features/room/widgets/voice_message_bubble.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_voice_data.dart';

/// Sohbet ekranında sesli mesajları oynatan, interaktif dalga formu ve hız kontrolü
/// içeren sevimli Poki temalı ses baloncuğu bileşeni.
class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.voice,
    required this.isMine,
    required this.meta,
  });

  final PokiVoiceData voice;
  final bool isMine;
  final Widget meta;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  double _speed = 1.0;
  bool _isSeeking = false;

  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted && !_isSeeking) {
        setState(() => _position = pos);
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    HapticFeedback.selectionClick();

    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_playerState == PlayerState.completed || _position >= widget.voice.duration) {
        await _player.seek(Duration.zero);
      }
      await _player.setPlaybackRate(_speed);
      await _player.play(UrlSource(widget.voice.url));
    }
  }

  void _cycleSpeed() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
    });
    if (_isPlaying) {
      _player.setPlaybackRate(_speed);
    }
  }

  void _seekToProgress(double progress) {
    final targetMs = (widget.voice.durationMs * progress).toInt();
    final target = Duration(milliseconds: targetMs);
    setState(() => _position = target);
    _player.seek(target);
  }

  String _formatTime(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalMs = widget.voice.durationMs <= 0 ? 1 : widget.voice.durationMs;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs);
    final progress = currentMs / totalMs;

    final bars = widget.voice.waveform.isEmpty
        ? List.generate(24, (i) => 25 + (i % 4) * 18)
        : widget.voice.waveform;

    final activeColor = PokiColors.primaryButton;
    final inactiveColor = PokiColors.textOf(context).withOpacity(0.22);

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Oynat / Duraklat Butonu
              Material(
                color: activeColor,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _togglePlay,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. İnteraktif Ses Dalgası (Dokunup Sarılabilir)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => _isSeeking = true,
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final localX = details.localPosition.dx;
                    final width = box.size.width - 90;
                    if (width > 0) {
                      final p = (localX / width).clamp(0.0, 1.0);
                      _seekToProgress(p);
                    }
                  },
                  onHorizontalDragEnd: (_) => _isSeeking = false,
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final localX = details.localPosition.dx;
                    final width = box.size.width - 90;
                    if (width > 0) {
                      final p = (localX / width).clamp(0.0, 1.0);
                      _seekToProgress(p);
                    }
                  },
                  child: SizedBox(
                    height: 38,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < bars.length; i++) ...[
                          _WaveformBar(
                            heightFraction: (bars[i] / 100).clamp(0.18, 1.0),
                            isActive: (i / bars.length) <= progress,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                          ),
                          if (i < bars.length - 1) const SizedBox(width: 2.2),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Hız Değiştirme Butonu (1.0x / 1.5x / 2.0x)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _cycleSpeed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: PokiColors.textOf(context).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_speed == 1.0 ? '1' : _speed.toString()}x',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: PokiColors.textOf(context).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Alt Çubuk: Süre & Meta (Saat, Okundu)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPlaying
                    ? '${_formatTime(_position)} / ${widget.voice.formattedDuration}'
                    : widget.voice.formattedDuration,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: PokiColors.textOf(context).withOpacity(0.65),
                ),
              ),
              widget.meta,
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({
    required this.heightFraction,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double heightFraction;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 3.2,
      height: 34 * heightFraction,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
