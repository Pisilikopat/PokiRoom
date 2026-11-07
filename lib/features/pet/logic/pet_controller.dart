// lib/features/pet/logic/pet_controller.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_event.dart';
import '../models/pet_state.dart';
import 'pet_math.dart';
import 'pet_sync.dart';
import 'pet_vibrator.dart';

class PetController extends ChangeNotifier {
  PetController({
    required this.roomId,
    required this.myId,
    this.myNickname = 'Sen',
    this.partnerNickname = 'Partnerin',
  }) {
    _init();
  }

  final String roomId;
  final String myId;
  String myNickname;
  String partnerNickname;
  final Map<String, String> _userNicknames = {};

  PetState? _state;
  PetState? get state => _state;

  PetStats _stats = const PetStats(hunger: 70, affection: 70, energy: 80);
  PetStats get stats => _stats;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Anlık yerel animasyon durumları
  bool _isGrooming = false;
  bool get isGrooming => _isGrooming;

  bool _isMeowing = false;
  bool get isMeowing => _isMeowing;

  String? _speechBubble;
  String? get speechBubble => _speechBubble;

  // Efekt tetikleyici sayaçları (EffectsLayer dinler)
  int _heartBurstCount = 0;
  int get heartBurstCount => _heartBurstCount;

  int _sparkleCount = 0;
  int get sparkleCount => _sparkleCount;

  double _actionProgress = 0.0;
  double get actionProgress => _actionProgress;

  List<PetEvent> _history = [];
  List<PetEvent> get history => _history;
  bool _historyLoading = false;
  bool get historyLoading => _historyLoading;

  PetSync? _sync;
  Timer? _ticker;
  Timer? _groomTimer;
  Timer? _meowTimer;
  Timer? _speechBubbleTimer;
  Timer? _actionSafetyTimer;
  bool _disposed = false;
  bool _isActionFinishing = false;
  final math.Random _random = math.Random();

  void _init() {
    _sync = PetSync(
      roomId: roomId,
      myId: myId,
      onRemoteUpdate: _onRemoteState,
      onEffectReceived: (effect, fromId) => _onRemoteEffect(effect),
    );

    _fetchPet();
    _fetchUserNicknames();
    _startTicker();
    _scheduleAutonomousGroom();
    _scheduleAutonomousMeow();
  }

