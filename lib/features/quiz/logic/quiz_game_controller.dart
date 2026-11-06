// lib/features/quiz/logic/quiz_game_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/quiz_config.dart';
import '../models/quiz_side.dart';
import 'quiz_deck.dart';
import 'quiz_engine.dart';
import 'quiz_sync.dart';

/// Motoru ekrana bağlar: seçim durumu, otomatik ilerleme ve canlı senkronizasyon.
class QuizGameController extends ChangeNotifier {
  QuizGameController({
    required this.config,
    required this.deck,
    this.starter = QuizSide.me,
    this.sync,
    bool? simulatePartner,
    this.revealDelay = const Duration(milliseconds: 3500),
    Random? random,
  })  : simulatePartner = simulatePartner ?? (sync == null),
        engine = QuizEngine(mode: config.mode, deck: deck, starter: starter),
        _random = random ?? Random() {
    sync?.attach(this);
    _afterChange();
  }

  final QuizConfig config;
  final QuizDeck deck;
  final QuizSide starter;
  final bool simulatePartner;
  final Duration revealDelay;
  final QuizSync? sync;

  final QuizEngine engine;
  final Random _random;

  /// Benim henüz kilitlemediğim ya da kilitlediğim şık (arayüzde göstermek için).
  int? selection;

  Timer? _advanceTimer;
  Timer? _partnerTimer;
  bool _disposed = false;

  // -------------------------------------------------------- arayüz eylemleri

  void select(int option) {
    if (!engine.canAct(QuizSide.me)) return;
    selection = option;
    notifyListeners();
  }

  bool get canLock => engine.canAct(QuizSide.me) && selection != null;

  void lockMine() {
    final option = selection;
    if (option == null || !engine.canAct(QuizSide.me)) return;
    try {
      _applyMove(QuizSide.me, option);
      sync?.sendLock(option: option);
    } on QuizRuleException {
      return;
    }
    _afterChange();
  }

  /// Karşı tarafın bir şeyi seçmesi bekleniyor mu? ("Düşünen kedi" için)
  bool get partnerThinking {
    if (!engine.canAct(QuizSide.partner)) return false;
    return engine.chooser != null || engine.hasLocked(QuizSide.me);
  }

  /// Uzaktan gelen hamle bildirimi (QuizSync tarafından çağrılır)
  void notifyExternalChange() {
    if (_disposed) return;
    _afterChange();
  }

  /// Uzaktan gelen 'sıradaki soru' bildirimi
  void handleRemoteAdvance() {
    if (_disposed || engine.phase != QuizPhase.revealed) return;
    engine.advance();
    selection = null;
    _afterChange();
  }

  /// Oyunu erken bitir (partner ayrıldığında)
  void finishEarly() {
    _partnerTimer?.cancel();
    _advanceTimer?.cancel();
    engine.finishEarly();
    notifyListeners();
  }

  // ------------------------------------------------------------------ iç

  void _applyMove(QuizSide side, int option) {
    if (engine.chooser != null) {
      // Mod A
      if (engine.phase == QuizPhase.choosing) {
        engine.lockChoice(side, option: option);
      } else {
        engine.lockGuess(side, option);
      }
    } else {
      // Mod B
      engine.lockAnswer(side, option: option);
    }
  }

  void _afterChange() {
    if (_disposed) return;
    notifyListeners();
    _partnerTimer?.cancel();
    _advanceTimer?.cancel();

    switch (engine.phase) {
      case QuizPhase.revealed:
        _advanceTimer = Timer(revealDelay, _advance);
      case QuizPhase.finished:
        break;
      case QuizPhase.choosing:
      case QuizPhase.guessing:
      case QuizPhase.answering:
        if (simulatePartner) _scheduleSimulatedPartner();
    }
  }

  void _advance() {
    if (_disposed || engine.phase != QuizPhase.revealed) return;
    engine.advance();
    sync?.sendAdvance();
    selection = null;
    _afterChange();
  }

  void _scheduleSimulatedPartner() {
    if (!engine.canAct(QuizSide.partner)) return;
    final delay = Duration(milliseconds: 1200 + _random.nextInt(1800));
    final optCount = max(1, engine.question.options.length);
    _partnerTimer = Timer(delay, () {
      if (_disposed || !engine.canAct(QuizSide.partner)) return;
      try {
        _applyMove(QuizSide.partner, _random.nextInt(optCount));
      } on QuizRuleException {
        return;
      }
      _afterChange();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _partnerTimer?.cancel();
    _advanceTimer?.cancel();
    sync?.dispose();
    super.dispose();
  }
}
