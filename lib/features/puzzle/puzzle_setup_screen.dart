// lib/features/puzzle/puzzle_setup_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/game_lobby_service.dart';
import '../../data/services/room_presence.dart';
import 'models/cat_art.dart';
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
  final _users = UserRepository();
  PuzzleImageSelection? _image =
      PuzzleImageSelection.cat(CatArt.all.first.id);
  PuzzleDifficulty _difficulty = PuzzleDifficulty.recommended;
  PuzzleMode _mode = PuzzleMode.coop;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    GameLobbyService.instance.init(widget.roomId);
  }

  Future<void> _start() async {
    final image = _image;
    if (image == null || _starting) return;
    setState(() => _starting = true);

    final config = PuzzleConfig(
      image: image,
      difficulty: _difficulty,
      mode: _mode,
    );

    try {
      final me = await _users.fetchMe();
      await GameLobbyService.instance.sendPuzzleInvite(
        config: config,
        myNickname: me.nickname,
      );
    } catch (_) {}

    RoomPresence.current?.setActivity(PokiActivity.inPuzzleWaiting);

    if (!mounted) return;
    setState(() => _starting = false);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleGameScreen(
          roomId: widget.roomId,
          config: config,
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
                  onPressed: (_image == null || _starting) ? null : _start,
                  icon: _starting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.extension_rounded),
                  label: Text(_image == null
                      ? 'Önce bir görsel seç'
                      : (_starting ? 'Lobi Kuruluyor...' : 'Oyunu Başlat')),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
