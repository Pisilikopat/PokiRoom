// lib/features/workshop/save_sticker_flow.dart
import 'package:flutter/material.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_notification.dart';
import '../../data/repositories/memory_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/sticker_repository.dart';
import 'doodle_controller.dart';
import 'sticker_exporter.dart';

enum _AfterSave { send, pin, done }

/// Çizimi şeffaf PNG çıkartmaya çevirir, Storage'a yükler ve
/// "sohbette gönder / anılara iğnele" seçeneklerini sunar. Kaydedildiyse true döner.
Future<bool> runSaveStickerFlow(
  BuildContext context, {
  required String roomId,
  required GlobalKey captureKey,
  required DoodleController controller,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  try {
    final exported = await StickerExporter.capture(captureKey, controller);
    if (exported == null) {
      snack('Önce bir şeyler çiz 🎨');
      return false;
    }
    final sticker = await StickerRepository.instance.uploadSticker(
      roomId: roomId,
      bytes: exported.bytes,
      width: exported.width,
      height: exported.height,
    );
    NotificationRepository.instance.notifyPartner(
      roomId: roomId,
      type: NotificationType.stickerCreated,
    );
    if (!context.mounted) return true;

    final action = await showModalBottomSheet<_AfterSave>(
      context: context,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Çıkartman hazır! 🎉',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.send_rounded),
                title: const Text('Sohbette gönder'),
                onTap: () => Navigator.of(sheetContext).pop(_AfterSave.send),
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_rounded),
                title: const Text('Anılara iğnele'),
                onTap: () => Navigator.of(sheetContext).pop(_AfterSave.pin),
              ),
              ListTile(
                leading: const Icon(Icons.check_rounded),
                title: const Text('Sadece kaydet'),
                onTap: () => Navigator.of(sheetContext).pop(_AfterSave.done),
              ),
            ],
          ),
        ),
      ),
    );

    switch (action) {
      case _AfterSave.send:
        await MessageRepository().sendSticker(roomId, sticker.id);
        snack('Çıkartma sohbete gönderildi 🐾');
      case _AfterSave.pin:
        await MemoryRepository().addSticker(roomId, sticker.id);
        snack('Anılara iğnelendi 📌');
      case _AfterSave.done:
      case null:
        snack('Çıkartma kaydedildi 🐾');
    }
    return true;
  } on PokiException catch (e) {
    snack(e.message);
    return false;
  } catch (_) {
    snack('Çıkartma hazırlanamadı, tekrar dener misin?');
    return false;
  }
}
