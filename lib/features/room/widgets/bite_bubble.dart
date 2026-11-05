// lib/features/room/widgets/bite_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_message.dart';

/// Sohbette görüntülenen interaktif tatlı ısırık kartı.
class BiteBubble extends StatelessWidget {
  const BiteBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.meta,
    this.onBiteBack,
    this.partnerNickname = 'Partnerin',
  });

  final PokiMessage message;
  final bool isMine;
  final Widget meta;
  final VoidCallback? onBiteBack;
  final String partnerNickname;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bite = message.biteData;
    final senderDisplay = isMine ? 'Sen' : (bite?.senderName ?? partnerNickname);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF3E2723).withOpacity(0.85),
                  const Color(0xFF4E342E).withOpacity(0.85),
                ]
              : [
                  const Color(0xFFFFF0F5),
                  const Color(0xFFFFECEF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFFFF8DA1).withOpacity(0.35)
              : const Color(0xFFFFB6C1).withOpacity(0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8DA1).withOpacity(isDark ? 0.15 : 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8DA1).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    bite?.emoji ?? '🦷',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bite?.title ?? 'Tatlı Isırık! 🐾',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFF8DA1)
                            : const Color(0xFFD81B60),
                      ),
                    ),
                    Text(
                      isMine
                          ? 'Partnerini tatlıca ısırdın 🐱'
                          : '$senderDisplay seni tatlıca ısırdı! 🩹',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PokiColors.textOf(context).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bite?.phrase ??
                (isMine
                    ? 'Ham! Çok tatlı bir ısırıktı ✨'
                    : 'Ayy acımadı ki... Şirin bir ısırık aldın! 💖'),
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: PokiColors.textOf(context).withOpacity(0.85),
            ),
          ),
          if (!isMine && onBiteBack != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F91),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Text('🦷', style: TextStyle(fontSize: 15)),
                label: Text(
                  'Karşılık Isırığı Ver!',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onBiteBack?.call();
                },
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: meta,
          ),
        ],
      ),
    );
  }
}
