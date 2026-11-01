// lib/features/puzzle/puzzle_game_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';
import 'models/puzzle_config.dart';
import 'widgets/piece_tray.dart';
import 'widgets/puzzle_board.dart';
import 'widgets/puzzle_top_bar.dart';

/// Oyun ekranı İSKELETİ. Mantık (parça üretimi, sürükle-bırak, senkron) sonraki adımlarda.
class PuzzleGameScreen extends StatelessWidget {
  const PuzzleGameScreen({super.key, required this.roomId, required this.config});

  final String roomId;
  final PuzzleConfig config;

  @override
  Widget build(BuildContext context) {
    final d = config.difficulty;
    return Scaffold(
      backgroundColor: PokiColors.backgroundOf(context),
      appBar: AppBar(title: const Text('Poki Puzzle 🧩')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              PuzzleTopBar(mode: config.mode, placed: 0, total: d.pieceCount),
              const SizedBox(height: 16),
              Expanded(child: Center(child: PuzzleBoard(grid: d.grid))),
              const SizedBox(height: 16),
              PieceTray(count: d.pieceCount),
            ],
          ),
        ),
      ),
    );
  }
}
