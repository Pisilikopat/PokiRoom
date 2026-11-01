// lib/features/puzzle/puzzle_setup_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';
import 'models/puzzle_config.dart';
import 'models/puzzle_difficulty.dart';
import 'models/puzzle_image_selection.dart';
import 'models/puzzle_mode.dart';
import 'puzzle_game_screen.dart';
import 'widgets/difficulty_selector.dart';
import 'widgets/image_source_picker.dart';
import 'widgets/mode_selector.dart';

/// Poki Puzzle kurulum ekranı: görsel + zorluk + mod seçimi.
class PuzzleSetupScreen extends StatefulWidget {
  const PuzzleSetupScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<PuzzleSetupScreen> createState() => _PuzzleSetupScreenState();
}

class _PuzzleSetupScreenState extends State<PuzzleSetupScreen> {
  PuzzleImageSelection? _image;
  PuzzleDifficulty _difficulty = PuzzleDifficulty.recommended;
  PuzzleMode _mode = PuzzleMode.coop;

  void _start() {
    final image = _image;
    if (image == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleGameScreen(
          roomId: widget.roomId,
          config: PuzzleConfig(image: image, difficulty: _difficulty, mode: _mode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: PokiColors.backgroundOf(context),
      appBar: AppBar(title: const Text('Poki Puzzle 🧩')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text('Bizim Parçamız', style: textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Bir görsel seç, zorluğu belirle ve birlikte tamamlayın.',
                      style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  _Section(
                    title: '1 · Görsel',
                    child: ImageSourcePicker(
                      selection: _image,
                      onChanged: (s) => setState(() => _image = s),
                    ),
                  ),
                  _Section(
                    title: '2 · Zorluk',
                    child: DifficultySelector(
                      selected: _difficulty,
                      onChanged: (d) => setState(() => _difficulty = d),
                    ),
                  ),
                  _Section(
                    title: '3 · Oyun modu',
                    child: ModeSelector(
                      selected: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _image == null ? null : _start,
                  icon: const Icon(Icons.extension_rounded),
                  label: Text(_image == null ? 'Önce bir görsel seç' : 'Oyunu Başlat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
