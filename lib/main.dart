// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_gate.dart';
import 'core/theme/poki_theme.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://bqfbatewvgvoidkonshd.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZmJhdGV3dmd6b2lka29uc2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4Mjc2MjIsImV4cCI6MjEwODQwMzYyMn0.DMgdBFt-RqbPLAHVUfKVKHwtVRdkVTCkmJBbsFZdV10',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  // GEÇİCİ: Auth ekranı sonraki adımlarda gelecek. Test için anonim giriş.
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    await auth.signInAnonymously();
  }

  runApp(const PokiRoomApp());
}

class PokiRoomApp extends StatelessWidget {
  const PokiRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokiRoom',
      debugShowCheckedModeBanner: false,
      theme: PokiTheme.light,
      home: const AppGate(),
    );
  }
}
