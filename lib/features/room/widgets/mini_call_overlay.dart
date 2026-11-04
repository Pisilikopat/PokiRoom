// lib/features/room/widgets/mini_call_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_user.dart';
import '../screens/voice_call_screen.dart';
import '../services/call_signaling_service.dart';

/// Chat ekranında arkaplan araması varken görünen küçük çubuk.
class MiniCallOverlay extends StatelessWidget {
  const MiniCallOverlay({
    super.key,
    required this.partner,
    required this.signaling,
  });

  final PokiUser partner;
  final CallSignalingService signaling;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: signaling,
      builder: (context, _) {
        final active = signaling.state == CallState.active ||
            signaling.state == CallState.connecting;
        if (!active) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VoiceCallScreen(
                  partner: partner,
                  signaling: signaling,
                  isCaller: signaling.isCaller,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? PokiColors.darkSurface : PokiColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6BCF7F).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: PokiShadows.softOf(context),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6BCF7F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '🐾 Aramada: ${_fmt(signaling.callDuration)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PokiColors.textOf(context),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    signaling.endCall();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5F5F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⬛ Bitir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
