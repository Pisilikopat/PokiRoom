// lib/data/repositories/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/utils/poki_code_validator.dart';
import '../models/poki_user.dart';

class UserRepository {
  UserRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  Future<PokiUser> fetchUser(String id) async {
    final row = await _db.from('users').select().eq('id', id).single();
    return PokiUser.fromMap(row);
  }

  /// Oda partnerini canlı izler (mood, nickname...). RLS gereği sadece aktif oda partneri okunabilir.
  Stream<PokiUser> watchUser(String id) => _db
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => PokiUser.fromMap(rows.first));

  Future<PokiUser> fetchMe() async {
    final row = await _db.from('users').select().eq('id', _uid).single();
    return PokiUser.fromMap(row);
  }

  /// Kendi satırını canlı izler (PokiCode değişimi, odaya katılma vb.)
  Stream<PokiUser> watchMe() => _db
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', _uid)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => PokiUser.fromMap(rows.first));

  /// [suffix]: sadece "4829" kısmı; "#POKI-" öneki otomatik eklenir.
  Future<PokiUser> updateCustomTag(String suffix) async {
    if (!PokiCodeValidator.isValidSuffix(suffix)) {
      throw const PokiException(
          'PokiCode 4-12 karakter olmalı (sadece harf ve rakam) 🐾');
    }
    try {
      final row = await _db
          .from('users')
          .update({'custom_tag': PokiCodeValidator.toFullTag(suffix)})
          .eq('id', _uid)
          .select()
          .single();
      return PokiUser.fromMap(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const PokiException('Bu PokiCode başka bir kedi tarafından alınmış 🐱');
      }
      if (e.code == '23514') {
        throw const PokiException('PokiCode biçimi geçersiz.');
      }
      throw const PokiException('PokiCode değiştirilemedi, tekrar dener misin?');
    }
  }
}
