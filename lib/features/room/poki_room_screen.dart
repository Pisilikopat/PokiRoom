import '../canvas/poki_canvas_screen.dart';
// lib/features/room/poki_room_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/poki_exception.dart';
import '../../core/theme/poki_theme.dart';
import '../../data/models/poki_message.dart';
import '../../data/models/poki_notification.dart';
import '../../data/models/poki_room.dart';
import '../../data/models/poki_user.dart';
import '../../data/repositories/memory_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/voice_repository.dart';
import 'screens/voice_call_screen.dart';
import 'services/call_signaling_service.dart';
import 'services/voice_recorder_service.dart';
import '../../data/services/game_lobby_service.dart';
import '../../data/services/room_presence.dart';
import '../arcade/games_hub_screen.dart';
import '../memories/memories_screen.dart';
import '../puzzle/puzzle_game_screen.dart';
import '../puzzle/puzzle_setup_screen.dart';
import '../quiz/logic/quiz_deck.dart';
import '../quiz/quiz_game_screen.dart';
import '../quiz/quiz_lobby_screen.dart';
import '../workshop/doodle_studio_screen.dart';
import '../workshop/live_doodle_screen.dart';
import '../workshop/widgets/sticker_picker_sheet.dart';
import 'widgets/bite_overlay.dart';
import 'widgets/chat_search_bar.dart';
import 'widgets/foggy_compose_sheet.dart';
import 'widgets/hearts_burst.dart';
import 'widgets/incoming_call_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/mini_call_overlay.dart';
import 'widgets/poke_toast.dart';
import 'widgets/poki_poke_menu.dart';
import 'widgets/room_header.dart';
import 'widgets/typing_paws.dart';