  Future<void> _fetchUserNicknames() async {
    try {
      final client = Supabase.instance.client;
      final roomRes = await client
          .from('rooms')
          .select('user1_id, user2_id')
          .eq('id', roomId)
          .maybeSingle();

      if (roomRes != null) {
        final u1 = roomRes['user1_id'] as String?;
        final u2 = roomRes['user2_id'] as String?;
        final ids = [u1, u2].whereType<String>().toList();
        if (ids.isNotEmpty) {
          final usersRes = await client
              .from('poki_users')
              .select('id, nickname')
              .inFilter('id', ids);

          for (final u in usersRes) {
            final uid = u['id'] as String;
            final nick = (u['nickname'] as String?)?.trim();
            if (nick != null && nick.isNotEmpty) {
              _userNicknames[uid] = nick;
              if (uid == myId) {
                myNickname = nick;
              } else {
                partnerNickname = nick;
              }
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPet() async {
    try {
      _loading = true;
      notifyListeners();

      final client = Supabase.instance.client;
      // 1) Atomik RPC dene
      try {
        final res = await client.rpc('pet_get_or_create', params: {'p_room_id': roomId});
        if (res != null && res is Map) {
          _state = PetState.fromMap(res.cast<String, dynamic>());
        }
      } catch (_) {
        // Fallback: doğrudan select dene
        final data = await client
            .from('room_pets')
            .select()
            .eq('room_id', roomId)
            .maybeSingle();

        if (data != null) {
          _state = PetState.fromMap(data);
        } else {
          // İlk kullanımda satır oluştur
          final inserted = await client.from('room_pets').insert({
            'room_id': roomId,
            'pet_name': 'Mırnav',
            'hunger': 70,
            'affection': 70,
            'energy': 80,
            'stats_updated_at': DateTime.now().toIso8601String(),
          }).select().single();
          _state = PetState.fromMap(inserted);
        }
      }

      _error = null;
    } catch (e) {
      _error = 'Kedi durumu yüklenemedi: $e';
    } finally {
      _loading = false;
      _updateStats();
      notifyListeners();
    }
  }

  Future<List<PetEvent>> fetchHistory() async {
    try {
      _historyLoading = true;
      notifyListeners();

      final client = Supabase.instance.client;
      final res = await client
          .from('pet_events')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(50);

      if (res is List) {
        _history = res
            .map((e) => PetEvent.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      return _history;
    } catch (e) {
      return _history;
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed) return;
      _updateStats();
      _updateActionProgress();
    });
  }

  void _updateStats() {
    final s = _state;
    if (s == null) return;
    final current = PetMath.computeStats(s, DateTime.now());
    if (current.hunger != _stats.hunger ||
        current.affection != _stats.affection ||
        current.energy != _stats.energy) {
      _stats = current;
      notifyListeners();
    }
  }

  void _updateActionProgress() {
    final s = _state;
    if (s == null || s.currentAction == PetActionKind.idle) {
      if (_actionProgress != 0.0) {
        _actionProgress = 0.0;
        notifyListeners();
      }
      return;
    }

    final end = s.actionEndsAt;
    if (end == null) {
      _finishAction();
      return;
    }

    final now = DateTime.now();
    final remainingMs = end.difference(now).inMilliseconds;

    if (remainingMs <= 0) {
      _actionProgress = 0.0;
      notifyListeners();
      _finishAction();
    } else {
      final totalMs = 3000.0;
      final elapsed = totalMs - remainingMs;
      _actionProgress = (elapsed / totalMs).clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void _onRemoteState(PetState newState) {
    _state = newState;
    _updateStats();
    notifyListeners();
  }

  void _onRemoteEffect(String effect) {
    if (effect == 'hearts') {
      PetVibrator.pet();
      _triggerHearts();
    } else if (effect == 'food') {
      PetVibrator.feed();
      _triggerSparkles();
    } else if (effect == 'meow') {
      _showBubble('Miyav~ 🐾');
    } else if (effect == 'wake') {
      PetVibrator.wake();
      _showBubble('Miyav~ ☀️');
    }
  }

  // ------------------------------------------------------------- Eylemler

  Future<void> feed() async {
    final s = _state;
    if (s == null || s.isSleeping || s.currentAction != PetActionKind.idle) return;

    try {
      PetVibrator.feed();
      _triggerSparkles();
      _sync?.sendEffect('food');

      final endsAt = DateTime.now().add(const Duration(seconds: 3));
      _state = s.copyWith(
        currentAction: PetActionKind.eating,
        actionEndsAt: endsAt,
        lastActionBy: myId,
        lastActionType: 'eating',
        lastActionAt: DateTime.now(),
      );
      _actionProgress = 0.01;
      notifyListeners();

      _actionSafetyTimer?.cancel();
      _actionSafetyTimer = Timer(const Duration(milliseconds: 3200), () {
        if (_disposed) return;
        if (_state?.currentAction == PetActionKind.eating) {
          _finishAction();
        }
      });

      final client = Supabase.instance.client;
      await client.rpc('pet_start_action', params: {
        'p_room_id': roomId,
        'p_kind': 'eating',
      });
    } catch (_) {}
  }

  Future<void> pet() async {
    final s = _state;
    if (s == null || s.isSleeping || s.currentAction != PetActionKind.idle) return;

    try {
      PetVibrator.pet();
      _triggerHearts();
      _sync?.sendEffect('hearts');

      final endsAt = DateTime.now().add(const Duration(seconds: 3));
      _state = s.copyWith(
        currentAction: PetActionKind.petting,
        actionEndsAt: endsAt,
        lastActionBy: myId,
        lastActionType: 'petting',
        lastActionAt: DateTime.now(),
      );
      _actionProgress = 0.01;
      notifyListeners();

      _actionSafetyTimer?.cancel();
      _actionSafetyTimer = Timer(const Duration(milliseconds: 3200), () {
        if (_disposed) return;
        if (_state?.currentAction == PetActionKind.petting) {
          _finishAction();
        }
      });

      final client = Supabase.instance.client;
      await client.rpc('pet_start_action', params: {
        'p_room_id': roomId,
        'p_kind': 'petting',
      });
    } catch (_) {}
  }

  Future<void> _finishAction() async {
    if (_isActionFinishing) return;
    _isActionFinishing = true;
    _actionSafetyTimer?.cancel();

    final s = _state;
    if (s == null || s.currentAction == PetActionKind.idle) {
      _isActionFinishing = false;
      return;
    }

    final action = s.currentAction;
    int targetHunger = s.hunger;
    int targetAffection = s.affection;

    if (action == PetActionKind.eating) {
      targetHunger = (targetHunger + 25).clamp(0, 100);
    } else if (action == PetActionKind.petting) {
      targetAffection = (targetAffection + 20).clamp(0, 100);
    }

    _state = s.copyWith(
      hunger: targetHunger,
      affection: targetAffection,
      currentAction: PetActionKind.idle,
      actionEndsAt: null,
      statsUpdatedAt: DateTime.now(),
    );
    _actionProgress = 0.0;
    _updateStats();
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      bool rpcSuccess = false;
      try {
        final res = await client.rpc('pet_finish_action', params: {'p_room_id': roomId});
        if (res != null && res is Map) {
          final serverState = PetState.fromMap(res.cast<String, dynamic>());
          if (serverState.currentAction == PetActionKind.idle) {
            _state = serverState;
            rpcSuccess = true;
          }
        }
      } catch (_) {}

      if (!rpcSuccess) {
        await client.from('room_pets').update({
          'hunger': targetHunger,
          'affection': targetAffection,
          'current_action': 'idle',
          'action_ends_at': null,
          'stats_updated_at': DateTime.now().toIso8601String(),
        }).eq('room_id', roomId);

        try {
          await client.from('pet_events').insert({
            'room_id': roomId,
            'actor_id': myId,
            'type': action == PetActionKind.eating ? 'feed' : 'pet',
          });
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _isActionFinishing = false;
      _updateStats();
      notifyListeners();
    }
  }

  Future<void> sleep(String? note) async {
    final s = _state;
    if (s == null || s.isSleeping) return;

    try {
      final sanitized = note != null && note.trim().isNotEmpty
          ? note.trim().substring(0, math.min(120, note.trim().length))
          : null;

      _state = s.copyWith(
        isSleeping: true,
        sleepNote: sanitized,
        sleepStartedAt: DateTime.now(),
        currentAction: PetActionKind.idle,
        actionEndsAt: null,
        lastActionBy: myId,
        lastActionType: 'sleep',
        lastActionAt: DateTime.now(),
      );
      notifyListeners();

      final client = Supabase.instance.client;

      try {
        await client.rpc('pet_sleep', params: {
          'p_room_id': roomId,
          'p_note': sanitized,
        });
      } catch (_) {}

      // Doğrudan veritabanı update'i: 120 karaktere kadar olan notun
      // eski RPC sürümlerinde bile kesilmeden eksiksiz kaydedilmesini garanti eder!
      await client.from('room_pets').update({
        'is_sleeping': true,
        'sleep_note': sanitized,
        'sleep_started_at': DateTime.now().toIso8601String(),
        'current_action': 'idle',
        'action_ends_at': null,
        'last_action_by': myId,
        'last_action_type': 'sleep',
        'last_action_at': DateTime.now().toIso8601String(),
      }).eq('room_id', roomId);

      try {
        await client.from('pet_events').insert({
          'room_id': roomId,
          'actor_id': myId,
          'type': 'sleep',
          'note': sanitized,
        });
      } catch (_) {}
    } catch (e) {
      _fetchPet();
    }
  }

  Future<void> wake() async {
    final s = _state;
    if (s == null || !s.isSleeping) return;

    try {
      PetVibrator.wake();
      _showBubble('Miyav~ ☀️');
      _sync?.sendEffect('wake');

      _state = s.copyWith(
        isSleeping: false,
        sleepNote: null,
        sleepStartedAt: null,
        lastActionBy: myId,
        lastActionType: 'wake',
        lastActionAt: DateTime.now(),
      );
      notifyListeners();

      final client = Supabase.instance.client;
      try {
        await client.rpc('pet_wake', params: {'p_room_id': roomId});
      } catch (_) {}

      await client.from('room_pets').update({
        'is_sleeping': false,
        'sleep_note': null,
        'sleep_started_at': null,
        'last_action_by': myId,
        'last_action_type': 'wake',
        'last_action_at': DateTime.now().toIso8601String(),
      }).eq('room_id', roomId);

      try {
        await client.from('pet_events').insert({
          'room_id': roomId,
          'actor_id': myId,
          'type': 'wake',
        });
      } catch (_) {}
    } catch (e) {
      _fetchPet();
    }
  }

  // ------------------------------------------------------------- Otonom Efektler

  void _triggerHearts() {
    _heartBurstCount++;
    notifyListeners();
  }

  void _triggerSparkles() {
    _sparkleCount++;
    notifyListeners();
  }

    void showCustomBubble(String text) {
    _showBubble(text);
    PetVibrator.pet();
  }

  void _showBubble(String text) {
    _speechBubble = text;
    notifyListeners();
    _speechBubbleTimer?.cancel();
    _speechBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (_disposed) return;
      _speechBubble = null;
      notifyListeners();
    });
  }

  void _scheduleAutonomousGroom() {
    final delaySeconds = 12 + _random.nextInt(6); // ~15s (±3s)
    _groomTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_disposed) return;
      final s = _state;
      if (s != null && !s.isSleeping && s.currentAction == PetActionKind.idle) {
        _isGrooming = true;
        notifyListeners();
        Timer(const Duration(milliseconds: 2500), () {
          if (_disposed) return;
          _isGrooming = false;
          notifyListeners();
        });
      }
      _scheduleAutonomousGroom();
    });
  }

  void _scheduleAutonomousMeow() {
    final delaySeconds = 20 + _random.nextInt(10); // ~25s
    _meowTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_disposed) return;
      final s = _state;
      if (s != null && !s.isSleeping && s.currentAction == PetActionKind.idle) {
        _isMeowing = true;
        _showBubble('Miyav~ 🐾');
        notifyListeners();
        Timer(const Duration(milliseconds: 2000), () {
          if (_disposed) return;
          _isMeowing = false;
          notifyListeners();
        });
      }
      _scheduleAutonomousMeow();
    });
  }

  String get lastActionFormatted {
    final s = _state;
    if (s == null || s.lastActionAt == null || s.lastActionType == null) {
      return 'Kediyle henüz bir işlem yapılmadı 🐾';
    }

    final isMe = s.lastActionBy == myId;
    final actor = isMe
        ? (myNickname.isNotEmpty && myNickname != 'Sen' ? '$myNickname (Sen)' : 'Sen')
        : (_userNicknames[s.lastActionBy] ?? partnerNickname);
    final type = s.lastActionType;
    String actionName = 'ilgilendi';
    if (type == 'eating' || type == 'feed') actionName = 'onu besledi 🍖';
    if (type == 'petting' || type == 'pet') actionName = 'onu sevdi 🤍';
    if (type == 'sleep') actionName = 'onu uyuttu 💤';
    if (type == 'wake') actionName = 'onu uyandırdı ☀️';

    final diff = DateTime.now().difference(s.lastActionAt!);
    String timeAgo = 'az önce';
    if (diff.inMinutes >= 1) timeAgo = '${diff.inMinutes} dk önce';
    if (diff.inHours >= 1) timeAgo = '${diff.inHours} sa önce';
    if (diff.inDays >= 1) timeAgo = '${diff.inDays} gün önce';

    return 'Son işlem: $actor $timeAgo $actionName';
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _groomTimer?.cancel();
    _meowTimer?.cancel();
    _speechBubbleTimer?.cancel();
    _actionSafetyTimer?.cancel();
    _sync?.dispose();
    super.dispose();
  }
}
