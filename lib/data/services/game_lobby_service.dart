// lib/data/services/game_lobby_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/puzzle/models/puzzle_config.dart';
import '../../features/quiz/models/quiz_config.dart';
import '../../features/quiz/models/quiz_question.dart';

class QuizInvite {
  const QuizInvite({
    required this.hostId,
    required this.hostNickname,
    required this.config,
    required this.questions,
    required this.timestamp,
  });

  final String hostId;
  final String hostNickname;
  final QuizConfig config;
  final List<QuizQuestion> questions;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class CanvasInvite {
  const CanvasInvite({
    required this.hostId,
    required this.hostNickname,
    required this.timestamp,
  });

  final String hostId;
  final String hostNickname;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class PuzzleInvite {
  const PuzzleInvite({
    required this.hostId,
    required this.hostNickname,
    required this.config,
    required this.timestamp,
  });

  final String hostId;
  final String hostNickname;
  final PuzzleConfig config;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

/// Tüm oyun lobileri ve canlı davetleri yöneten servis.
class GameLobbyService extends ChangeNotifier {
  GameLobbyService._();
  static final GameLobbyService instance = GameLobbyService._();

  final SupabaseClient _db = Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _roomId;
  String? _myId;

  QuizInvite? _activeQuizInvite;
  QuizInvite? get activeQuizInvite =>
      (_activeQuizInvite?.isExpired ?? true) ? null : _activeQuizInvite;

  CanvasInvite? _activeCanvasInvite;
  CanvasInvite? get activeCanvasInvite =>
      (_activeCanvasInvite?.isExpired ?? true) ? null : _activeCanvasInvite;

  final StreamController<CanvasInvite> _canvasInviteEvents =
      StreamController<CanvasInvite>.broadcast();
  Stream<CanvasInvite> get onCanvasInvite => _canvasInviteEvents.stream;

  PuzzleInvite? _activePuzzleInvite;
  PuzzleInvite? get activePuzzleInvite =>
      (_activePuzzleInvite?.isExpired ?? true) ? null : _activePuzzleInvite;

  final StreamController<QuizInvite> _quizInviteEvents =
      StreamController<QuizInvite>.broadcast();
  Stream<QuizInvite> get onQuizInvite => _quizInviteEvents.stream;

  final StreamController<PuzzleInvite> _puzzleInviteEvents =
      StreamController<PuzzleInvite>.broadcast();
  Stream<PuzzleInvite> get onPuzzleInvite => _puzzleInviteEvents.stream;

  void init(String roomId) {
    if (_roomId == roomId && _channel != null) return;
    _disposeChannel();
    _roomId = roomId;
    _myId = _db.auth.currentUser?.id;

    final myKey = _myId ?? '';
    final channel = _db.channel(
      'room:$roomId:lobby',
      opts: RealtimeChannelConfig(key: myKey),
    );

    channel
        .onBroadcast(event: 'quiz_invite', callback: _handleQuizInvite)
        .onBroadcast(event: 'quiz_cancel', callback: (_) => clearQuizInvite())
        .onBroadcast(event: 'puzzle_invite', callback: _handlePuzzleInvite)
        .onBroadcast(event: 'puzzle_cancel', callback: (_) => clearPuzzleInvite())
        .onBroadcast(event: 'canvas_invite', callback: _handleCanvasInvite)
        .onBroadcast(event: 'canvas_cancel', callback: (_) => clearCanvasInvite())
        .subscribe();

    _channel = channel;
  }

  void _handleQuizInvite(Map<String, dynamic> payload) {
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;

    final from = data['from'] as String?;
    if (from == _myId) return; // Kendi gönderdiğimiz davet

    try {
      final configMap =
          (data['config'] as Map?)?.cast<String, dynamic>() ?? {};
      final questionsList = (data['questions'] as List?) ?? [];
      final questions = questionsList
          .map((q) =>
              QuizQuestion.fromJson((q as Map).cast<String, dynamic>()))
          .toList();

      final invite = QuizInvite(
        hostId: from ?? '',
        hostNickname: (data['nickname'] as String?) ?? 'Partnerin',
        config: QuizConfig.fromJson(configMap),
        questions: questions,
        timestamp:
            DateTime.tryParse(data['timestamp'] as String? ?? '') ??
                DateTime.now(),
      );

      _activeQuizInvite = invite;
      _quizInviteEvents.add(invite);
      notifyListeners();
    } catch (_) {}
  }

  void _handlePuzzleInvite(Map<String, dynamic> payload) {
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;

    final from = data['from'] as String?;
    if (from == _myId) return; // Kendi gönderdiğimiz davet

    try {
      final configMap =
          (data['config'] as Map?)?.cast<String, dynamic>() ?? {};

      final invite = PuzzleInvite(
        hostId: from ?? '',
        hostNickname: (data['nickname'] as String?) ?? 'Partnerin',
        config: PuzzleConfig.fromJson(configMap),
        timestamp:
            DateTime.tryParse(data['timestamp'] as String? ?? '') ??
                DateTime.now(),
      );

      _activePuzzleInvite = invite;
      _puzzleInviteEvents.add(invite);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendQuizInvite({
    required QuizConfig config,
    required List<QuizQuestion> questions,
    required String myNickname,
  }) async {
    final myId = _myId ?? _db.auth.currentUser?.id;
    final payload = {
      'from': myId,
      'nickname': myNickname,
      'config': config.toJson(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _channel?.sendBroadcastMessage(
      event: 'quiz_invite',
      payload: payload,
    );
  }

  Future<void> sendPuzzleInvite({
    required PuzzleConfig config,
    required String myNickname,
  }) async {
    final myId = _myId ?? _db.auth.currentUser?.id;
    final payload = {
      'from': myId,
      'nickname': myNickname,
      'config': config.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _channel?.sendBroadcastMessage(
      event: 'puzzle_invite',
      payload: payload,
    );
  }

  void clearQuizInvite() {
    _activeQuizInvite = null;
    notifyListeners();
  }

  void clearPuzzleInvite() {
    _activePuzzleInvite = null;
    notifyListeners();
  }

  void clearInvite() {
    clearQuizInvite();
    clearPuzzleInvite();
    clearCanvasInvite();
  }

  void _disposeChannel() {
    if (_channel != null) {
      _db.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  void dispose() {
    _disposeChannel();
    _quizInviteEvents.close();
    _puzzleInviteEvents.close();
    _canvasInviteEvents.close();
    super.dispose();
  }
}
