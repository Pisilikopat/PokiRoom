// lib/features/pet/widgets/pet_stats_bar.dart

import 'package:flutter/material.dart';
import '../logic/pet_math.dart';
import '../pet_strings.dart';

class PetStatsBar extends StatelessWidget {
  const PetStatsBar({super.key, required this.stats});

  final PetStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _StatRow(
            label: PetStrings.hunger,
            emoji: '🍖',
            value: stats.hunger,
            color: const Color(0xFFF59E0B),
            warning: stats.isHungry ? 'Karnı gurulduyor 😿' : null,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: PetStrings.affection,
            emoji: '❤️',
            value: stats.affection,
            color: const Color(0xFFF43F5E),
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: PetStrings.energy,
            emoji: '⚡',
            value: stats.energy,
            color: const Color(0xFF6366F1),
            warning: stats.isTired ? 'Uykusu geldi 🥱' : null,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.emoji,
    required this.value,
    required this.color,
    this.warning,
  });

  final String label;
  final String emoji;
  final int value;
  final Color color;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (value / 100.0).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: color.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '%$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        if (warning != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: warning!,
            child: const Text('⚠️', style: TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );
  }
}
