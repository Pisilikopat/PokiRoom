// lib/features/pet/logic/pet_controller.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_state.dart';
import 'pet_math.dart';
import 'pet_sync.dart';

class PetController extends ChangeNotifier {
  PetController({
    required this.roomId,
    required this.myId,
    this.partnerNickname = 'Partnerin',
  }) {
    _init();
  }

  final String roomId;
  final String myId;
  final String partnerNickname;

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

  PetSync? _sync;
  Timer? _ticker;
  Timer? _groomTimer;
  Timer? _meowTimer;
  Timer? _speechBubbleTimer;
  bool _disposed = false;
  bool _isActionFinishing = false;
  final math.Random _random = math.Random();

  void _init() {
    _sync = PetSync(
      roomId: roomId,
      myId: myId,
      onRemoteUpdate: _onRemoteState,
      onEffectReceived: _onRemoteEffect,
    );

    _fetchPet();
    _startTicker();
    _scheduleAutonomousGroom();
    _scheduleAutonomousMeow();
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

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      _updateStats();
      _updateActionProgress();
    });
  }

  void _updateStats() {
    final s = _state;
    if (s == null) return;
    final now = DateTime.now();
    _stats = PetMath.computeStats(s, now);
    notifyListeners();
  }

  void _updateActionProgress() {
    final s = _state;
    if (s == null || !s.isActionActive) {
      if (_actionProgress != 0.0) {
        _actionProgress = 0.0;
        notifyListeners();
      }
      return;
    }

    final end = s.actionEndsAt!;
    final now = DateTime.now();
    final remainingMs = end.difference(now).inMilliseconds;

    if (remainingMs <= 0) {
      _actionProgress = 1.0;
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

  void _onRemoteEffect(String effect, String from) {
    if (effect == 'hearts') {
      _triggerHearts();
    } else if (effect == 'food') {
      _triggerSparkles();
    } else if (effect == 'meow') {
      _showBubble('Miyav~ 🐾');
    } else if (effect == 'wake') {
      _showBubble('Miyav~ ☀️');
    }
  }

  // ------------------------------------------------------------- Eylemler

  Future<void> feed() async {
    final s = _state;
    if (s == null || s.isSleeping || s.isActionActive) return;

    try {
      HapticFeedback.lightImpact();
      _triggerSparkles();
      _sync?.sendEffect('food');

      // Optimistik aksiyon
      _state = s.copyWith(
        currentAction: PetActionKind.eating,
        actionEndsAt: DateTime.now().add(const Duration(seconds: 3)),
        lastActionBy: myId,
        lastActionType: 'eating',
        lastActionAt: DateTime.now(),
      );
      notifyListeners();

      final client = Supabase.instance.client;
      await client.rpc('pet_start_action', params: {
        'p_room_id': roomId,
        'p_kind': 'eating',
      });
    } catch (e) {
      _fetchPet(); // Hata durumunda rollback
    }
  }

  Future<void> pet() async {
    final s = _state;
    if (s == null || s.isSleeping || s.isActionActive) return;

    try {
      HapticFeedback.mediumImpact();
      _triggerHearts();
      _sync?.sendEffect('hearts');

      _state = s.copyWith(
        currentAction: PetActionKind.petting,
        actionEndsAt: DateTime.now().add(const Duration(seconds: 3)),
        lastActionBy: myId,
        lastActionType: 'petting',
        lastActionAt: DateTime.now(),
      );
      notifyListeners();

      final client = Supabase.instance.client;
      await client.rpc('pet_start_action', params: {
        'p_room_id': roomId,
        'p_kind': 'petting',
      });
    } catch (e) {
      _fetchPet();
    }
  }

  Future<void> _finishAction() async {
    if (_isActionFinishing) return;
    _isActionFinishing = true;

    try {
      final client = Supabase.instance.client;
      final res = await client.rpc('pet_finish_action', params: {'p_room_id': roomId});
      if (res != null && res is Map) {
        _state = PetState.fromMap(res.cast<String, dynamic>());
      }
    } catch (_) {
      // Offline fallback: yerel tamamla
      final s = _state;
      if (s != null) {
        int newHunger = s.hunger;
        int newAffection = s.affection;
        if (s.currentAction == PetActionKind.eating) newHunger = (newHunger + 25).clamp(0, 100);
        if (s.currentAction == PetActionKind.petting) newAffection = (newAffection + 20).clamp(0, 100);

        _state = s.copyWith(
          hunger: newHunger,
          affection: newAffection,
          currentAction: PetActionKind.idle,
          actionEndsAt: null,
          statsUpdatedAt: DateTime.now(),
        );
      }
    } finally {
      _isActionFinishing = false;
      _actionProgress = 0.0;
      _updateStats();
      notifyListeners();
    }
  }

  Future<void> sleep(String? note) async {
    final s = _state;
    if (s == null || s.isSleeping) return;

    try {
      final sanitized = note != null && note.trim().isNotEmpty
          ? note.trim().substring(0, math.min(80, note.trim().length))
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
      await client.rpc('pet_sleep', params: {
        'p_room_id': roomId,
        'p_note': sanitized,
      });
    } catch (e) {
      _fetchPet();
    }
  }

  Future<void> wake() async {
    final s = _state;
    if (s == null || !s.isSleeping) return;

    try {
      HapticFeedback.mediumImpact();
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
      await client.rpc('pet_wake', params: {'p_room_id': roomId});
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
    final delaySeconds = 20 + _random.nextInt(10); // ~25s (±5s)
    _meowTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_disposed) return;
      final s = _state;
      if (s != null && !s.isSleeping && s.currentAction == PetActionKind.idle) {
        _isMeowing = true;
        _showBubble('Miyav~ 🐾');
        _sync?.sendEffect('meow');
        notifyListeners();
        Timer(const Duration(milliseconds: 1500), () {
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
    final actor = isMe ? 'Sen' : partnerNickname;
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
    _sync?.dispose();
    super.dispose();
  }
}
