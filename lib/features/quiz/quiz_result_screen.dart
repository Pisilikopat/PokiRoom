// lib/features/quiz/quiz_result_screen.dart
import 'package:flutter/material.dart';

import 'logic/quiz_engine.dart';
import 'logic/quiz_verdict.dart';
import 'models/quiz_config.dart';
import 'models/quiz_mode.dart';
import 'theme/quiz_palette.dart';
import 'widgets/certificate_card.dart';

/// Poki Uyum Sertifikası. (İsimler ve Anılara iğneleme sonraki adımlarda bağlanacak.)
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.result,
  });

  final String roomId;
  final QuizConfig config;
  final QuizResult result;

  String get _statLine => result.mode == QuizMode.readMyMind
      ? '🐾 ${result.patiPoints} Pati Puanı · ${result.matches}/${result.total} doğru tahmin'
      : '💖 ${result.soulmates} Ruh İkizi · 🐱 ${result.opposites} Zıt Kutup';

  void _soon(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final verdict = QuizVerdict.of(result);
    return Scaffold(
      backgroundColor: QuizPalette.background(context),
      appBar: AppBar(
        backgroundColor: QuizPalette.background(context),
        foregroundColor: QuizPalette.text(context),
        title: Text('Sonuç 🎉', style: QuizPalette.title(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CertificateCard(
              myName: 'Sen',
              partnerName: 'Partnerin',
              percent: result.percent,
              title: verdict.title,
              comment: verdict.comment,
              statLine: _statLine,
              date: DateTime.now(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _soon(context, 'Anılara iğneleme son adımda geliyor 📌'),
              icon: const Icon(Icons.push_pin_rounded),
              label: const Text('Anılar Panosuna İğnele 📌'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              // Oyun ekranı bu ekranla değiştirildiği için tek geri = lobi
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Rövanş Oyna 🔁'),
            ),
          ],
        ),
      ),
    );
  }
}
