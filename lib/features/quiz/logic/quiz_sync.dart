// lib/features/quiz/logic/quiz_sync.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quiz_engine.dart';
import 'quiz_game_controller.dart';
import '../models/quiz_side.dart';
import '../models/quiz_mode.dart';

/// `room:$roomId:quiz` kanalı üzerinden iki oyuncu arasındaki canlı oyun senkronizasyonu.
class QuizSync {
  QuizSync({
    required this.roomId,
    required this.myId,
    required this.isHost,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client;

  final String roomId;
  final String myId;
  final bool isHost;
  final SupabaseClient _db;

  RealtimeChannel? _channel;
  QuizGameController? _controller;
  bool _disposed = false;
  bool _everSawPartner = false;

  final ValueNotifier<bool> partnerPresent = ValueNotifier(false);

  final StreamController<void> _abandonEvents =
      StreamController<void>.broadcast();
  Stream<void> get onAbandon => _abandonEvents.stream;

  void attach(QuizGameController controller) {
    _controller = controller;
    _channel = _db.channel(
      'room:$roomId:quiz',
      opts: RealtimeChannelConfig(key: myId),
    );

    _channel!
        .onPresenceSync((_) => _checkPresence())
        .onBroadcast(event: 'quiz_move', callback: _onRemoteMove)
        .onBroadcast(event: 'quiz_reveal', callback: _onRemoteReveal)
        .onBroadcast(event: 'quiz_advance', callback: _onRemoteAdvance)
        .onBroadcast(event: 'quiz_abandon', callback: _onRemoteAbandon)
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel?.track({'here': true, 'host': isHost});
      }
    });
  }

  void _checkPresence() {
    final presences = _channel?.presenceState() ?? [];
    var partnerHere = false;
    for (final state in presences) {
      if (state.key != myId && state.presences.isNotEmpty) {
        partnerHere = true;
        break;
      }
    }

    if (partnerHere) {
      _everSawPartner = true;
    } else if (_everSawPartner && !partnerHere) {
      // Partner daha önce bağlıydı ama şimdi düştü/çıktı!
      if (!_disposed && !_abandonEvents.isClosed) {
        _abandonEvents.add(null);
      }
    }

    partnerPresent.value = partnerHere;
  }

  // ------------------------------------------------------------- Gönderme

  /// Kendi seçimimi kilitlediğimde partnerime haber ver
  void sendLock({required int option}) {
    final c = _controller;
    if (c == null || _channel == null || _disposed) return;
    final mode = c.config.mode;

    if (mode == QuizMode.readMyMind) {
      if (c.engine.chooser == QuizSide.me) {
        // Gerçeği seçen tarafım: seçim kilitlendi ama şıkkı GİZLİ tutuyoruz
        _send('quiz_move', {'action': 'lock_choice'});
      } else {
        // Tahmin eden tarafım: tahminim kilitlendi (şık gönderilir)
        _send('quiz_move', {'action': 'lock_guess', 'option': option});
      }
    } else {
      // Ruh İkizi: cevabımı kilitledim ama şıkkı diğer taraf kilitleyene kadar GİZLİ
      _send('quiz_move', {'action': 'lock_answer'});
    }
  }

  /// İki taraf da kilitleyince gizli şıkkı açığa çıkar
  void sendReveal({required int option}) {
    _send('quiz_reveal', {'option': option});
  }

  /// Sıradaki soruya geç
  void sendAdvance() {
    _send('quiz_advance', {});
  }

  /// Oyundan ayrılma bildirimi
  void sendAbandon() {
    _send('quiz_abandon', {'reason': 'player_left'});
  }

  void _send(String event, Map<String, dynamic> payload) {
    if (_disposed || _channel == null) return;
    _channel!
        .sendBroadcastMessage(event: event, payload: {...payload, 'from': myId})
        .catchError((_) {});
  }

  // ----------------------------------------------------------- Karşılama

  void _onRemoteMove(Map<String, dynamic> payload) {
    final c = _controller;
    if (c == null || _disposed) return;

    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;

    final action = data['action'] as String?;
    final option = data['option'] as int?;

    try {
      if (action == 'lock_choice') {
        // Mod A: Karşı taraf (chooser) gerçeğini kilitledi
        c.engine.lockChoice(QuizSide.partner);
        c.notifyExternalChange();
      } else if (action == 'lock_guess') {
        // Mod A: Karşı taraf (guesser) tahminini kilitledi
        if (option != null) {
          c.engine.lockGuess(QuizSide.partner, option);
          // Eğer ben chooser isem, gizli gerçeğimi karşı tarafa aç
          if (c.engine.chooser == QuizSide.me && c.selection != null) {
            sendReveal(option: c.selection!);
          }
          c.notifyExternalChange();
        }
      } else if (action == 'lock_answer') {
        // Mod B: Karşı taraf kendi cevabını kilitledi
        c.engine.lockAnswer(QuizSide.partner);
        // Eğer ben de kilitlediysem, ikimiz de seçimlerimizi açıklıyoruz
        if (c.engine.hasLocked(QuizSide.me) && c.selection != null) {
          sendReveal(option: c.selection!);
        }
        c.notifyExternalChange();
      }
    } catch (_) {}
  }

  void _onRemoteReveal(Map<String, dynamic> payload) {
    final c = _controller;
    if (c == null || _disposed) return;

    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;

    final option = data['option'] as int?;
    if (option == null) return;

    try {
      if (c.config.mode == QuizMode.readMyMind) {
        c.engine.reveal(option);
      } else {
        c.engine.revealPick(QuizSide.partner, option);
        // Ben de henüz açıklamadıysam açıkla
        if (c.selection != null) {
          sendReveal(option: c.selection!);
        }
      }
      c.notifyExternalChange();
    } catch (_) {}
  }

  void _onRemoteAdvance(Map<String, dynamic> payload) {
    final c = _controller;
    if (c == null || _disposed) return;

    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;

    c.handleRemoteAdvance();
  }

  void _onRemoteAbandon(Map<String, dynamic> payload) {
    final nested = payload['payload'];
    final data = nested is Map ? nested.cast<String, dynamic>() : payload;
    if (data['from'] == myId) return;

    if (!_disposed && !_abandonEvents.isClosed) {
      _abandonEvents.add(null);
    }
  }

  void dispose() {
    _disposed = true;
    _abandonEvents.close();
    partnerPresent.dispose();
    if (_channel != null) {
      _db.removeChannel(_channel!);
      _channel = null;
    }
  }
}
