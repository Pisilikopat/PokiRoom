// lib/features/workshop/live_doodle_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import 'doodle_controller.dart';
import 'live_doodle_sync.dart';
import 'save_sticker_flow.dart';
import 'widgets/doodle_canvas.dart';
import 'widgets/doodle_toolbar.dart';

/// 1'e 1 canlı doodle: iki kişi aynı tuvale aynı anda çizer.
class LiveDoodleScreen extends StatefulWidget {
  const LiveDoodleScreen({
    super.key,
    required this.roomId,
    this.onInvitePartner,
  });

  final String roomId;

  /// Ekran açılınca karşı tarafı davet etmek için (opsiyonel).
  final Future<void> Function()? onInvitePartner;

  @override
  State<LiveDoodleScreen> createState() => _LiveDoodleScreenState();
}

class _LiveDoodleScreenState extends State<LiveDoodleScreen> {
  late final String _myId = Supabase.instance.client.auth.currentUser!.id;
  late final DoodleController _controller = DoodleController(ownerId: _myId);
  late final LiveDoodleSync _sync = LiveDoodleSync(
    roomId: widget.roomId,
    myId: _myId,
    controller: _controller,
  );
  final GlobalKey _captureKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sync.join();
    widget.onInvitePartner?.call();
  }

  @override
  void dispose() {
    _sync.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tuval temizlensin mi?'),
        content: const Text('İkinizin çizimi de silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (ok == true) _controller.clear();
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: PokiColors.background,
      appBar: AppBar(title: const Text('Birlikte Çiz 🐾')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _sync.partnerHere,
                builder: (context, here, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: here
                        ? PokiColors.incomingBubble
                        : PokiColors.surface,
                    borderRadius: PokiRadius.all,
                  ),
                  child: Text(
                    here
                        ? 'Karşı taraf tuvalde, birlikte çizin! 🎨'
                        : 'Karşı tarafı bekliyoruz... 💤',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: DoodleCanvas(
                    controller: _controller,
                    captureKey: _captureKey,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DoodleToolbar(
                controller: _controller,
                onClearRequested: _confirmClear,
              ),
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
                    label: const Text('Çıkartmaya çevir'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
