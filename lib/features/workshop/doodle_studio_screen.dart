// lib/features/workshop/doodle_studio_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import 'doodle_controller.dart';
import 'live_doodle_screen.dart';
import 'save_sticker_flow.dart';
import 'widgets/doodle_canvas.dart';
import 'widgets/doodle_toolbar.dart';
import 'widgets/sticker_picker_sheet.dart';

/// Atölye: çiz, şeffaf çıkartmaya çevir, sohbette kullan.
class DoodleStudioScreen extends StatefulWidget {
  const DoodleStudioScreen({
    super.key,
    required this.roomId,
    this.onInvitePartner,
  });

  final String roomId;

  /// "Birlikte çiz" açılırken karşı tarafı davet etmek için (opsiyonel).
  final Future<void> Function()? onInvitePartner;

  @override
  State<DoodleStudioScreen> createState() => _DoodleStudioScreenState();
}

class _DoodleStudioScreenState extends State<DoodleStudioScreen> {
  late final DoodleController _controller = DoodleController(
    ownerId: Supabase.instance.client.auth.currentUser!.id,
  );
  final GlobalKey _captureKey = GlobalKey();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await runSaveStickerFlow(
      context,
      roomId: widget.roomId,
      captureKey: _captureKey,
      controller: _controller,
    );
    if (mounted) setState(() => _saving = false);
  }

  void _openLive() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveDoodleScreen(
          roomId: widget.roomId,
          onInvitePartner: widget.onInvitePartner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atölye 🎨'),
        actions: [
          IconButton(
            tooltip: 'Çıkartmalarım',
            icon: const Icon(Icons.collections_rounded),
            onPressed: () => StickerPickerSheet.show(context, roomId: widget.roomId),
          ),
          IconButton(
            tooltip: 'Birlikte çiz',
            icon: const Icon(Icons.people_alt_rounded),
            onPressed: _openLive,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: DoodleCanvas(
                    controller: _controller,
                    captureKey: _captureKey,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DoodleToolbar(controller: _controller),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_controller.isEmpty || _saving) ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Çıkartma yap'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: PokiColors.background,
    );
  }
}
