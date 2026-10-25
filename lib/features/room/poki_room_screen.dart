// lib/features/room/poki_room_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_message.dart';
import '../../data/models/poki_room.dart';
import '../../data/models/poki_user.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/room_presence.dart';
import 'widgets/foggy_compose_sheet.dart';
import 'widgets/hearts_burst.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/poke_toast.dart';
import 'widgets/poki_poke_menu.dart';
import 'widgets/room_header.dart';
import 'widgets/typing_paws.dart';

/// 1'e 1 kilitli PokiRoom ana sohbet ekranı.
/// Cebi kapatınca users.current_room_id null olur; AppGate otomatik Boş Cep'e döner.
class PokiRoomScreen extends StatefulWidget {
  const PokiRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<PokiRoomScreen> createState() => _PokiRoomScreenState();
}

class _PokiRoomScreenState extends State<PokiRoomScreen>
    with WidgetsBindingObserver {
  static const _pokeCooldown = Duration(seconds: 3);

  final _users = UserRepository();
  final _rooms = RoomRepository();
  final _messages = MessageRepository();

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  PokiUser? _me;
  PokiUser? _partner;
  PokiRoom? _room;
  List<PokiMessage> _list = const [];
  RoomPresence? _presence;

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _foreground = true;
  bool _loading = true;
  String? _error;

  // Poki-Poke durumu
  int? _burstId;
  int _burstCounter = 0;
  String? _toast;
  Timer? _toastTimer;
  DateTime? _lastPokeSent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _presence?.dispose();
    super.dispose();
  }

  void _listen<T>(Stream<T> stream, void Function(T) onData) {
    _subs.add(stream.listen(onData, onError: (_) {}));
  }

  Future<void> _init() async {
    try {
      final room = await _rooms.fetchRoom(widget.roomId);
      final partnerId = room.partnerOf(_myId);
      final me = await _users.fetchMe();
      final partner = await _users.fetchUser(partnerId);
      if (!mounted) return;

      final presence = RoomPresence(
        roomId: widget.roomId,
        myId: _myId,
        partnerId: partnerId,
      )
        ..addListener(() {
          if (mounted) setState(() {});
        })
        ..join();

      setState(() {
        _room = room;
        _me = me;
        _partner = partner;
        _presence = presence;
        _loading = false;
      });

      _listen(presence.pokes, _onPoke);
      _listen(_users.watchMe(), (u) => _setState(() => _me = u));
      _listen(_users.watchUser(partnerId), (u) => _setState(() => _partner = u));
      _listen(_rooms.watchRoom(widget.roomId), (r) => _setState(() => _room = r));
      _listen(_messages.watchMessages(widget.roomId), (list) {
        _setState(() => _list = list);
        _maybeMarkRead();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Oda yüklenemedi, tekrar dener misin?';
        });
      }
    }
  }

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ---------------------------------------------------------------- okundu

  void _maybeMarkRead() {
    if (!_foreground) return;
    // Buğulu mesajlar sadece silinince okunmuş sayılır.
    final hasUnread = _list.any(
      (m) => m.senderId != _myId && !m.isRead && m.type != 'foggy',
    );
    if (hasUnread) {
      _messages.markRead(widget.roomId).catchError((_) {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    if (isForeground == _foreground) return;
    _foreground = isForeground;
    if (isForeground) {
      _presence?.resume();
      _maybeMarkRead();
    } else {
      _presence?.pause();
    }
  }

  // ------------------------------------------------------------ Poki-Poke

  void _onPoke(PokeEvent event) {
    HapticFeedback.mediumImpact();
    _toastTimer?.cancel();
    setState(() {
      _burstId = ++_burstCounter;
      _toast = 'Pıt! 🐾 ${event.nickname} şu an seni düşünüyor';
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _openMenu() async {
    final action = await PokiPokeMenu.show(context);
    switch (action) {
      case PokiPokeAction.thinkingOfYou:
        await _sendPoke();
      case PokiPokeAction.foggyMessage:
        await _composeFoggy();
      case null:
        break;
    }
  }

  Future<void> _sendPoke() async {
    final now = DateTime.now();
    final last = _lastPokeSent;
    if (last != null && now.difference(last) < _pokeCooldown) {
      _snack('Biraz yavaş, kedi nefes alsın 🐱');
      return;
    }
    _lastPokeSent = now;
    try {
      await _presence?.sendPoke(_me?.nickname ?? 'Biri');
      final partnerName = _partner?.nickname ?? 'Karşı taraf';
      _snack(
        (_presence?.partnerOnline ?? false)
            ? 'Poki-Poke gönderildi 🐾'
            : '$partnerName şu an uyuyor, Poki-Poke\'u görmeyebilir 💤',
      );
    } catch (_) {
      _snack('Poki-Poke gönderilemedi, tekrar dener misin?');
    }
  }

  Future<void> _composeFoggy() async {
    final text = await FoggyComposeSheet.show(context);
    if (text == null) return;
    try {
      await _messages.sendFoggy(widget.roomId, text);
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  // ------------------------------------------------------------- mesajlar

  Future<void> _send(String text) async {
    try {
      await _messages.sendText(widget.roomId, text);
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _confirmClosePocket() async {
    final partnerName = _partner?.nickname ?? 'karşı taraf';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cebi kapatalım mı? 🐾'),
        content: Text(
          'Oda $partnerName için de kapanacak. Başka biriyle konuşabilmen için bu gerekli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cebi Kapat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _rooms.closeRoom();
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ----------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PokiColors.primary)),
      );
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    final presence = _presence;
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              RoomHeader(
                me: _me,
                partner: _partner,
                partnerOnline: presence?.partnerOnline ?? false,
                streak: _room?.streakCount ?? 1,
                onClosePocket: _confirmClosePocket,
              ),
              Expanded(child: _buildMessages()),
              if (presence?.partnerTyping ?? false)
                TypingPaws(name: _partner?.nickname ?? 'Karşı taraf'),
              MessageInput(
                onSend: _send,
                onTypingChanged: (typing) => presence?.setTyping(typing),
                onOpenMenu: _openMenu,
              ),
            ],
          ),
          if (_burstId != null)
            Positioned.fill(
              child: HeartsBurst(
                key: ValueKey(_burstId),
                onDone: () => _setState(() => _burstId = null),
              ),
            ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.6),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _toast == null
                    ? const SizedBox.shrink(key: ValueKey('no-toast'))
                    : Padding(
                        key: ValueKey(_toast),
                        padding: const EdgeInsets.only(top: 8),
                        child: PokeToast(text: _toast!),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_list.isEmpty) {
      return Center(
        child: Text(
          'Cebin sessiz... ilk mesajı sen bırak 🐾',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      reverse: true, // liste en yeni mesaj ilk olacak şekilde geliyor
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _list.length,
      itemBuilder: (context, index) {
        final m = _list[index];
        return MessageBubble(
          key: ValueKey(m.id),
          message: m,
          isMine: m.senderId == _myId,
          onFoggyRevealed: () =>
              _messages.markMessageRead(m.id).catchError((_) {}),
        );
      },
    );
  }
}
