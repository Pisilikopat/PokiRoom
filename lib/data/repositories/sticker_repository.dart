// lib/data/repositories/sticker_repository.dart
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/utils/uuid.dart';
import '../models/poki_sticker.dart';

class StickerRepository {
  StickerRepository._(this._db);

  /// Önbellek paylaşılsın diye tek örnek kullanılır.
  static final StickerRepository instance =
      StickerRepository._(Supabase.instance.client);

  static const String _bucket = 'stickers';

  final SupabaseClient _db;
  final Map<String, Future<PokiSticker>> _stickerCache = {};
  final Map<String, Future<Uint8List>> _bytesCache = {};

  String get _uid => _db.auth.currentUser!.id;

  Stream<List<PokiSticker>> watchStickers(String roomId) => _db
      .from('room_stickers')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(PokiSticker.fromMap).toList());

  /// PNG baytlarını `stickers/{room_id}/{uuid}.png` yoluna yükler ve kaydı oluşturur.
  Future<PokiSticker> uploadSticker({
    required String roomId,
    required Uint8List bytes,
    required int width,
    required int height,
  }) async {
    final id = generateUuidV4();
    final path = '$roomId/$id.png';

    try {
      await _db.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );
    } on StorageException {
      throw const PokiException('Çıkartma yüklenemedi, tekrar dener misin? 🐾');
    }

    try {
      final row = await _db
          .from('room_stickers')
          .insert({
            'id': id,
            'room_id': roomId,
            'creator_id': _uid,
            'storage_path': path,
            'width': width,
            'height': height,
          })
          .select()
          .single();
      final sticker = PokiSticker.fromMap(row);
      _bytesCache[id] = Future.value(bytes);
      return sticker;
    } on PostgrestException {
      try {
        await _db.storage.from(_bucket).remove([path]);
      } catch (_) {}
      throw const PokiException('Çıkartma kaydedilemedi, tekrar dener misin?');
    }
  }

  Future<PokiSticker> getSticker(String stickerId) {
    final cached = _stickerCache[stickerId];
    if (cached != null) return cached;
    final future = () async {
      try {
        final row =
            await _db.from('room_stickers').select().eq('id', stickerId).single();
        return PokiSticker.fromMap(row);
      } catch (_) {
        _stickerCache.remove(stickerId);
        rethrow;
      }
    }();
    _stickerCache[stickerId] = future;
    return future;
  }

  /// Çıkartma görselini bayt olarak getirir (Image.memory ile web + mobil uyumlu).
  Future<Uint8List> imageBytes(String stickerId) {
    final cached = _bytesCache[stickerId];
    if (cached != null) return cached;
    final future = () async {
      try {
        final sticker = await getSticker(stickerId);
        return await _db.storage.from(_bucket).download(sticker.storagePath);
      } catch (_) {
        _bytesCache.remove(stickerId);
        rethrow;
      }
    }();
    _bytesCache[stickerId] = future;
    return future;
  }

  Future<void> deleteSticker(PokiSticker sticker) async {
    try {
      await _db.from('room_stickers').delete().eq('id', sticker.id);
      try {
        await _db.storage.from(_bucket).remove([sticker.storagePath]);
      } catch (_) {}
      _stickerCache.remove(sticker.id);
      _bytesCache.remove(sticker.id);
    } on PostgrestException {
      throw const PokiException('Çıkartma silinemedi, tekrar dener misin?');
    }
  }
}
