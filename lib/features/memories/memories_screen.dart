// lib/features/memories/memories_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_memory.dart';
import '../../data/repositories/memory_repository.dart';
import '../workshop/widgets/sticker_picker_sheet.dart';
import 'widgets/memory_card.dart';
import 'widgets/note_composer_sheet.dart';

enum _AddAction { note, sticker }

/// Anılar: ikilinin ortak mantar panosu / hatıra defteri.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _repo = MemoryRepository();
  late final Stream<List<PokiMemory>> _stream =
      _repo.watchMemories(widget.roomId);

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _add() async {
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Not yaz'),
                onTap: () => Navigator.of(ctx).pop(_AddAction.note),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions_rounded),
                title: const Text('Çıkartma ekle'),
                onTap: () => Navigator.of(ctx).pop(_AddAction.sticker),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;

    try {
      switch (action) {
        case _AddAction.note:
          final text = await NoteComposerSheet.show(context);
          if (text != null) await _repo.addNote(widget.roomId, text);
        case _AddAction.sticker:
          await StickerPickerSheet.show(
            context,
            roomId: widget.roomId,
            onPick: (s) async {
              try {
                await _repo.addSticker(widget.roomId, s.id);
              } on PokiException catch (e) {
                _snack(e.message);
              }
            },
          );
      }
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _confirmDelete(PokiMemory m) async {
    if (m.authorId != _myId) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anı panodan kaldırılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(m.id);
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anılar 📌')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: PokiColors.primaryButton,
        foregroundColor: PokiColors.background,
        icon: const Icon(Icons.push_pin_rounded),
        label: const Text('Anı ekle'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CorkPainter())),
          StreamBuilder<List<PokiMemory>>(
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
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Panon henüz boş 📌\nSohbette bir mesaja uzun basıp iğneleyebilir ya da "Anı ekle"ye dokunabilirsin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return _board(list);
            },
          ),
        ],
      ),
    );
  }

  Widget _board(List<PokiMemory> list) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: MemoryCard(
          key: ValueKey(m.id),
          memory: m,
          onLongPress: m.authorId == _myId ? () => _confirmDelete(m) : null,
        ),
      );
      (i.isEven ? left : right).add(card);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(children: [const SizedBox(height: 28), ...right]),
          ),
        ],
      ),
    );
  }
}

/// Mantar doku: sabit tohumlu rastgele benekler.
class _CorkPainter extends CustomPainter {
  const _CorkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE6CFAA));
    final rnd = math.Random(42);
    final dark = Paint()..color = const Color(0xFFB58B5A).withOpacity(0.25);
    final light = Paint()..color = const Color(0xFFF5E3C3).withOpacity(0.45);
    for (var i = 0; i < 320; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawCircle(p, 0.8 + rnd.nextDouble() * 1.6, i.isEven ? dark : light);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
