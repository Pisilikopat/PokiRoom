// lib/data/repositories/notification_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/poki_notification.dart';

class NotificationRepository {
  NotificationRepository._(this._db);

  static final NotificationRepository instance =
      NotificationRepository._(Supabase.instance.client);

  final SupabaseClient _db;
  final Map<String, String> _partnerCache = {};
  String? _myName;

  String get _uid => _db.auth.currentUser!.id;

  /// Bana gelen bildirimler, en yeni ilk sırada (son 50).
  Stream<List<PokiNotification>> watchNotifications() => _db
      .from('room_notifications')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', _uid)
      .order('created_at', ascending: false)
      .limit(50)
      .map((rows) =>
          rows.map(PokiNotification.tryParse).whereType<PokiNotification>().toList());

  /// Belirli bir alıcıya bildirim yazar. Bildirimler "en iyi çaba" mantığıyla
  /// çalışır: hata asıl işlemi (mesaj, çıkartma...) asla bozmaz. Başarıyı döner.
  /// Not: `knock` istemciden yazılamaz; sunucudaki send_knock() yazar.
  Future<bool> sendNotification({
    required String receiverId,
    required NotificationType type,
    required String senderName,
    required String roomId,
  }) async {
    final draft = type.compose(senderName);
    try {
      await _db.from('room_notifications').insert({
        'room_id': roomId,
        'sender_id': _uid,
        'receiver_id': receiverId,
        'type': type.wire,
        'title': draft.title,
        'body': draft.body,
      });
      return true;
    } catch (e) {
      debugPrint('Bildirim gönderilemedi: $e');
      return false;
    }
  }

  /// Odadaki partnere bildirim gönderir (partner ve kendi adın otomatik bulunur).
  Future<void> notifyPartner({
    required String roomId,
    required NotificationType type,
  }) async {
    try {
      final partnerId = await _partnerOf(roomId);
      final name = await _myNickname();
      await sendNotification(
        receiverId: partnerId,
        type: type,
        senderName: name,
        roomId: roomId,
      );
    } catch (e) {
      debugPrint('Partner bildirimi atlandı: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .from('room_notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('receiver_id', _uid);
  }

  Future<void> markAllAsRead() async {
    await _db
        .from('room_notifications')
        .update({'is_read': true})
        .eq('receiver_id', _uid)
        .eq('is_read', false);
  }

  Future<String> _partnerOf(String roomId) async {
    final cached = _partnerCache[roomId];
    if (cached != null) return cached;
    final row = await _db
        .from('rooms')
        .select('user1_id, user2_id')
        .eq('id', roomId)
        .single();
    final partner = row['user1_id'] == _uid
        ? row['user2_id'] as String
        : row['user1_id'] as String;
    _partnerCache[roomId] = partner;
    return partner;
  }

  Future<String> _myNickname() async {
    final cached = _myName;
    if (cached != null) return cached;
    final row =
        await _db.from('users').select('nickname').eq('id', _uid).single();
    final name = (row['nickname'] as String?)?.trim();
    final resolved = (name == null || name.isEmpty) ? 'Biri' : name;
    _myName = resolved;
    return resolved;
  }
}
