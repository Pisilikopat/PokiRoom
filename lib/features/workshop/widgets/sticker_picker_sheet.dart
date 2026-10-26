// lib/features/workshop/widgets/sticker_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/poki_exception.dart';
import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_sticker.dart';
import '../../../data/repositories/sticker_repository.dart';
import 'sticker_image.dart';

/// Çıkartma seçme çekmecesi. [onPick] verilirse dokununca seçer ve kapanır;
/// verilmezse yönetim modunda çalışır. Uzun basınca (kendi çıkartman) silinir.
class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({
    super.key,
    required this.roomId,
    this.onPick,
    this.onOpenWorkshop,
  });

  final String roomId;
  final void Function(PokiSticker sticker)? onPick;
  final VoidCallback? onOpenWorkshop;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    void Function(PokiSticker sticker)? onPick,
    VoidCallback? onOpenWorkshop,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (_) => StickerPickerSheet(
        roomId: roomId,
        onPick: onPick,
        onOpenWorkshop: onOpenWorkshop,
      ),
    );
  }

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  late final Stream<List<PokiSticker>> _stream =
      StickerRepository.instance.watchStickers(widget.roomId);

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  Future<void> _confirmDelete(PokiSticker s) async {
    if (s.creatorId != _myId) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkartma silinsin mi?'),
        content: const Text('Sohbetteki ve anılardaki kopyaları da kaybolabilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await StickerRepository.instance.deleteSticker(s);
    } on PokiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final picking = widget.onPick != null;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Çıkartmalarım 🎨', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              picking
                  ? 'Göndermek için dokun. Silmek için uzun bas.'
                  : 'Silmek için uzun bas.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<PokiSticker>>(
                stream: _stream,
                builder: (context, snapshot) {
                  final list = snapshot.data;
                  if (list == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: PokiColors.primary),
                    );
                  }
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Henüz çıkartman yok 🐾', style: textTheme.bodyLarge),
                          const SizedBox(height: 12),
                          if (widget.onOpenWorkshop != null)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onOpenWorkshop!();
                              },
                              child: const Text('Atölye\'ye git'),
                            ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final s = list[i];
                      return Material(
                        color: PokiColors.surface,
                        borderRadius: PokiRadius.all,
                        child: InkWell(
                          borderRadius: PokiRadius.all,
                          onTap: picking
                              ? () {
                                  Navigator.of(context).pop();
                                  widget.onPick!(s);
                                }
                              : null,
                          onLongPress: () => _confirmDelete(s),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: StickerImage(stickerId: s.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
