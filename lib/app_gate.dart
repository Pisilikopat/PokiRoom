// lib/app_gate.dart
import 'package:flutter/material.dart';

import 'core/theme/poki_theme.dart';
import 'data/models/poki_user.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/notification_center.dart';
import 'features/empty_pocket/empty_pocket_screen.dart';
import 'features/room/poki_room_screen.dart';

/// Kullanıcının current_room_id durumuna göre Boş Cep ya da PokiRoom gösterir.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late final Stream<PokiUser> _meStream = UserRepository().watchMe();

  @override
  void initState() {
    super.initState();
    NotificationCenter.instance.start();
  }

  @override
  void dispose() {
    NotificationCenter.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PokiUser>(
      stream: _meStream,
      builder: (context, snapshot) {
        final me = snapshot.data;
        if (me == null) {
          return Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? const Text('Bağlantı kurulamadı 🐾')
                  : const CircularProgressIndicator(color: PokiColors.primary),
            ),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: me.hasRoom
              ? PokiRoomScreen(
                  key: ValueKey(me.currentRoomId),
                  roomId: me.currentRoomId!,
                )
              : EmptyPocketScreen(
                  key: const ValueKey('empty-pocket'),
                  onRoomJoined: (_) {}, // geçişi AppGate yönetiyor
                ),
        );
      },
    );
  }
}
