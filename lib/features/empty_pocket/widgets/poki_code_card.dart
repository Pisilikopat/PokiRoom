// lib/features/empty_pocket/widgets/poki_code_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../shared/widgets/poki_card.dart';

/// Kullanıcının kendi PokiCode'unu gösteren, kopyalatan ve değiştirten kart.
class PokiCodeCard extends StatelessWidget {
  const PokiCodeCard({super.key, required this.code, required this.onEdit});

  final String code;
  final VoidCallback onEdit;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('PokiCode kopyalandı 🐾')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PokiCard(
      color: PokiColors.primary.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Senin PokiCode\'un', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    code,
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kopyala',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              ),
              IconButton(
                tooltip: 'PokiCode\'u değiştir',
                icon: const Icon(Icons.edit_rounded),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bu kodu paylaşarak biriyle oda kurabilirsin. Dilediğin zaman değiştirebilirsin.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
