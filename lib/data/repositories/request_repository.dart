// lib/data/repositories/request_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/utils/poki_code_validator.dart';
import '../models/knock_request.dart';

class RequestRepository {
  RequestRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  Future<void> sendKnock({required String suffix, String? message}) async {
    if (!PokiCodeValidator.isValidSuffix(suffix)) {
      throw const PokiException('Geçerli bir PokiCode gir 🐾');
    }
    try {
      await _db.rpc('send_knock', params: {
        'p_tag': PokiCodeValidator.toFullTag(suffix),
        'p_message': message,
      });
    } on PostgrestException catch (e) {
      throw PokiException(_knockError(e.message));
    }
  }

  Future<List<KnockRequest>> fetchIncoming() async {
    final rows = await _db
        .from('room_requests')
        .select('id, sender_id, knock_message, created_at, '
            'sender:users!room_requests_sender_id_fkey(nickname)')
        .eq('receiver_id', _uid)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(KnockRequest.fromMap).toList();
  }

  /// Gelen bekleyen "Tık tık!" isteklerini canlı izler.
  Stream<List<KnockRequest>> watchIncoming() => _db
      .from('room_requests')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', _uid)
      .asyncMap((_) => fetchIncoming());

  /// Başarılıysa yeni oda id'sini döner.
  Future<String> accept(String requestId) async {
    try {
      final roomId = await _db
          .rpc('accept_room_request', params: {'p_request_id': requestId});
      return roomId as String;
    } on PostgrestException catch (e) {
      throw PokiException(_acceptError(e.message));
    }
  }

  Future<void> reject(String requestId) async {
    await _db
        .from('room_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId)
        .eq('receiver_id', _uid);
  }

  String _knockError(String code) {
    switch (code) {
      case 'user_not_found':
        return 'Bu PokiCode ile bir cep bulamadım 🔍';
      case 'cannot_knock_self':
        return 'Kendi cebine tıklatamazsın 😸';
      case 'sender_busy':
        return 'Önce mevcut cebini kapatman gerek.';
      case 'receiver_busy':
        return 'Bu kişi şu an başka bir odada 🚪';
      case 'duplicate_request':
        return 'Bu kişiye zaten bir tık tık gönderdin, cevabı bekle ⏳';
      default:
        return 'Tık tık gönderilemedi, tekrar dener misin?';
    }
  }

  String _acceptError(String code) {
    switch (code) {
      case 'request_not_found':
        return 'Bu istek artık geçerli değil.';
      case 'user_busy':
        return 'Taraflardan biri başka bir odada.';
      default:
        return 'İstek kabul edilemedi, tekrar dener misin?';
    }
  }
}
