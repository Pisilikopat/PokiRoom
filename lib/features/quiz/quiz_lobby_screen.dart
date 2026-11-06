// lib/features/quiz/quiz_lobby_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/services/game_lobby_service.dart';
import '../../data/services/room_presence.dart';
import 'data/quiz_question_bank.dart';
import 'logic/quiz_deck.dart';
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
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    GameLobbyService.instance.init(widget.roomId);
    RoomPresence.current?.setActivity(PokiActivity.inQuizWaiting);
  }

  @override
  void dispose() {
    RoomPresence.current?.setActivity(PokiActivity.chatting);
    super.dispose();
  }

  Future<void> _addCustom() async {
    final q = await CustomQuestionSheet.show(context);
    if (q != null) setState(() => _custom.add(q));
  }

  List<QuizQuestion> _buildQuestions(QuizConfig config) {
    final count = config.length.questions;
    final List<QuizQuestion> pool = [...config.customQuestions];

    if (config.mode == QuizMode.telepathy) {
      final bank = [...QuizQuestionBank.telepathyPool]..shuffle(Random());
      for (final q in bank) {
        if (pool.length >= count) break;
        if (!pool.any((p) => p.id == q.id)) pool.add(q);
      }
      return pool.take(count).toList();
    }

    if (pool.length < count) {
      final bankPool = config.categories.isNotEmpty
          ? QuizQuestionBank.sample
              .where((q) =>
                  q.category != null && config.categories.contains(q.category))
              .toList()
          : QuizQuestionBank.sample.toList();

      final rng = Random();
      final shuffled = [...bankPool]..shuffle(rng);

      for (final q in shuffled) {
        if (pool.length >= count) break;
        if (!pool.any((p) => p.id == q.id)) pool.add(q);
      }
    }

    if (pool.length < count) {
      final all = QuizQuestionBank.sample
          .where((q) => !pool.any((p) => p.id == q.id))
          .toList()
        ..shuffle(Random());
      for (final q in all) {
        if (pool.length >= count) break;
        pool.add(q);
      }
    }

    return pool.take(count).toList();
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);

    final config = QuizConfig(
      mode: _mode,
      categories: _categories,
      length: _length,
      customQuestions: List.unmodifiable(_custom),
    );

    final questions = _buildQuestions(config);
    final deck = QuizDeck(questions);

    try {
      final me = await UserRepository().fetchMe();
      await GameLobbyService.instance.sendQuizInvite(
        config: config,
        questions: questions,
        myNickname: me.nickname,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _starting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizGameScreen(
          roomId: widget.roomId,
          config: config,
          deck: deck,
          isHost: true,
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
        title: Text('Poki Quiz 🎯', style: QuizPalette.title(context)),
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
                  if (_mode == QuizMode.telepathy)
                    _Section(
                      title: '2 · Frekans Havuzu',
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: QuizPalette.sage(context),
                          borderRadius: PokiRadius.all,
                        ),
                        child: Row(
                          children: [
                            const Text('🧠', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Telepati modunda ikinize özel 2 seçenekli anlık uyum ve frekans ikilemleri sorulur.',
                                style: QuizPalette.body(context).copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                            leading:
                                const Text('✍️', style: TextStyle(fontSize: 22)),
                            title: Text(q.text, style: QuizPalette.body(context)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () =>
                                  setState(() => _custom.remove(q)),
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
                  onPressed: _starting ? null : _start,
                  icon: _starting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_starting ? 'Hazırlanıyor...' : 'Oyunu Başlat'),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
