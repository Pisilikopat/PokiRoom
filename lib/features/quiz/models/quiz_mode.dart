// lib/features/quiz/models/quiz_mode.dart

enum QuizMode {
  /// Sıra tabanlı: biri gerçeğini seçer (gizli), diğeri tahmin eder.
  readMyMind(
    'Aklımı Oku!',
    'Biri kendi gerçeğini gizlice seçer 🔒, diğeri tahmin eder. Doğru tahmin: +10 Pati Puanı. Her soruda roller değişir.',
    '🔒',
  ),

  /// Eşzamanlı: ikisi de kendi tercihini yapar; ikisi de işaretleyene kadar şıklar buğulu.
  soulmates(
    'Ruh İkizi miyiz?',
    'İkiniz aynı soruyu aynı anda cevaplarsınız. İkiniz de seçene kadar şıklar buğulu kalır.',
    '💖',
  ),

  /// Eşzamanlı 2 seçenekli durumlar: Aynı seçeneği seçebilirseniz telepati tutar!
  telepathy(
    'Telepati / Frekans',
    'Aynı anda 2 seçenekli anlık ikilemler gelir. Aynı şeyi hissedip seçebilirseniz telepati tutar ve ortak frekans yakalanır! 🧠✨',
    '🧠',
  );

  const QuizMode(this.label, this.description, this.emoji);

  final String label;
  final String description;
  final String emoji;
}
