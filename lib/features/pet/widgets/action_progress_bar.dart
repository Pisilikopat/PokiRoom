// lib/features/pet/widgets/action_progress_bar.dart

import 'package:flutter/material.dart';
import '../models/pet_state.dart';
import '../pet_strings.dart';

class ActionProgressBar extends StatelessWidget {
  const ActionProgressBar({
    super.key,
    required this.action,
    required this.progress,
  });

  final PetActionKind action;
  final double progress; // 0.0 .. 1.0

  @override
  Widget build(BuildContext context) {
    if (action == PetActionKind.idle) {
      return const SizedBox(height: 38);
    }

    final isFeed = action == PetActionKind.eating;
    final color = isFeed ? const Color(0xFFF59E0B) : const Color(0xFFEC4899);
    final text = isFeed ? PetStrings.feedingProgress : PetStrings.pettingProgress;

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Dolma efekti
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.28),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Yazı
          Center(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
