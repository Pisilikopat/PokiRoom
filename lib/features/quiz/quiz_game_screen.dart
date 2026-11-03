// lib/features/quiz/quiz_game_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import 'data/quiz_question_bank.dart';
import 'logic/quiz_deck.dart';
import 'logic/quiz_engine.dart';
import 'logic/quiz_game_controller.dart';
import 'logic/quiz_sync.dart';
import 'models/quiz_config.dart';
import 'models/quiz_mode.dart';
import 'models/quiz_question.dart';
import 'models/quiz_side.dart';
import 'quiz_result_screen.dart';
import 'theme/quiz_palette.dart';
import 'widgets/answer_option_tile.dart';
import 'widgets/question_card.dart';
import 'widgets/reaction_cat.dart';
import 'widgets/thinking_cat.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    this.deck,
    this.isHost = true,
  });

  final String roomId;
  final QuizConfig config;
  final QuizDeck? deck;
  final bool isHost;

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  static const _letters = ['A', 'B', 'C', 'D'];

  late final QuizGameController _controller;
  QuizSync? _sync;

  @override
  void initState() {
    super.initState();
    final deck = widget.deck ?? QuizDeck(_buildQuestions());
    final myId = Supabase.instance.client.auth.currentUser?.id;

    if (myId != null) {
      _sync = QuizSync(
        roomId: widget.roomId,
        myId: myId,
        isHost: widget.isHost,
      );
    }

    _controller = QuizGameController(
      config: widget.config,
      deck: deck,
      starter: widget.isHost ? QuizSide.me : QuizSide.partner,
      sync: _sync,
    );
  }

  List<QuizQuestion> _buildQuestions() {
    final count = widget.config.length.questions;
    final custom = widget.config.customQuestions;

    final List<QuizQuestion> pool = [...custom];

    if (pool.length < count) {
      final bankPool = widget.config.categories.isNotEmpty
          ? QuizQuestionBank.sample
              .where((q) =>
                  q.category != null &&
                  widget.config.categories.contains(q.category))
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OptionVisual _visualFor(int i) {
    final eng = _controller.engine;
    final phase = eng.phase;
    final mySelection = _controller.selection;

    if (phase == QuizPhase.revealed || phase == QuizPhase.finished) {
      final rec = eng.lastRecord;
      if (rec == null) return OptionVisual.idle;

      final myPick = rec.myPick;
      final partnerPick = rec.partnerPick;

      if (eng.mode == QuizMode.readMyMind) {
        final chooserPick = eng.chooser == QuizSide.me ? myPick : partnerPick;
        final guesserPick = eng.chooser == QuizSide.me ? partnerPick : myPick;

        if (i == chooserPick) return OptionVisual.correct;
        if (i == guesserPick && !rec.matched) return OptionVisual.wrong;
        return OptionVisual.idle;
      } else {
        if (rec.matched) {
          if (i == myPick) return OptionVisual.correct;
        } else {
          if (i == myPick) return OptionVisual.wrong;
          if (i == partnerPick) return OptionVisual.correct;
        }
        return OptionVisual.idle;
      }
    }

    if (eng.hasLocked(QuizSide.partner) && !eng.hasLocked(QuizSide.me)) {
      if (mySelection == i) return OptionVisual.selected;
      return OptionVisual.fogged;
    }

    if (eng.hasLocked(QuizSide.me)) {
      if (i == mySelection) return OptionVisual.lockedMine;
      return OptionVisual.idle;
    }

    return mySelection == i ? OptionVisual.selected : OptionVisual.idle;
  }

  String get _roleBanner {
    final eng = _controller.engine;
    final phase = eng.phase;

    if (phase == QuizPhase.revealed) {
      final rec = eng.lastRecord;
      if (rec == null) return '';
      if (eng.mode == QuizMode.readMyMind) {
        return rec.matched
            ? '✨ Doğru tahmin! +10 Pati Puanı'
            : '🙈 Yanlış tahmin...';
      } else {
        return rec.matched ? '💖 Ruh İkizisiniz!' : '🐱 Zıt kutuplar...';
      }
    }

    if (phase == QuizPhase.finished) return '🎉 Oyun bitti!';

    if (eng.mode == QuizMode.readMyMind) {
      if (phase == QuizPhase.choosing) {
        return eng.chooser == QuizSide.me
            ? 'Sıra sende: gerçeğini seç 🔒 (partner tahmin edecek)'
            : 'Partner gerçeğini seçiyor... 🔮';
      }
      if (phase == QuizPhase.guessing) {
        return eng.guesser == QuizSide.me
            ? 'Partnerin ne seçtiğini tahmin et! 🤔'
            : 'Sen seçtin, partner tahmin ediyor... 🐾';
      }
    }

    if (eng.hasLocked(QuizSide.me)) {
      return 'Seçimin kilitlendi 🔒 Partner bekleniyor...';
    }
    return 'İkiniz de seçin, sonra buğu kalkacak 🌫️';
  }

  Widget? get _bottomPanel {
    final phase = _controller.engine.phase;
    final rec = _controller.engine.lastRecord;

    if (phase == QuizPhase.revealed && rec != null) {
      if (_controller.engine.mode == QuizMode.readMyMind) {
        return ReactionCat(
          reaction: rec.matched ? CatReaction.correct : CatReaction.wrong,
        );
      } else {
        return ReactionCat(
          reaction: rec.matched ? CatReaction.soulmates : CatReaction.opposites,
        );
      }
    }

    if (_controller.partnerThinking) return const ThinkingCat();

    return null;
  }

  void _navigate() {
    final result = _controller.engine.result;
    if (result == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizResultScreen(
          roomId: widget.roomId,
          config: widget.config,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final eng = _controller.engine;
        final phase = eng.phase;

        if (phase == QuizPhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
        }

        final question = eng.question;
        final canAct = eng.canAct(QuizSide.me);

        return Scaffold(
          backgroundColor: QuizPalette.background(context),
          appBar: AppBar(
            backgroundColor: QuizPalette.background(context),
            foregroundColor: QuizPalette.text(context),
            title: Text(
              '${eng.mode.emoji} ${eng.mode.label}',
              style: QuizPalette.title(context),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ScoreBar(controller: _controller),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: QuizPalette.sage(context),
                    borderRadius: PokiRadius.all,
                  ),
                  child: Text(_roleBanner, style: QuizPalette.body(context)),
                ),
                const SizedBox(height: 12),
                QuestionCard(
                  question: question,
                  index: eng.index + 1,
                  total: eng.total,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnswerOptionTile(
                      letter: _letters[i],
                      text: question.options[i],
                      visual: _visualFor(i),
                      onTap: canAct ? () => _controller.select(i) : null,
                    ),
                  ),
                const SizedBox(height: 8),
                if (canAct && _controller.canLock)
                  ElevatedButton.icon(
                    onPressed: _controller.lockMine,
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Seçimi Kilitle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuizPalette.primary(context),
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_bottomPanel != null) ...[
                  const SizedBox(height: 16),
                  Center(child: _bottomPanel),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller});
  final QuizGameController controller;

  @override
  Widget build(BuildContext context) {
    final eng = controller.engine;
    final isMind = eng.mode == QuizMode.readMyMind;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QuizPalette.surface(context),
        borderRadius: PokiRadius.all,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isMind
                ? '🐾 ${eng.patiPoints} Pati Puanı'
                : '💖 ${eng.matchesSoFar} Ruh İkizi · 🐱 ${eng.opposesSoFar} Zıt',
            style: QuizPalette.subtitle(context),
          ),
          Text(
            '${eng.index + 1} / ${eng.total}',
            style: QuizPalette.caption(context),
          ),
        ],
      ),
    );
  }
}
