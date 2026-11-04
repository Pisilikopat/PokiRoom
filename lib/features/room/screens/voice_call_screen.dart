// lib/features/room/screens/voice_call_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';
import '../services/call_signaling_service.dart';

/// Aktif sesli arama ekranı.
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.partner,
    required this.signaling,
    required this.isCaller,
  });

  final PokiUser partner;
  final CallSignalingService signaling;
  final bool isCaller;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    widget.signaling.addListener(_onSignalingChanged);
  }

  @override
  void dispose() {
    _pulse.dispose();
    widget.signaling.removeListener(_onSignalingChanged);
    super.dispose();
  }

  void _onSignalingChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.signaling.state == CallState.idle) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    switch (widget.signaling.state) {
      case CallState.calling:
        return 'Aranıyor... 🐾';
      case CallState.ringing:
        return 'Geliyor... 📞';
      case CallState.connecting:
        return 'Bağlanıyor... ✨';
      case CallState.active:
        return '🐾 ${_formatDuration(widget.signaling.callDuration)}';
      case CallState.idle:
        return 'Arama bitti';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.signaling.state == CallState.active;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF2C2522),
                    const Color(0xFF1D1917),
                    const Color(0xFF2C2522),
                  ]
                : [
                    const Color(0xFFFFECE8),
                    const Color(0xFFFFF5F0),
                    const Color(0xFFE8F4E8),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Üst bar — minimize butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      color: PokiColors.textOf(context).withOpacity(0.6),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Sesli Arama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PokiColors.textOf(context),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Spacer(),
              // Avatar + nabız halkaları
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final v = _pulse.value;
                  final scale = isActive ? (1.0 + sin(v * pi) * 0.08) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isActive) ...[
                      _buildRing(130, 0.12, isDark),
                      _buildRing(110, 0.18, isDark),
                    ],
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? PokiColors.darkSurface : PokiColors.surface,
                        border: Border.all(
                          color: isActive ? PokiColors.primary : PokiColors.primary.withOpacity(0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PokiColors.primary.withOpacity(0.3),
                            blurRadius: isActive ? 24 : 12,
                            spreadRadius: isActive ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.partner.moodEmoji ?? '🐱',
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // İsim
              Text(
                widget.partner.nickname,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: PokiColors.textOf(context),
                ),
              ),
              const SizedBox(height: 10),
              // Durum / süre
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 16,
                  color: PokiColors.textOf(context).withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Kontrol butonları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: widget.signaling.isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: widget.signaling.isMuted ? 'Sessiz' : 'Mikrofon',
                      active: !widget.signaling.isMuted,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.signaling.toggleMute();
                      },
                    ),
                    // Aramayı bitir
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        widget.signaling.endCall();
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F5F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66FF5F5F),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                    _ControlButton(
                      icon: widget.signaling.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      label: widget.signaling.isSpeakerOn ? 'Hoparlör' : 'Kulak',
                      active: widget.signaling.isSpeakerOn,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.signaling.toggleSpeaker();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(double radius, double opacity, bool isDark) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PokiColors.primary.withOpacity(opacity),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? PokiColors.darkSurface : PokiColors.surface)
                  : PokiColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? PokiColors.primary.withOpacity(0.4) : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              color: active
                  ? PokiColors.textOf(context)
                  : PokiColors.textOf(context).withOpacity(0.4),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: PokiColors.textOf(context).withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
