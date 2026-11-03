// lib/features/quiz/widgets/certificate_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/date_format.dart';
import '../theme/quiz_palette.dart';

/// Poki Uyum Sertifikası (karne kartı). İSKELET: sabit örnek veriyle çalışır.
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.myName,
    required this.partnerName,
    required this.percent,
    required this.title,
    required this.comment,
    required this.date,
    this.statLine,
  });

  final String myName;
  final String partnerName;

  /// 0-100
  final int percent;
  final String title;
  final String comment;
  final DateTime date;

  /// Örn: "🐾 40 Pati Puanı · 4/5 doğru tahmin"
  final String? statLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuizPalette.surface(context),
        borderRadius: PokiRadius.all,
        border: Border.all(color: QuizPalette.primary(context), width: 3),
        boxShadow: QuizPalette.softShadow(context),
      ),
      child: Column(
        children: [
          Text('🐾 Poki Uyum Sertifikası 🐾',
              textAlign: TextAlign.center, style: QuizPalette.subtitle(context)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: QuizPalette.background(context),
                    color: QuizPalette.accent(context),
                  ),
                ),
                Text('%$percent',
                    style: QuizPalette.title(context).copyWith(fontSize: 34)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('$myName 💞 $partnerName', style: QuizPalette.subtitle(context)),
          const SizedBox(height: 6),
          Text(title, style: QuizPalette.title(context), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(comment,
              textAlign: TextAlign.center, style: QuizPalette.body(context)),
          if (statLine != null) ...[
            const SizedBox(height: 12),
            Text(statLine!, style: QuizPalette.subtitle(context)),
          ],
          const SizedBox(height: 16),
          Text(formatStamp(date), style: QuizPalette.caption(context)),
        ],
      ),
    );
  }
}