/// 1'e 1 kilitli PokiRoom ana sohbet ekranı.
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
  final _memories = MemoryRepository();

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  PokiUser? _me;
  PokiUser? _partner;
  PokiRoom? _room;
  List<PokiMessage> _list = const [];
  RoomPresence? _presence;

  // Sayfalama (Pagination) durumu
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  List<PokiMessage> _streamMessages = const [];
  final List<PokiMessage> _olderMessages = [];
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;

  // Arama & Filtreleme durumu
  bool _isSearchActive = false;
  bool _isSearchingRunning = false;
  String _selectedSearchFilter = 'all';
  List<PokiMessage>? _searchResults;
  int _searchMatchIndex = -1;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  Timer? _searchDebounceTimer;
  final Map<String, GlobalKey> _messageKeys = {};

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _foreground = true;
  bool _loading = true;
  String? _error;

  // Poki-Poke / bildirim durumu
  int? _burstId;
  int _burstCounter = 0;
  BiteEvent? _incomingBite;
  int? _biteBurstId;
  int _biteCounter = 0;
  String? _toast;
  VoidCallback? _toastOnTap;
  Timer? _toastTimer;
  DateTime? _lastPokeSent;
  PokiMessage? _replyingTo;
  final FocusNode _inputFocusNode = FocusNode();

  // ───────────── Sesli Arama ─────────────
  CallSignalingService? _callSignaling;
  StreamSubscription<IncomingCallEvent>? _incomingCallSub;
  StreamSubscription<CallEndReason>? _callEndedSub;
  bool _callScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _init();
  }

  void _onPresenceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    _highlightTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _inputFocusNode.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    _incomingCallSub?.cancel();
    _callEndedSub?.cancel();
    _callSignaling?.dispose();
    _presence?.removeListener(_onPresenceChanged);
    _presence?.setActivity(PokiActivity.inApp);
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

      final presence = RoomPresence.ensure(
        roomId: widget.roomId,
        myId: _myId,
        partnerId: partnerId,
      );
      presence.addListener(_onPresenceChanged);
      presence.join();
      presence.setActivity(PokiActivity.chatting);

      // Sesli arama servisini başlat
      final signaling = CallSignalingService(
        roomId: widget.roomId,
        myId: _myId,
        partnerId: partnerId,
      );
      await signaling.init();

      _incomingCallSub = signaling.onIncomingCall.listen(_onIncomingCall);
      _callEndedSub = signaling.onCallEnded.listen(_onCallEnded);

      setState(() {
        _room = room;
        _me = me;
        _partner = partner;
        _presence = presence;
        _callSignaling = signaling;
        _loading = false;
      });

      _listen(presence.pokes, _onPoke);
      _listen(presence.bites, _onBite);
      _listen(presence.doodleInvites, _onDoodleInvite);
      GameLobbyService.instance.init(widget.roomId);
      _listen(GameLobbyService.instance.onQuizInvite, _onQuizInvite);
      _listen(GameLobbyService.instance.onPuzzleInvite, _onPuzzleInvite);
      _listen(GameLobbyService.instance.onCanvasInvite, _onCanvasInvite);
      _listen(_users.watchMe(), (u) => _setState(() => _me = u));
      _listen(_users.watchUser(partnerId), (u) => _setState(() => _partner = u));
      _listen(_rooms.watchRoom(widget.roomId), (r) => _setState(() => _room = r));
      _listen(_messages.watchMessages(widget.roomId, limit: 40), (list) {
        _streamMessages = list;
        _rebuildMergedList();
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

  void _rebuildMergedList() {
    final map = <String, PokiMessage>{};
    for (final m in _streamMessages) {
      map[m.id] = m;
    }
    for (final m in _olderMessages) {
      map.putIfAbsent(m.id, () => m);
    }
    final merged = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setState(() => _list = merged);
    _maybeMarkRead();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200 && !_loadingOlder && _hasMoreOlder && _list.isNotEmpty) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingOlder || !_hasMoreOlder || _list.isEmpty) return;
    setState(() {
      _loadingOlder = true;
    });

    try {
      final oldest = _list.last;
      final older = await _messages.fetchOlderMessages(
        widget.roomId,
        before: oldest.createdAt,
        limit: 40,
      );

      if (!mounted) return;
      setState(() {
        if (older.isEmpty || older.length < 40) {
          _hasMoreOlder = false;
        }
        _olderMessages.addAll(older);
        _rebuildMergedList();
        _loadingOlder = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingOlder = false;
        });
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchResults = null;
        _searchMatchIndex = -1;
        _highlightedMessageId = null;
        _highlightTimer?.cancel();
      }
    });
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 320), () {
      _runSearch();
    });
  }

  void _onSearchFilterChanged(String filter) {
    setState(() {
      _selectedSearchFilter = filter;
    });
    _runSearch();
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty && _selectedSearchFilter == 'all') {
      setState(() {
        _searchResults = null;
        _searchMatchIndex = -1;
        _isSearchingRunning = false;
      });
      return;
    }

    setState(() {
      _isSearchingRunning = true;
    });

    try {
      final results = await _messages.searchMessages(
        widget.roomId,
        query: q.isEmpty ? null : q,
        messageType:
            _selectedSearchFilter == 'all' ? null : _selectedSearchFilter,
        limit: 80,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searchMatchIndex = results.isNotEmpty ? 0 : -1;
        _isSearchingRunning = false;
      });

      if (results.isNotEmpty) {
        _jumpToMessage(results.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchingRunning = false;
        });
      }
    }
  }

  void _onPrevMatch() {
    if (_searchResults == null || _searchResults!.isEmpty) return;
    setState(() {
      _searchMatchIndex =
          (_searchMatchIndex - 1 + _searchResults!.length) % _searchResults!.length;
    });
    _jumpToMessage(_searchResults![_searchMatchIndex]);
  }

  void _onNextMatch() {
    if (_searchResults == null || _searchResults!.isEmpty) return;
    setState(() {
      _searchMatchIndex = (_searchMatchIndex + 1) % _searchResults!.length;
    });
    _jumpToMessage(_searchResults![_searchMatchIndex]);
  }

  void _jumpToMessage(PokiMessage target) => _scrollToMessage(target);

  void _onReplyTap(String replyMessageId) {
    if (replyMessageId.isEmpty) return;
    _scrollToMessageId(replyMessageId);
  }

  Future<bool> _ensureMessageLoaded(String messageId) async {
    if (_list.any((m) => m.id == messageId)) return true;

    // Hedef mesaj yüklenene kadar eski mesajları parça parça çek
    int batches = 6;
    while (!_list.any((m) => m.id == messageId) && _hasMoreOlder && batches > 0) {
      batches--;
      final oldest = _list.isNotEmpty ? _list.last : null;
      if (oldest == null) break;

      final batch = await _messages.fetchOlderMessages(
        widget.roomId,
        before: oldest.createdAt,
        limit: 40,
      );
      if (!mounted) return false;
      if (batch.isEmpty) {
        _hasMoreOlder = false;
        break;
      }
      if (batch.length < 40) {
        _hasMoreOlder = false;
      }
      _olderMessages.addAll(batch);
      _rebuildMergedList();
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // Listede hala yoksa tekil olarak çek
    if (!_list.any((m) => m.id == messageId)) {
      final single = await _messages.fetchSingleMessage(messageId);
      if (!mounted) return false;
      if (single != null) {
        _olderMessages.add(single);
        _rebuildMergedList();
      }
    }

    return _list.any((m) => m.id == messageId);
  }

  Future<void> _scrollToMessageId(String messageId) async {
    final existing = _list.where((m) => m.id == messageId).firstOrNull;
    if (existing != null) {
      await _scrollToMessage(existing);
      return;
    }

    _showToast('🐾 Yanıtlanan mesaj aranıyor...');
    final loaded = await _ensureMessageLoaded(messageId);
    if (!loaded || !mounted) {
      if (mounted) {
        _showToast('Yanıtlanan mesaj bulunamadı veya silinmiş 🐾');
      }
      return;
    }

    final target = _list.firstWhere((m) => m.id == messageId);
    await _scrollToMessage(target);
  }

  Future<void> _scrollToMessage(PokiMessage target) async {
    if (!_list.any((m) => m.id == target.id)) {
      final loaded = await _ensureMessageLoaded(target.id);
      if (!loaded || !mounted) return;
    }

    final idx = _list.indexWhere((m) => m.id == target.id);
    if (idx == -1 || !_scrollController.hasClients) return;

    final key = _messageKeys.putIfAbsent(target.id, () => GlobalKey());

    // 1. Zaten ekranda / önbellekte varsa akıcı şekilde ortaya hizala
    if (key.currentContext != null) {
      await Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // 2. Uzaktaysa gerçek ortalama yüksekliği hesaplayıp oraya sıçra
      final max = _scrollController.position.maxScrollExtent;
      final avgHeight = max > 0 && _list.length > 1
          ? (max / (_list.length - 1)).clamp(65.0, 180.0)
          : 90.0;
      final targetOffset = (idx * avgHeight).clamp(0.0, max);
      _scrollController.jumpTo(targetOffset);

      // Çerçevenin oluşturulmasını bekle
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      final ctx = _messageKeys[target.id]?.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        // İkincil hassas hizalama
        final newMax = _scrollController.position.maxScrollExtent;
        final newAvg = newMax > 0 && _list.length > 1 ? newMax / (_list.length - 1) : avgHeight;
        _scrollController.jumpTo((idx * newAvg).clamp(0.0, newMax));
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted && _messageKeys[target.id]?.currentContext != null) {
          await Scrollable.ensureVisible(
            _messageKeys[target.id]!.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }

    // 3. Mesajı parlayan turuncu çerçeveyle vurgula
    if (mounted) {
      setState(() {
        _highlightedMessageId = target.id;
      });
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted && _highlightedMessageId == target.id) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ---------------------------------------------------------------- okundu

  void _maybeMarkRead() {
    if (!_foreground) return;
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

  // ------------------------------------------------------------ bildirimler

  void _showToast(
    String text, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    _toastTimer?.cancel();
    setState(() {
      _toast = text;
      _toastOnTap = onTap;
    });
    _toastTimer = Timer(duration, _hideToast);
  }

  void _hideToast() {
    if (!mounted) return;
    setState(() {
      _toast = null;
      _toastOnTap = null;
    });
  }

  void _onPoke(PokeEvent event) {
    HapticFeedback.mediumImpact();
    setState(() => _burstId = ++_burstCounter);
    _showToast('Pıt! 🐾 ${event.nickname} şu an seni düşünüyor');
  }

  void _onBite(BiteEvent event) {
    HapticFeedback.heavyImpact();
    setState(() {
      _incomingBite = event;
      _biteBurstId = ++_biteCounter;
    });
    final title = event.title ?? 'Tatlı Isırık';
    final emoji = event.emoji ?? '🦷';
    _showToast('$emoji ${event.nickname} seni ısırdı: $title! 🩹');
  }

  void _onDoodleInvite(PokeEvent event) {
    HapticFeedback.mediumImpact();
    _showToast(
      '🎨 ${event.nickname} birlikte çizmeye çağırıyor • Katıl',
      duration: const Duration(seconds: 12),
      onTap: () {
        _hideToast();
        _openLive(invite: false);
      },
    );
  }

  void _onQuizInvite(QuizInvite invite) {
    HapticFeedback.mediumImpact();
    _showToast(
      '🐾 ${invite.hostNickname} seni Poki Quiz\'e çağırıyor 💖 Katıl',
      duration: const Duration(seconds: 15),
      onTap: () {
        _hideToast();
        GameLobbyService.instance.clearInvite();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QuizGameScreen(
              roomId: widget.roomId,
              config: invite.config,
              deck: QuizDeck(invite.questions),
              isHost: false,
            ),
          ),
        );
      },
    );
  }

  void _onCanvasInvite(CanvasInvite invite) {
    HapticFeedback.mediumImpact();
    _showToast(
      '🐾 ${invite.hostNickname} seni İki Pati Bir Tuval\'e çağırıyor 🎨 Katıl',
      duration: const Duration(seconds: 15),
      onTap: () {
        _hideToast();
        GameLobbyService.instance.clearCanvasInvite();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PokiCanvasScreen(
              roomId: widget.roomId,
              isCoop: true,
            ),
          ),
        );
      },
    );
  }

  void _onPuzzleInvite(PuzzleInvite invite) {
    HapticFeedback.mediumImpact();
    _showToast(
      '🧩 ${invite.hostNickname} seni Poki Puzzle\'a çağırıyor 💖 Katıl',
      duration: const Duration(seconds: 15),
      onTap: () {
        _hideToast();
        GameLobbyService.instance.clearPuzzleInvite();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PuzzleGameScreen(
              roomId: widget.roomId,
              config: invite.config,
            ),
          ),
        );
      },
    );
  }

  void _handleQuickAction(String actionType) {
    HapticFeedback.mediumImpact();
    if (actionType == 'doodle') {
      _openLive(invite: false);
    } else if (actionType == 'quiz') {
      final invite = GameLobbyService.instance.activeQuizInvite;
      if (invite != null) {
        GameLobbyService.instance.clearQuizInvite();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QuizGameScreen(
              roomId: widget.roomId,
              config: invite.config,
              deck: QuizDeck(invite.questions),
              isHost: false,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QuizLobbyScreen(roomId: widget.roomId),
          ),
        );
      }
    } else if (actionType == 'puzzle') {
      final invite = GameLobbyService.instance.activePuzzleInvite;
      if (invite != null) {
        GameLobbyService.instance.clearPuzzleInvite();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PuzzleGameScreen(
              roomId: widget.roomId,
              config: invite.config,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GamesHubScreen(roomId: widget.roomId),
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------ Poki-Poke

  Future<void> _openMenu() async {
    final action = await PokiPokeMenu.show(context);
    if (!mounted) return;
    switch (action) {
      case PokiPokeAction.thinkingOfYou:
        await _sendPoke();
      case PokiPokeAction.sweetBite:
        await _sendBite();
      case PokiPokeAction.voiceCall:
        await _startVoiceCall();
      case PokiPokeAction.foggyMessage:
        await _composeFoggy();
      case PokiPokeAction.sticker:
        await _openStickerPicker();
      case PokiPokeAction.liveDoodle:
        _openLive();
      case PokiPokeAction.workshop:
        _openWorkshop();
      case PokiPokeAction.memories:
        _openMemories();
      case PokiPokeAction.arcade:
        _openArcade();
      case null:
        break;
    }
  }

  void _openArcade() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamesHubScreen(roomId: widget.roomId),
      ),
    );
  }

  void _openPuzzle() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleSetupScreen(roomId: widget.roomId),
      ),
    );
  }

  void _openQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizLobbyScreen(roomId: widget.roomId),
      ),
    );
  }

  Future<void> _sendPoke() async {
    final now = DateTime.now();
    final last = _lastPokeSent;
    if (last != null && now.difference(last) < _pokeCooldown) {
      _snack('Biraz yavaş, kedi nefes alsın 🐾');
      return;
    }
    _lastPokeSent = now;
    try {
      await _presence?.sendPoke(_me?.nickname ?? 'Biri');
      NotificationRepository.instance.notifyPartner(
        roomId: widget.roomId,
        type: NotificationType.poke,
      );
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

  Future<void> _sendBite({String? spot}) async {
    final now = DateTime.now();
    final last = _lastPokeSent;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 1200)) {
      _snack('Biraz yavaş, kedi nefes alsın 🐾');
      return;
    }
    _lastPokeSent = now;
    final scenario = PokiBiteScenario.getRandom();
    final finalSpot = spot ?? scenario.spot;
    final myNick = _me?.nickname ?? 'Biri';
    final partnerNick = _partner?.nickname ?? 'Karşı taraf';
    try {
      await _presence?.sendBite(
        myNick,
        spot: finalSpot,
        title: scenario.title,
        phrase: scenario.phrase,
        emoji: scenario.emoji,
      );
      await _messages.sendBite(
        widget.roomId,
        spot: finalSpot,
        bittenName: partnerNick,
        senderName: myNick,
        title: scenario.title,
        phrase: scenario.phrase,
        emoji: scenario.emoji,
      );
      NotificationRepository.instance.notifyPartner(
        roomId: widget.roomId,
        type: NotificationType.poke,
      );
      _snack('${scenario.emoji} ${scenario.title} yapıldı! 🐾');
    } catch (_) {
      _snack('Isırık gönderilemedi, tekrar dener misin?');
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

  // ----------------------------------------------- Atölye / Anılar / Canlı

  Future<void> _openStickerPicker() {
    return StickerPickerSheet.show(
      context,
      roomId: widget.roomId,
      onOpenWorkshop: _openWorkshop,
      onPick: (sticker) async {
        try {
          await _messages.sendSticker(widget.roomId, sticker.id);
        } on PokiException catch (e) {
          _snack(e.message);
        }
      },
    );
  }

  Future<void> _inviteToDoodle() async {
    try {
      await _presence?.sendDoodleInvite(_me?.nickname ?? 'Biri');
    } catch (_) {}
  }

  void _openWorkshop() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DoodleStudioScreen(
          roomId: widget.roomId,
          onInvitePartner: _inviteToDoodle,
        ),
      ),
    );
  }

  void _openLive({bool invite = true}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveDoodleScreen(
          roomId: widget.roomId,
          onInvitePartner: invite ? _inviteToDoodle : null,
        ),
      ),
    );
  }

  void _openMemories() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoriesScreen(roomId: widget.roomId),
      ),
    );
  }

  Future<void> _onMessageLongPress(PokiMessage m, bool mine) async {
    final pinnable = m.type == 'text' || m.type == 'sticker' || m.type == 'foggy';
    final hidden = m.type == 'foggy' && !mine && !m.isRead;
    if (!pinnable || hidden) return;

    final pin = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: ListTile(
            leading: const Icon(Icons.push_pin_rounded),
            title: const Text('Anılara İğnele'),
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ),
      ),
    );
    if (pin != true) return;
    try {
      await _memories.addFromMessage(m);
      _snack('Anılara iğnelendi 📌');
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  // ------------------------------------------------------------- mesajlar

  Future<void> _onFoggyRevealed(String messageId) async {
    try {
      await _messages.markMessageRead(messageId);
    } catch (_) {}
    NotificationRepository.instance.notifyPartner(
      roomId: widget.roomId,
      type: NotificationType.foggyRevealed,
    );
  }

  void _startReply(PokiMessage m) {
    setState(() => _replyingTo = m);
    _inputFocusNode.requestFocus();
  }

  PokiReplyInfo? get _currentReplyInfo {
    final m = _replyingTo;
    if (m == null) return null;
    final senderName =
        m.senderId == _myId ? 'Sen' : (_partner?.nickname ?? 'Partnerin');
    final snippet = m.displaySnippet;
    return PokiReplyInfo(
      messageId: m.id,
      senderNickname: senderName,
      snippet: snippet,
    );
  }

  Future<void> _send(String text) async {
    final replyInfo = _currentReplyInfo;
    setState(() => _replyingTo = null);

    try {
      await _messages.sendText(widget.roomId, text, reply: replyInfo);
    } on PokiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _sendVoice(VoiceRecordResult result) async {
    final replyInfo = _currentReplyInfo;
    setState(() => _replyingTo = null);

    try {
      final voiceRepo = VoiceRepository();
      final voiceData = await voiceRepo.prepareVoiceData(
        roomId: widget.roomId,
        bytes: result.bytes,
        durationMs: result.durationMs,
        waveform: result.waveform,
      );

      await _messages.sendVoice(widget.roomId, voiceData, reply: replyInfo);
    } on PokiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Sesli mesaj gönderilemedi 🐾');
    }
  }

  // ─────────────────────── SESLİ ARAMA ───────────────────────

  Future<void> _startVoiceCall() async {
    final signaling = _callSignaling;
    final partner = _partner;
    if (signaling == null || partner == null) return;

    if (signaling.state != CallState.idle) {
      _snack('Zaten bir arama devam ediyor 📞');
      return;
    }

    HapticFeedback.mediumImpact();
    await signaling.startCall();

    if (!mounted) return;
    _openCallScreen(signaling, partner);
  }

  void _onIncomingCall(IncomingCallEvent event) {
    final signaling = _callSignaling;
    final partner = _partner;
    if (signaling == null || partner == null || !mounted) return;

    HapticFeedback.heavyImpact();

    IncomingCallSheet.show(
      context,
      caller: partner,
      onAccept: () {
        Navigator.of(context).pop();
        signaling.acceptCall();
        _openCallScreen(signaling, partner);
      },
      onReject: () {
        Navigator.of(context).pop();
        signaling.rejectCall();
      },
    );
  }

  void _onCallEnded(CallEndReason reason) {
    if (!mounted) return;
    setState(() {
      _callScreenOpen = false;
    });

    switch (reason) {
      case CallEndReason.rejected:
        _showToast('Arama reddedildi 📵');
      case CallEndReason.noAnswer:
        _showToast('Cevap yok 📵');
      case CallEndReason.connectionLost:
        _showToast('Bağlantı kesildi ⚠️');
      case CallEndReason.ended:
        break;
    }
  }

  void _openCallScreen(CallSignalingService signaling, PokiUser partner) {
    setState(() => _callScreenOpen = true);
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => VoiceCallScreen(
          partner: partner,
          signaling: signaling,
          isCaller: signaling.isCaller,
        ),
      ),
    )
        .then((_) {
      setState(() => _callScreenOpen = false);
    });
  }

  // ─────────────────────────────────────────────────────────────

  Future<void> _confirmClosePocket() async {
    final partnerName = _partner?.nickname ?? 'karşı taraf';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cebi kapatalım mı?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '$partnerName ile olan mevcut odanız sonlandırılacak. Başka biriyle eşleşebilmek veya odayı sıfırlamak için bu gereklidir.\n\nEmin misin?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet, Cebi Kapat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _rooms.closeRoom();
      RoomPresence.current?.dispose();
      RoomPresence.current = null;
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
    final signaling = _callSignaling;
    final partner = _partner;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              RoomHeader(
                me: _me,
                partner: _partner,
                partnerOnline: presence?.partnerOnline ?? false,
                partnerActivity:
                    presence?.partnerActivity ?? PokiActivity.offline,
                streak: _room?.streakCount ?? 1,
                onClosePocket: _confirmClosePocket,
                onQuickAction: _handleQuickAction,
                onSearchTap: _toggleSearch,
                isSearching: _isSearchActive,
                onVoiceCallTap: _startVoiceCall,
                onBitePartner: () => _sendBite(),
                partnerHasBandage: presence?.partnerHasBandage ?? false,
                myHasBandage: presence?.myHasBandage ?? false,
                onBandageTap: () => presence?.healPartnerBandage(),
                onMyBandageTap: () => presence?.healMyBandage(),
              ),
              if (_isSearchActive)
                ChatSearchBar(
                  controller: _searchController,
                  selectedFilter: _selectedSearchFilter,
                  onFilterChanged: _onSearchFilterChanged,
                  onQueryChanged: _onSearchQueryChanged,
                  onClose: _toggleSearch,
                  totalMatches: _searchResults?.length ?? 0,
                  currentMatchIndex: _searchMatchIndex,
                  onPrevMatch: _onPrevMatch,
                  onNextMatch: _onNextMatch,
                  isLoading: _isSearchingRunning,
                ),
              Expanded(child: _buildMessages()),
              if (presence?.partnerTyping ?? false)
                TypingPaws(name: _partner?.nickname ?? 'Karşı taraf'),
              if (signaling != null &&
                  partner != null &&
                  !_callScreenOpen &&
                  signaling.state != CallState.idle &&
                  signaling.state != CallState.ringing)
                MiniCallOverlay(partner: partner, signaling: signaling),
              MessageInput(
                onSend: _send,
                onSendVoice: _sendVoice,
                onTypingChanged: (typing) => presence?.setTyping(typing),
                onOpenMenu: _openMenu,
                replyInfo: _currentReplyInfo,
                onCancelReply: () => setState(() => _replyingTo = null),
                focusNode: _inputFocusNode,
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
          if (_incomingBite != null && _biteBurstId != null)
            Positioned.fill(
              child: BiteOverlay(
                key: ValueKey('bite_$_biteBurstId'),
                senderName: _incomingBite!.nickname,
                spot: _incomingBite!.spot,
                title: _incomingBite!.title,
                phrase: _incomingBite!.phrase,
                emoji: _incomingBite!.emoji,
                onDone: () => _setState(() => _incomingBite = null),
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
                        child: PokeToast(text: _toast!, onTap: _toastOnTap),
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

    final showTopIndicator = _loadingOlder || !_hasMoreOlder;
    final totalCount = _list.length + (showTopIndicator ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      cacheExtent: 1500.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == _list.length) {
          if (_loadingOlder) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PokiColors.primaryButton,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🐾 Eski anılar getiriliyor...',
                    style: TextStyle(
                      fontSize: 12,
                      color: PokiColors.textOf(context).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          if (!_hasMoreOlder && _list.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'İkinizin ilk anısı burada başladı 🐾',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PokiColors.textOf(context).withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final m = _list[index];
        final mine = m.senderId == _myId;
        return MessageBubble(
          key: _messageKeys.putIfAbsent(m.id, () => GlobalKey()),
          message: m,
          isMine: mine,
          isHighlighted: m.id == _highlightedMessageId,
          onFoggyRevealed: () => _onFoggyRevealed(m.id),
          onLongPress: () => _onMessageLongPress(m, mine),
          onSwipeReply: _startReply,
          onReplyTap: _onReplyTap,
          onBiteBack: () => _sendBite(),
          partnerNickname: _partner?.nickname ?? 'Partnerin',
        );
      },
    );
  }
}
