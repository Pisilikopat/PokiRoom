// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/navigation/app_navigator.dart';
import 'core/services/notification_service.dart';
import 'core/theme/poki_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/notifications/notification_router.dart';
import 'shared/widgets/poki_notification_overlay.dart';

const _supabaseUrl = 'https://bqfbatewvgzoidkonshd.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZmJhdGV3dmd6b2lka29uc2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4Mjc2MjIsImV4cCI6MjEwODQwMzYyMn0.DMgdBFt-RqbPLAHVUfKVKHwtVRdkVTCkmJBbsFZdV10';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  await NotificationService.instance.initialize();
  runApp(const PokiRoomApp());
}

class PokiRoomApp extends StatelessWidget {
  const PokiRoomApp({super.key});

  /// Uygulama genelinde anlık tema değiştirici (Açık ☀️ / Koyu 🌙 / Pembe 🌸)
  static final ValueNotifier<PokiThemeMode> themeMode =
      ValueNotifier<PokiThemeMode>(PokiThemeMode.light);

  /// Sırayla temalar arasında geçiş yapar: Gündüz ☀️ ➔ Gece 🌙 ➔ Pembe Mod 🌸 ➔ Gündüz ☀️
  static void cycleTheme() {
    switch (themeMode.value) {
      case PokiThemeMode.light:
        themeMode.value = PokiThemeMode.dark;
        break;
      case PokiThemeMode.dark:
        themeMode.value = PokiThemeMode.pink;
        break;
      case PokiThemeMode.pink:
        themeMode.value = PokiThemeMode.light;
        break;
    }
  }

  /// Doğrudan istenen temaya geçirir
  static void setTheme(PokiThemeMode mode) {
    themeMode.value = mode;
  }

  /// Geriye dönük uyumluluk için
  static void toggleTheme() => cycleTheme();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PokiThemeMode>(
      valueListenable: themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'PokiRoom',
          debugShowCheckedModeBanner: false,
          theme: PokiTheme.getTheme(currentMode),
          navigatorKey: appNavigatorKey,
          builder: (context, child) => PokiNotificationOverlay(
            onTap: NotificationRouter.open,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
