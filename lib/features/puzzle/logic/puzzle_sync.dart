// lib/features/puzzle/logic/puzzle_sync.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PuzzlePieceMove {
  const PuzzlePieceMove({
    required this.slotIndex,
    required this.pieceIndex,
    required this.byUserId,
  });

  final int slotIndex;
  final int pieceIndex;
  final String byUserId;
}

/// Supabase Realtime üzerinden iki oyuncu arasındaki canlı puzzle senkronizasyonu.
class PuzzleSync {
  PuzzleSync({
    required this.roomId,
    required this.myId,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client {
    _initChannel();
  }

  final String roomId;
  final String myId;
  final SupabaseClient _db;

  RealtimeChannel? _channel;
  bool _disposed = false;
  bool _everSawPartner = false;

  final ValueNotifier<bool> partnerPresent = ValueNotifier(false);
  final StreamController<PuzzlePieceMove> _moveController =
      StreamController<PuzzlePieceMove>.broadcast();
  final StreamController<void> _restartController =
      StreamController<void>.broadcast();
  final StreamController<void> _abandonController =
      StreamController<void>.broadcast();

  Stream<PuzzlePieceMove> get onPiecePlaced => _moveController.stream;
  Stream<void> get onRestart => _restartController.stream;
  Stream<void> get onAbandon => _abandonController.stream;

  void _initChannel() {
    final chan = _db.channel('room:$roomId:puzzle');
    _channel = chan;

    chan.onPresenceSync((_) => _checkPresence());

    chan.onBroadcast(event: 'piece_placed', callback: (payload) {
      if (_disposed) return;
      final by = payload['byUserId'] as String?;
      if (by == myId) return; // Kendi hamlemizi tekrar işlemeyiz

      final slot = payload['slotIndex'] as int?;
      final piece = payload['pieceIndex'] as int?;
      if (slot != null && piece != null) {
        _moveController.add(PuzzlePieceMove(
          slotIndex: slot,
          pieceIndex: piece,
          byUserId: by ?? '',
        ));
      }
    });

    chan.onBroadcast(event: 'puzzle_restart', callback: (payload) {
      if (_disposed) return;
      final by = payload['byUserId'] as String?;
      if (by == myId) return;
      _restartController.add(null);
    });

    chan.onBroadcast(event: 'puzzle_abandon', callback: (payload) {
      if (_disposed) return;
      final by = payload['byUserId'] as String?;
      if (by == myId) return;
      _abandonController.add(null);
    });

    chan.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        chan.track({'user_id': myId, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  void _checkPresence() {
    if (_disposed || _channel == null) return;
    final state = _channel!.presenceState();
    var hasPartner = false;
    for (final entry in state.entries) {
      for (final pres in entry.value) {
        final uid = pres.payload['user_id'] as String?;
        if (uid != null && uid != myId) {
          hasPartner = true;
          break;
        }
      }
      if (hasPartner) break;
    }

    if (hasPartner) {
      _everSawPartner = true;
      partnerPresent.value = true;
    } else {
      partnerPresent.value = false;
      if (_everSawPartner) {
        _abandonController.add(null);
      }
    }
  }

  void sendPiecePlaced({required int slotIndex, required int pieceIndex}) {
    if (_disposed) return;
    _channel?.sendBroadcastMessage(
      event: 'piece_placed',
      payload: {
        'slotIndex': slotIndex,
        'pieceIndex': pieceIndex,
        'byUserId': myId,
      },
    );
  }

  void sendRestart() {
    if (_disposed) return;
    _channel?.sendBroadcastMessage(
      event: 'puzzle_restart',
      payload: {'byUserId': myId},
    );
  }

  void sendAbandon() {
    if (_disposed) return;
    _channel?.sendBroadcastMessage(
      event: 'puzzle_abandon',
      payload: {'byUserId': myId},
    );
  }

  void dispose() {
    _disposed = true;
    _moveController.close();
    _restartController.close();
    _abandonController.close();
    _channel?.untrack();
    if (_channel != null) {
      _db.removeChannel(_channel!);
    }
  }
}
