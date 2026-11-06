// lib/data/repositories/message_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../models/poki_message.dart';
import '../models/poki_voice_data.dart';

class MessageRepository {
  MessageRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  /// En yeni mesaj ilk sırada, varsayılan son 40 mesaj (ters ListView için uygun).
  Stream<List<PokiMessage>> watchMessages(String roomId, {int limit = 40}) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(limit)
      .map((rows) => rows.map(PokiMessage.fromMap).toList());

  /// Belirli bir tarihten önceki eski mesajları sayfalı çeker (Cursor-based pagination).
  Future<List<PokiMessage>> fetchOlderMessages(
    String roomId, {
    required DateTime before,
    int limit = 40,
    String? messageType,
  }) async {
    var query = _db
        .from('messages')
        .select()
        .eq('room_id', roomId)
        .lt('created_at', before.toUtc().toIso8601String());

    if (messageType != null && messageType.isNotEmpty && messageType != 'all') {
      query = query.eq('message_type', messageType);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((m) => PokiMessage.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Tek bir mesajı ID'ye göre getirir.
  Future<PokiMessage?> fetchSingleMessage(String messageId) async {
    final res = await _db
        .from('messages')
        .select()
        .eq('id', messageId)
        .maybeSingle();
    if (res == null) return null;
    return PokiMessage.fromMap(res as Map<String, dynamic>);
  }

  /// Tüm oda geçmişinde kelime ve mesaj türüne göre arama yapar.
  Future<List<PokiMessage>> searchMessages(
    String roomId, {
    String? query,
    String? messageType,
    int limit = 80,
  }) async {
    var req = _db.from('messages').select().eq('room_id', roomId);

    if (messageType != null && messageType.isNotEmpty && messageType != 'all') {
      req = req.eq('message_type', messageType);
    }

    final cleanQ = query?.trim() ?? '';
    if (cleanQ.isNotEmpty) {
      req = req.ilike('content', '%$cleanQ%');
    }

    final rows = await req
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((m) => PokiMessage.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendText(String roomId, String text, {PokiReplyInfo? reply}) {
    final finalContent = reply != null
        ? PokiMessage.formatWithReply(text, reply)
        : text;
    return _send(roomId, 'text', finalContent);
  }

  /// Tatlı ısırık mesajı
  Future<void> sendBite(
    String roomId, {
    required String spot,
    required String bittenName,
    required String senderName,
    String? title,
    String? phrase,
    String? emoji,
  }) {
    final content = PokiBiteData.format(
      spot: spot,
      bittenName: bittenName,
      senderName: senderName,
      title: title,
      phrase: phrase,
      emoji: emoji,
    );
    return _send(roomId, 'text', content);
  }

  /// Buğulu mesaj: alıcı üzerini silince okunmuş sayılır.
  Future<void> sendFoggy(String roomId, String text) =>
      _send(roomId, 'foggy', text);

  /// Çıkartma mesajı: content = room_stickers.id
  Future<void> sendSticker(String roomId, String stickerId) =>
      _send(roomId, 'sticker', stickerId);

  /// Sesli mesaj: content = PokiVoiceData.toJson()
  Future<void> sendVoice(
    String roomId,
    PokiVoiceData voice, {
    PokiReplyInfo? reply,
  }) {
    final jsonStr = voice.toJson();
    final finalContent = reply != null
        ? PokiMessage.formatWithReply(jsonStr, reply)
        : jsonStr;
    return _send(roomId, 'voice', finalContent);
  }

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
