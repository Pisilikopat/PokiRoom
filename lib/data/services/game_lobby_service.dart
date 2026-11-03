// lib/data/services/game_lobby_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final StreamController<QuizInvite> _inviteEvents =
      StreamController<QuizInvite>.broadcast();
  Stream<QuizInvite> get onQuizInvite => _inviteEvents.stream;

  void init(String roomId) {
    if (_roomId == roomId && _channel != null) return;
    _disposeChannel();
    _roomId = roomId;
    _myId = _db.auth.currentUser?.id;

    final channel = _db.channel(
      'room:$roomId:lobby',
      opts: RealtimeChannelConfig(key: _myId),
    );

    channel
        .onBroadcast(event: 'quiz_invite', callback: _handleQuizInvite)
        .onBroadcast(event: 'quiz_cancel', callback: (_) => clearInvite())
        .subscribe();

    _channel = channel;
  }

  void _handleQuizInvite(Map<String, dynamic> payload) {
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;

    final from = data['from'] as String?;
    if (from == _myId) return; // Kendi gönderdiğimiz davet

    try {
      final configMap = (data['config'] as Map?)?.cast<String, dynamic>() ?? {};
      final questionsList = (data['questions'] as List?) ?? [];
      final questions = questionsList
          .map((q) => QuizQuestion.fromJson((q as Map).cast<String, dynamic>()))
          .toList();

      final invite = QuizInvite(
        hostId: from ?? '',
        hostNickname: (data['nickname'] as String?) ?? 'Partnerin',
        config: QuizConfig.fromJson(configMap),
        questions: questions,
        timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

      _activeQuizInvite = invite;
      _inviteEvents.add(invite);
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

  void clearInvite() {
    _activeQuizInvite = null;
    notifyListeners();
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
    _inviteEvents.close();
    super.dispose();
  }
}
