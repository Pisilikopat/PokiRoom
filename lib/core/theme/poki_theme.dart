// lib/core/theme/poki_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PokiRoom tema modları: Gündüz (Aydınlık), Gece (Karanlık) ve Pembe Mod (Çilekli Süt 🌸)
enum PokiThemeMode {
  light, // Gündüz (Aydınlık & Krem)
  dark,  // Gece (Karanlık & Sıcak Işık)
  pink,  // Pembe Mod (Canlı Pastel Pembe / Çilekli Süt & Kalpler 🌸)
}

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

  // Pembe Mod (Canlı Şeker & Çilekli Süt 🌸💖)
  static const Color pinkBackground = Color(0xFFFFC6D9); // Belirgin, göz alıcı tatlı çilekli süt pembesi
  static const Color pinkSurface = Color(0xFFFFB1C5); // Canlı pudra-pembe oda çerçevesi ve kartlar
  static const Color pinkText = Color(0xFF4A1020); // Derin vişne-kakao (kusursuz okunabilirlik)
  static const Color pinkIncomingBubble = Color(0xFFFFF0F5); // Karşı taraf: Marshmallow çilekli krema
  static const Color pinkPrimary = Color(0xFFFF3377); // Benim balonum: Canlı şeker kedi pembesi
  static const Color pinkPrimaryButton = Color(0xFFFF1A5E); // Butonlar ve ikonlar: Parlak çarpıcı pembe
  static const Color pinkLampOn = Color(0xFFFFBE0B); // Sıcak altın sarısı

  // Context-aware renk yardımcıları
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.surface ??
      (Theme.of(context).brightness == Brightness.dark ? darkSurface : surface);

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.background ??
      (Theme.of(context).brightness == Brightness.dark ? darkBackground : background);

  static Color textOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.text ??
      (Theme.of(context).brightness == Brightness.dark ? darkText : text);

  static Color incomingBubbleOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.incomingBubble ??
      (Theme.of(context).brightness == Brightness.dark ? darkIncomingBubble : incomingBubble);

  static Color outgoingBubbleOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.outgoingBubble ??
      (Theme.of(context).brightness == Brightness.dark ? darkPrimary : primary);

  static Color primaryButtonOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.primaryButton ?? primaryButton;

  static Color lampOnOf(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.lampOn ?? lampOn;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static bool isPink(BuildContext context) =>
      Theme.of(context).extension<PokiThemeColors>()?.mode == PokiThemeMode.pink;
}

/// Tüm temaların renklerini Widget ağacına taşıyan ThemeExtension
@immutable
class PokiThemeColors extends ThemeExtension<PokiThemeColors> {
  const PokiThemeColors({
    required this.mode,
    required this.background,
    required this.surface,
    required this.text,
    required this.primary,
    required this.primaryButton,
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.lampOn,
  });

  final PokiThemeMode mode;
  final Color background;
  final Color surface;
  final Color text;
  final Color primary;
  final Color primaryButton;
  final Color incomingBubble;
  final Color outgoingBubble;
  final Color lampOn;

  @override
  PokiThemeColors copyWith({
    PokiThemeMode? mode,
    Color? background,
    Color? surface,
    Color? text,
    Color? primary,
    Color? primaryButton,
    Color? incomingBubble,
    Color? outgoingBubble,
    Color? lampOn,
  }) {
    return PokiThemeColors(
      mode: mode ?? this.mode,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      primary: primary ?? this.primary,
      primaryButton: primaryButton ?? this.primaryButton,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      lampOn: lampOn ?? this.lampOn,
    );
  }

  @override
  PokiThemeColors lerp(ThemeExtension<PokiThemeColors>? other, double t) {
    if (other is! PokiThemeColors) return this;
    return PokiThemeColors(
      mode: t < 0.5 ? mode : other.mode,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryButton: Color.lerp(primaryButton, other.primaryButton, t)!,
      incomingBubble: Color.lerp(incomingBubble, other.incomingBubble, t)!,
      outgoingBubble: Color.lerp(outgoingBubble, other.outgoingBubble, t)!,
      lampOn: Color.lerp(lampOn, other.lampOn, t)!,
    );
  }
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
    final ext = Theme.of(context).extension<PokiThemeColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = ext != null
        ? ext.text.withOpacity(isDark ? 0.35 : 0.08)
        : (isDark ? Colors.black.withOpacity(0.35) : PokiColors.text.withOpacity(0.08));
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class PokiTheme {
  PokiTheme._();

  static ThemeData getTheme(PokiThemeMode mode) {
    switch (mode) {
      case PokiThemeMode.light:
        return light;
      case PokiThemeMode.dark:
        return dark;
      case PokiThemeMode.pink:
        return pink;
    }
  }

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
      extensions: const [
        PokiThemeColors(
          mode: PokiThemeMode.light,
          background: PokiColors.background,
          surface: PokiColors.surface,
          text: PokiColors.text,
          primary: PokiColors.primary,
          primaryButton: PokiColors.primaryButton,
          incomingBubble: PokiColors.incomingBubble,
          outgoingBubble: PokiColors.primary,
          lampOn: PokiColors.lampOn,
        ),
      ],
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
      extensions: const [
        PokiThemeColors(
          mode: PokiThemeMode.dark,
          background: PokiColors.darkBackground,
          surface: PokiColors.darkSurface,
          text: PokiColors.darkText,
          primary: PokiColors.darkPrimary,
          primaryButton: PokiColors.darkPrimaryButton,
          incomingBubble: PokiColors.darkIncomingBubble,
          outgoingBubble: PokiColors.darkPrimary,
          lampOn: PokiColors.lampOn,
        ),
      ],
    );
  }

  static ThemeData get pink {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PokiColors.pinkBackground,
      cardColor: PokiColors.pinkSurface,
    );

    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: PokiColors.pinkText,
      displayColor: PokiColors.pinkText,
    );

    final shape = RoundedRectangleBorder(borderRadius: PokiRadius.all);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: PokiColors.pinkPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: PokiColors.pinkPrimaryButton,
        onPrimary: Colors.white,
        secondary: PokiColors.pinkPrimary,
        onSecondary: Colors.white,
        surface: PokiColors.pinkSurface,
        onSurface: PokiColors.pinkText,
        surfaceContainerHighest: PokiColors.pinkSurface,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: PokiColors.pinkText),
      appBarTheme: AppBarTheme(
        backgroundColor: PokiColors.pinkSurface,
        foregroundColor: PokiColors.pinkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          color: PokiColors.pinkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PokiColors.pinkPrimaryButton,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: PokiColors.pinkPrimaryButton.withOpacity(0.35),
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
          foregroundColor: PokiColors.pinkPrimaryButton,
          shape: shape,
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF0F5),
        hintStyle: TextStyle(color: PokiColors.pinkText.withOpacity(0.55)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PokiRadius.all,
          borderSide: const BorderSide(color: PokiColors.pinkPrimary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PokiColors.pinkPrimaryButton,
        contentTextStyle: GoogleFonts.quicksand(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerColor: PokiColors.pinkSurface,
      extensions: const [
        PokiThemeColors(
          mode: PokiThemeMode.pink,
          background: PokiColors.pinkBackground,
          surface: PokiColors.pinkSurface,
          text: PokiColors.pinkText,
          primary: PokiColors.pinkPrimary,
          primaryButton: PokiColors.pinkPrimaryButton,
          incomingBubble: PokiColors.pinkIncomingBubble,
          outgoingBubble: PokiColors.pinkPrimary,
          lampOn: PokiColors.pinkLampOn,
        ),
      ],
    );
  }
}
