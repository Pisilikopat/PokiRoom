// lib/data/repositories/room_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../models/poki_room.dart';

class RoomRepository {
  RoomRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  Future<PokiRoom> fetchRoom(String roomId) async {
    final row = await _db.from('rooms').select().eq('id', roomId).single();
    return PokiRoom.fromMap(row);
  }

  /// Streak ve aktiflik değişikliklerini canlı izler.
  Stream<PokiRoom> watchRoom(String roomId) => _db
      .from('rooms')
      .stream(primaryKey: ['id'])
      .eq('id', roomId)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => PokiRoom.fromMap(rows.first));

  /// "Cebi Kapat"
  Future<void> closeRoom() async {
    try {
      await _db.rpc('close_room');
    } on PostgrestException {
      throw const PokiException('Cep kapatılamadı, tekrar dener misin?');
    }
  }
}
