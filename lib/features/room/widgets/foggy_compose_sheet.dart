// lib/features/room/widgets/foggy_compose_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Buğulu mesaj yazma paneli. Gönderilecek metinle kapanır (iptalde null).
class FoggyComposeSheet extends StatefulWidget {
  const FoggyComposeSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (_) => const FoggyComposeSheet(),
    );
  }

  @override
  State<FoggyComposeSheet> createState() => _FoggyComposeSheetState();
}

class _FoggyComposeSheetState extends State<FoggyComposeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buğulu mesaj 🌫️', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Karşı taraf üzerini silince okuyabilecek.',
              style: textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Sadece sana söylüyorum...'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.text.trim().isEmpty ? null : _submit,
              child: const Text('Buğula ve gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
