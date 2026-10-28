// lib/data/repositories/memory_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../models/poki_memory.dart';
import '../models/poki_message.dart';
import '../models/poki_notification.dart';
import 'notification_repository.dart';

class MemoryRepository {
  MemoryRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  /// En yeni anı ilk sırada.
  Stream<List<PokiMemory>> watchMemories(String roomId) => _db
      .from('memories')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(PokiMemory.fromMap).toList());

  Future<void> addNote(String roomId, String text) =>
      _insert(roomId, MemoryKind.note, content: text);

  Future<void> addFoggy(String roomId, String text) =>
      _insert(roomId, MemoryKind.foggy, content: text);

  Future<void> addSticker(String roomId, String stickerId) =>
      _insert(roomId, MemoryKind.sticker, stickerId: stickerId);

  /// Sohbetteki bir mesajı anılara iğnele.
  Future<void> addFromMessage(PokiMessage m) {
    switch (m.type) {
      case 'sticker':
        return addSticker(m.roomId, m.content);
      case 'foggy':
        return addFoggy(m.roomId, m.content);
      case 'text':
        return addNote(m.roomId, m.content);
      default:
        throw const PokiException('Bu mesaj türü iğnelenemez.');
    }
  }

  Future<void> delete(String memoryId) async {
    try {
      await _db.from('memories').delete().eq('id', memoryId);
    } on PostgrestException {
      throw const PokiException('Anı silinemedi, tekrar dener misin?');
    }
  }

  Future<void> _insert(
    String roomId,
    String kind, {
    String? content,
    String? stickerId,
  }) async {
    final text = content?.trim();
    if (kind != MemoryKind.sticker && (text == null || text.isEmpty)) return;
    try {
      await _db.from('memories').insert({
        'room_id': roomId,
        'author_id': _uid,
        'kind': kind,
        if (text != null) 'content': text,
        if (stickerId != null) 'sticker_id': stickerId,
      });
      NotificationRepository.instance.notifyPartner(
        roomId: roomId,
        type: NotificationType.memoryPinned,
      );
    } on PostgrestException {
      throw const PokiException('Anı iğnelenemedi, tekrar dener misin? 📌');
    }
  }
}
