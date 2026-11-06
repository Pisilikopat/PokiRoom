import 'package:flutter/foundation.dart';
// lib/features/auth/auth_gate.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/services/notification_center.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Oturum durumuna göre LoginScreen veya HomeScreen gösterir.
/// Giriş yapıldığında NotificationCenter'ı başlatır, çıkış yapıldığında durdurur.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSub;
  bool _ready = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    _loggedIn = session != null;
    _ready = true;

    // Oturum zaten varsa bildirimleri hemen başlat
    if (_loggedIn) {
      NotificationCenter.instance.start();
      if (!kIsWeb) {
        NotificationService.instance.syncTokenWithSupabase();
      }
    }

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final hasSession = data.session != null;
      if (hasSession && !_loggedIn) {
        // Yeni giriş → bildirimleri başlat
        NotificationCenter.instance.start();
        if (!kIsWeb) {
          NotificationService.instance.syncTokenWithSupabase();
        }
      } else if (!hasSession && _loggedIn) {
        // Çıkış → bildirimleri durdur
        NotificationCenter.instance.stop();
      }
      if (mounted && hasSession != _loggedIn) {
        setState(() => _loggedIn = hasSession);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: PokiColors.primary),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _loggedIn
          ? const HomeScreen(key: ValueKey('home'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
