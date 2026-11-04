// lib/features/quiz/quiz_game_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/room_presence.dart';
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
  StreamSubscription<void>? _abandonSub;
  bool _abandonDialogShown = false;

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
      _abandonSub = _sync?.onAbandon.listen((_) => _onPartnerLeft());
    }

    _controller = QuizGameController(
      config: widget.config,
      deck: deck,
      starter: widget.isHost ? QuizSide.me : QuizSide.partner,
      sync: _sync,
    );
    RoomPresence.current?.setActivity(
      widget.isHost ? PokiActivity.inQuizWaiting : PokiActivity.inQuizPlaying,
    );
  }

  void _onPartnerLeft() {
    if (!mounted || _abandonDialogShown) return;
    _abandonDialogShown = true;
    HapticFeedback.heavyImpact();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('😿', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Partnerin Ayrıldı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Arkadaşın oyundan çıktı veya bağlantısı kesildi 🐾\n\nO ana kadarki skorlarla sonuçlara göz atabilir veya sohbete geri dönebilirsin.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sohbete Dön',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PokiColors.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.finishEarly();
              _navigate();
            },
            child: const Text('Sonuçları Gör 🏆'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final eng = _controller.engine;
    if (eng.phase == QuizPhase.finished) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Oyundan Çıkılsın mı?'),
          ],
        ),
        content: const Text(
          'Oyundan ayrılırsan oyun sonlanacak ve karşı taraf da oyundan çıkacak.\n\nEmin misin?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Devam Et', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Evet, Ayrıl'),
          ),
        ],
      ),
    );

    if (leave == true) {
      _sync?.sendAbandon();
      return true;
    }
    return false;
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
    RoomPresence.current?.setActivity(PokiActivity.chatting);
    _abandonSub?.cancel();
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

      final isMePick = rec.myPick == i;
      final isPartnerPick = rec.partnerPick == i;

      if (eng.mode == QuizMode.readMyMind) {
        final isActual = eng.chooser == QuizSide.me ? isMePick : isPartnerPick;
        final isGuess = eng.chooser == QuizSide.me ? isPartnerPick : isMePick;

        if (isActual && isGuess) return OptionVisual.bothPicked;
        if (isActual) return OptionVisual.correct;
        if (isGuess) return OptionVisual.wrong;
      } else {
        if (isMePick && isPartnerPick) return OptionVisual.bothPicked;
        if (isMePick) return OptionVisual.iPicked;
        if (isPartnerPick) return OptionVisual.partnerPicked;
      }

      return OptionVisual.idle;
    }

    if (mySelection == i) {
      return eng.hasLocked(QuizSide.me)
          ? OptionVisual.locked
          : OptionVisual.selected;
    }

    return OptionVisual.idle;
  }

  String get _roleBanner {
    final eng = _controller.engine;
    if (eng.mode == QuizMode.readMyMind) {
      if (eng.phase == QuizPhase.choosing) {
        return eng.chooser == QuizSide.me
            ? 'Senin sıran: Gerçeği seç'
            : 'Partnerin gerçeğini seçiyor...';
      }
      if (eng.phase == QuizPhase.guessing) {
        return eng.chooser == QuizSide.me
            ? 'Partnerin tahmin ediyor...'
            : 'Senin sıran: Tahmin et';
      }
    }
    return 'İkiniz de size uyan şıkkı seçin';
  }

  Widget? get _bottomPanel {
    final eng = _controller.engine;
    final phase = eng.phase;

    if (phase == QuizPhase.revealed) {
      final rec = eng.lastRecord;
      if (rec == null) return null;
      return ReactionCat(
        matched: rec.matched,
        celebration: eng.mode == QuizMode.soulmates
            ? 'Ruh İkizi!'
            : 'Doğru Tahmin!',
        consolation: eng.mode == QuizMode.soulmates
            ? 'Zıt Kutuplar...'
            : 'Tüh, Bilemedin!',
      );
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final canExit = await _confirmExit();
            if (canExit && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: QuizPalette.background(context),
            appBar: AppBar(
              backgroundColor: QuizPalette.background(context),
              foregroundColor: QuizPalette.text(context),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () async {
                  final canExit = await _confirmExit();
                  if (canExit && mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
