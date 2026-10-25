// lib/data/repositories/message_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../models/poki_message.dart';

class MessageRepository {
  MessageRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  /// En yeni mesaj ilk sırada, son 100 mesaj (ters ListView için uygun).
  Stream<List<PokiMessage>> watchMessages(String roomId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.map(PokiMessage.fromMap).toList());

  Future<void> sendText(String roomId, String text) =>
      _send(roomId, 'text', text);

  /// Buğulu mesaj: alıcı üzerini silince okunmuş sayılır.
  Future<void> sendFoggy(String roomId, String text) =>
      _send(roomId, 'foggy', text);

  Future<void> _send(String roomId, String type, String text) async {
    final content = text.trim();
    if (content.isEmpty) return;
    try {
      await _db.from('messages').insert({
        'room_id': roomId,
        'sender_id': _uid,
        'message_type': type,
        'content': content,
      });
    } on PostgrestException {
      throw const PokiException('Mesaj gönderilemedi, tekrar dener misin? 🐾');
    }
  }

  /// Karşı tarafın okunmamış (buğulu olmayan) mesajlarını okundu yapar.
  Future<void> markRead(String roomId) async {
    await _db
        .from('messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .neq('sender_id', _uid)
        .neq('message_type', 'foggy')
        .eq('is_read', false);
  }

  /// Tek mesajı okundu yapar (buğulu mesaj silinince).
  Future<void> markMessageRead(String messageId) async {
    await _db
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId)
        .neq('sender_id', _uid);
  }
}
