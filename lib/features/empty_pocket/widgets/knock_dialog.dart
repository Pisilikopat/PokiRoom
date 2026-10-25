// lib/features/empty_pocket/widgets/knock_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/knock_request.dart';

/// "Tık tık!" pop-up'ı. true = kabul, false = reddet.
class KnockDialog extends StatelessWidget {
  const KnockDialog({super.key, required this.request});

  final KnockRequest request;

  static Future<bool?> show(BuildContext context, KnockRequest request) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => KnockDialog(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasMessage = request.message != null && request.message!.isNotEmpty;
    return AlertDialog(
      title: const Text('Tık tık! 🐾'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${request.senderNickname} cebinin kapısını çalıyor.',
              style: textTheme.bodyLarge),
          if (hasMessage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PokiColors.incomingBubble,
                borderRadius: PokiRadius.all,
              ),
              child: Text(request.message!, style: textTheme.bodyMedium),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Şimdi değil'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Kapıyı aç'),
        ),
      ],
    );
  }
}
