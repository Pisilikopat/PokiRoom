// lib/core/theme/poki_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PokiRoom renk paleti. Saf siyah (#000000) kullanılmaz.
class PokiColors {
  PokiColors._();

  // Açık Tema (Gündüz)
  static const Color background = Color(0xFFFFFDF9); // Sıcak yulaf / krem
  static const Color surface = Color(0xFFF4EFE6); // Yumuşak bej (oda çerçevesi)
  static const Color primary = Color(0xFFFFB5A7); // Poki Pink / şeftali
  static const Color primaryButton = Color(0xFFFF9E80); // Buton vurgusu
  static const Color incomingBubble = Color(0xFFE2F0CB); // Adaçayı yeşili
  static const Color text = Color(0xFF4A403A); // Kakao kahvesi
  static const Color lampOn = Color(0xFFFFE169); // Online / masa lambası

  // Koyu Tema (Gece Odası)
  static const Color darkBackground = Color(0xFF1D1917); // Koyu kahve-kömür
  static const Color darkSurface = Color(0xFF2C2522); // Gece odası çerçevesi
  static const Color darkText = Color(0xFFF6F2EC); // Yumuşak krem beyazı
  static const Color darkIncomingBubble = Color(0xFF2E3827); // Koyu adaçayı
  static const Color darkPrimary = Color(0xFFE5988A); // Gece pembe
  static const Color darkPrimaryButton = Color(0xFFFF9E80); // Buton vurgusu

  // Context-aware renk yardımcıları
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : background;

  static Color textOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkText : text;

  static Color incomingBubbleOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkIncomingBubble : incomingBubble;
}

class PokiRadius {
  PokiRadius._();

  static const double card = 24;
  static final BorderRadius all = BorderRadius.circular(card);
}

class PokiShadows {
  PokiShadows._();

  /// Çok hafif, sıcak tonlu gölge.
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: PokiColors.text.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> softOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.35) : PokiColors.text.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class PokiTheme {
  PokiTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PokiColors.background,
    );

    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: PokiColors.text,
      displayColor: PokiColors.text,
    );

    final shape = RoundedRectangleBorder(borderRadius: PokiRadius.all);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: PokiColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: PokiColors.primaryButton,
        onPrimary: PokiColors.background,
        secondary: PokiColors.primary,
        onSecondary: PokiColors.text,
        surface: PokiColors.background,
        onSurface: PokiColors.text,
        surfaceContainerHighest: PokiColors.surface,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: PokiColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: PokiColors.background,
        foregroundColor: PokiColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          color: PokiColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PokiColors.primaryButton,
          foregroundColor: PokiColors.background,
          elevation: 2,
          shadowColor: PokiColors.text.withOpacity(0.15),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PokiColors.text,
          shape: shape,
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PokiColors.surface,
        hintStyle: TextStyle(color: PokiColors.text.withOpacity(0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: const BorderSide(color: PokiColors.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PokiColors.text,
        contentTextStyle: GoogleFonts.quicksand(color: PokiColors.background),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerColor: PokiColors.surface,
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PokiColors.darkBackground,
    );

    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: PokiColors.darkText,
      displayColor: PokiColors.darkText,
    );

    final shape = RoundedRectangleBorder(borderRadius: PokiRadius.all);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: PokiColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: PokiColors.darkPrimaryButton,
        onPrimary: PokiColors.darkBackground,
        secondary: PokiColors.darkPrimary,
        onSecondary: PokiColors.darkText,
        surface: PokiColors.darkSurface,
        onSurface: PokiColors.darkText,
        surfaceContainerHighest: PokiColors.darkSurface,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: PokiColors.darkText),
      appBarTheme: AppBarTheme(
        backgroundColor: PokiColors.darkBackground,
        foregroundColor: PokiColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          color: PokiColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PokiColors.darkPrimaryButton,
          foregroundColor: PokiColors.darkBackground,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PokiColors.darkText,
          shape: shape,
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PokiColors.darkSurface,
        hintStyle: TextStyle(color: PokiColors.darkText.withOpacity(0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: const BorderSide(color: PokiColors.darkPrimary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PokiColors.darkSurface,
        contentTextStyle: GoogleFonts.quicksand(color: PokiColors.darkText),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerColor: PokiColors.darkSurface,
    );
  }
}
