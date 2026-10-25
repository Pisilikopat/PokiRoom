// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_gate.dart';
import 'core/theme/poki_theme.dart';

const _supabaseUrl = 'https://bqfbatewvgzoidkonshd.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZmJhdGV3dmd6b2lka29uc2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4Mjc2MjIsImV4cCI6MjEwODQwMzYyMn0.DMgdBFt-RqbPLAHVUfKVKHwtVRdkVTCkmJBbsFZdV10';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  // Anonim oturum açma
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
