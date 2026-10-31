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

  /// Uygulama genelinde anlık tema değiştirici (Açık / Koyu)
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'PokiRoom',
          debugShowCheckedModeBanner: false,
          theme: PokiTheme.light,
          darkTheme: PokiTheme.dark,
          themeMode: currentMode,
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
