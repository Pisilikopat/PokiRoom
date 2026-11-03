// lib/features/quiz/theme/quiz_palette.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Quiz modülünün Açık/Koyu tema uyumlu renkleri.
///
/// Projende zaten `backgroundOf(context)` / `surfaceOf(context)` gibi yardımcılar varsa
/// SADECE bu dosyadaki fonksiyonların gövdesini onlara bağlaman yeterli;
/// quiz widget'ları renkleri yalnızca buradan okur.
class QuizPalette {
  QuizPalette._();

  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  static Color background(BuildContext c) =>
      isDark(c) ? const Color(0xFF2A2420) : PokiColors.background;

  static Color surface(BuildContext c) =>
      isDark(c) ? const Color(0xFF3A322D) : PokiColors.surface;

  static Color text(BuildContext c) =>
      isDark(c) ? const Color(0xFFF4EFE6) : PokiColors.text;

  static Color mutedText(BuildContext c) => text(c).withOpacity(0.65);

  /// Poki Pink (iki temada da aynı)
  static Color primary(BuildContext c) => PokiColors.primary;

  /// Buton vurgusu
  static Color accent(BuildContext c) => PokiColors.primaryButton;

  /// Adaçayı yeşili (gelen balon / doğru)
  static Color sage(BuildContext c) =>
      isDark(c) ? const Color(0xFF55663F) : PokiColors.incomingBubble;

  static Color correct(BuildContext c) =>
      isDark(c) ? const Color(0xFF6E8F4E) : const Color(0xFFB5E48C);

  static Color wrong(BuildContext c) =>
      isDark(c) ? const Color(0xFF9C5650) : const Color(0xFFF4A6A0);

  static Color lamp(BuildContext c) => PokiColors.lampOn;

  static List<BoxShadow> softShadow(BuildContext c) => [
        BoxShadow(
          color: (isDark(c) ? Colors.black : PokiColors.text)
              .withOpacity(isDark(c) ? 0.35 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ---- Yazı stilleri (renk temaya göre) ----
  static TextStyle title(BuildContext c) => Theme.of(c)
      .textTheme
      .titleLarge!
      .copyWith(color: text(c), fontWeight: FontWeight.w800);

  static TextStyle subtitle(BuildContext c) => Theme.of(c)
      .textTheme
      .titleSmall!
      .copyWith(color: text(c), fontWeight: FontWeight.w800);

  static TextStyle body(BuildContext c) =>
      Theme.of(c).textTheme.bodyMedium!.copyWith(color: text(c));

  static TextStyle caption(BuildContext c) =>
      Theme.of(c).textTheme.bodySmall!.copyWith(color: mutedText(c));
}
