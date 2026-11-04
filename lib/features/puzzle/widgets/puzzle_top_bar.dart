// lib/features/puzzle/widgets/puzzle_top_bar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/puzzle_mode.dart';

/// Oyun üst çubuğu: mod, geçen süre, ipucu butonu, ilerleme ve partner durumu.
class PuzzleTopBar extends StatelessWidget {
  const PuzzleTopBar({
    super.key,
    required this.mode,
    required this.placed,
    required this.total,
    required this.elapsedSeconds,
    this.showGhostHint = true,
    this.onToggleHint,
    this.partnerHere = false,
  });

  final PuzzleMode mode;
  final int placed;
  final int total;
  final int elapsedSeconds;
  final bool showGhostHint;
  final VoidCallback? onToggleHint;
  final bool partnerHere;

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context),
        borderRadius: PokiRadius.all,
        boxShadow: PokiShadows.softOf(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${mode.emoji} ${mode.label}',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              // Sayaç
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PokiColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(elapsedSeconds),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // İpucu butonu
              if (onToggleHint != null)
                IconButton(
                  tooltip: showGhostHint ? 'İpucunu Gizle' : 'İpucunu Göster',
                  icon: Icon(
                    showGhostHint
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: showGhostHint
                        ? const Color(0xFFFFB74D)
                        : PokiColors.textOf(context).withOpacity(0.55),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleHint,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : placed / total,
              minHeight: 10,
              backgroundColor: PokiColors.backgroundOf(context),
              color: PokiColors.primaryButton,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$placed / $total parça',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: partnerHere
                      ? const Color(0xFF81C784)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                partnerHere ? 'Partner bağlandı 🐾' : 'Partner bekleniyor...',
                style: textTheme.bodySmall?.copyWith(
                  color: partnerHere
                      ? const Color(0xFF4CAF50)
                      : PokiColors.textOf(context).withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
