// lib/features/quiz/quiz_lobby_screen.dart
import 'package:flutter/material.dart';

import 'models/quiz_category.dart';
import 'models/quiz_config.dart';
import 'models/quiz_mode.dart';
import 'models/quiz_question.dart';
import 'models/quiz_round_length.dart';
import 'quiz_game_screen.dart';
import 'theme/quiz_palette.dart';
import 'widgets/category_selector.dart';
import 'widgets/custom_question_sheet.dart';
import 'widgets/mode_selector.dart';
import 'widgets/round_length_selector.dart';

/// Poki Quiz lobisi: mod + kategori + tur uzunluğu + özel soru.
class QuizLobbyScreen extends StatefulWidget {
  const QuizLobbyScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<QuizLobbyScreen> createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen> {
  QuizMode _mode = QuizMode.readMyMind;
  Set<QuizCategory> _categories = {...QuizCategory.values};
  QuizRoundLength _length = QuizRoundLength.short;
  final List<QuizQuestion> _custom = [];

  Future<void> _addCustom() async {
    final q = await CustomQuestionSheet.show(context);
    if (q != null) setState(() => _custom.add(q));
  }

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizGameScreen(
          roomId: widget.roomId,
          config: QuizConfig(
            mode: _mode,
            categories: _categories,
            length: _length,
            customQuestions: List.unmodifiable(_custom),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizPalette.background(context),
      appBar: AppBar(
        backgroundColor: QuizPalette.background(context),
        foregroundColor: QuizPalette.text(context),
        title: Text('Poki Quiz 🎯',
            style: QuizPalette.title(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text('Ne Kadar Tanıyorsun?',
                      style: QuizPalette.title(context).copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text('Birbirinizi ne kadar iyi bildiğinizi keşfedin.',
                      style: QuizPalette.caption(context)),
                  const SizedBox(height: 24),
                  _Section(
                    title: '1 · Oyun modu',
                    child: QuizModeSelector(
                      selected: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                  ),
                  _Section(
                    title: '2 · Kategoriler',
                    child: QuizCategorySelector(
                      selected: _categories,
                      onChanged: (c) => setState(() => _categories = c),
                    ),
                  ),
                  _Section(
                    title: '3 · Tur uzunluğu',
                    child: RoundLengthSelector(
                      selected: _length,
                      onChanged: (l) => setState(() => _length = l),
                    ),
                  ),
                  _Section(
                    title: '4 · Özel sorular',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final q in _custom)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Text('✍️', style: TextStyle(fontSize: 22)),
                            title: Text(q.text, style: QuizPalette.body(context)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _custom.remove(q)),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: _addCustom,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Kendi sorunu ekle'),
                        ),
                      ],
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
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Oyunu Başlat'),
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
          Text(title, style: QuizPalette.subtitle(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
