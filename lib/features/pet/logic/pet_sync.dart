// lib/features/pet/logic/pet_sync.dart

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_state.dart';

typedef OnPetRemoteUpdate = void Function(PetState state);
typedef OnPetEffectReceived = void Function(String effectType, String fromUserId);

class PetSync {
  PetSync({
    required this.roomId,
    required this.myId,
    required this.onRemoteUpdate,
    required this.onEffectReceived,
  }) {
    _init();
  }

  final String roomId;
  final String myId;
  final OnPetRemoteUpdate onRemoteUpdate;
  final OnPetEffectReceived onEffectReceived;

  RealtimeChannel? _channel;
  bool _disposed = false;

  void _init() {
    final client = Supabase.instance.client;
    _channel = client.channel('pet_room_$roomId');

    // 1) Postgres changes: room_pets satırı güncellendiğinde
    _channel?.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'room_pets',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        if (_disposed) return;
        final record = payload.newRecord;
        if (record.isNotEmpty) {
          try {
            final state = PetState.fromMap(record);
            onRemoteUpdate(state);
          } catch (_) {}
        }
      },
    );

    // 2) Broadcast: Anlık görsel efektler (uçuşan kalpler, yemek saçılması, miyav balonu)
    _channel?.onBroadcast(
      event: 'pet_effect',
      callback: (payload) {
        if (_disposed) return;
        final from = payload['from'] as String?;
        final effect = payload['effect'] as String?;
        if (from != null && from != myId && effect != null) {
          onEffectReceived(effect, from);
        }
      },
    );

    _channel?.subscribe();
  }

  /// Karşı tarafa anlık efekt fırlat
  void sendEffect(String effectType) {
    if (_disposed || _channel == null) return;
    _channel?.sendBroadcastMessage(
      event: 'pet_effect',
      payload: {
        'effect': effectType,
        'from': myId,
      },
    ).catchError((_) {});
  }

  void dispose() {
    _disposed = true;
    _channel?.unsubscribe();
  }
}
