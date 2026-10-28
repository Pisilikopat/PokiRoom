// lib/features/empty_pocket/empty_pocket_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/knock_request.dart';
import '../../data/models/poki_user.dart';
import '../../data/repositories/request_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../notifications/widgets/activity_bell_button.dart';
import 'widgets/edit_poki_code_sheet.dart';
import 'widgets/knock_dialog.dart';
import 'widgets/knock_form_card.dart';
import 'widgets/poki_code_card.dart';
import 'widgets/pocket_header.dart';

/// Bağlantı yokken gösterilen "Boş Cep" ekranı.
class EmptyPocketScreen extends StatefulWidget {
  const EmptyPocketScreen({super.key, required this.onRoomJoined});

  /// Kullanıcı bir odaya bağlanınca (kabul eden ya da kabul edilen taraf) çağrılır.
  final void Function(String roomId) onRoomJoined;

  @override
  State<EmptyPocketScreen> createState() => _EmptyPocketScreenState();
}

class _EmptyPocketScreenState extends State<EmptyPocketScreen> {
  final _users = UserRepository();
  final _requests = RequestRepository();

  PokiUser? _me;
  StreamSubscription<PokiUser>? _meSub;
  StreamSubscription<List<KnockRequest>>? _requestSub;

  final Set<String> _seenRequestIds = {};
  bool _dialogOpen = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _load();
    _meSub = _users.watchMe().listen(_onMe);
    _requestSub = _requests.watchIncoming().listen(_onIncoming);
  }

  @override
  void dispose() {
    _meSub?.cancel();
    _requestSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await _users.fetchMe();
      _onMe(me);
    } catch (_) {
      _showSnack('Profil yüklenemedi, tekrar dener misin?');
    }
  }

  void _onMe(PokiUser me) {
    if (!mounted) return;
    setState(() => _me = me);
    final roomId = me.currentRoomId;
    if (roomId != null && !_navigated) {
      _navigated = true;
      widget.onRoomJoined(roomId);
    }
  }

  Future<void> _onIncoming(List<KnockRequest> list) async {
    if (_dialogOpen || !mounted) return;
    final next = list.where((r) => !_seenRequestIds.contains(r.id)).firstOrNull;
    if (next == null) return;

    _seenRequestIds.add(next.id);
    _dialogOpen = true;
    final accepted = await KnockDialog.show(context, next);
    _dialogOpen = false;
    if (accepted == null) return;

    try {
      if (accepted) {
        final roomId = await _requests.accept(next.id);
        if (mounted && !_navigated) {
          _navigated = true;
          widget.onRoomJoined(roomId);
        }
      } else {
        await _requests.reject(next.id);
      }
    } on PokiException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _editCode() async {
    final me = _me;
    if (me == null) return;
    final updated = await EditPokiCodeSheet.show(
      context,
      currentTag: me.customTag,
      repository: _users,
    );
    if (updated != null && mounted) {
      setState(() => _me = updated);
      _showSnack('Yeni PokiCode\'un hazır 🐱');
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final me = _me;

    return Scaffold(
      body: SafeArea(
        child: me == null
            ? const Center(
                child: CircularProgressIndicator(color: PokiColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: ActivityBellButton(),
                    ),
                    const PocketHeader(),
                    const SizedBox(height: 20),
                    Text('Cebin şu an boş', style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Kodunu paylaş ya da birinin cebine tıklat.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    PokiCodeCard(code: me.customTag, onEdit: _editCode),
                    const SizedBox(height: 16),
                    KnockFormCard(repository: _requests),
                  ],
                ),
              ),
      ),
    );
  }
}
