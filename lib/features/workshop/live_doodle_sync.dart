// lib/features/workshop/live_doodle_sync.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/doodle_stroke.dart';
import 'doodle_controller.dart';

/// `room:{room_id}:doodle` Broadcast kanalı üzerinden çift taraflı canlı çizim.
///
/// Olaylar:
///  - stroke {phase: start|update|end, id, ...}  -> çizgi akışı
///  - undo {id}, clear {}
///  - sync_request / sync_state                  -> geç katılana mevcut tuvali gönderir
/// Veritabanına hiçbir şey yazılmaz.
class LiveDoodleSync {
  LiveDoodleSync({
    required this.roomId,
    required this.myId,
    required this.controller,
    SupabaseClient? client,
  }) : _db = client ?? Supabase.instance.client;

  static const Duration _flushInterval = Duration(milliseconds: 50);

  final String roomId;
  final String myId;
  final DoodleController controller;
  final SupabaseClient _db;

  /// Karşı taraf tuvalde mi?
  final ValueNotifier<bool> partnerHere = ValueNotifier(false);

  RealtimeChannel? _channel;
  Timer? _flushTimer;
  String? _pendingId;
  final List<Offset> _pending = [];
  bool _disposed = false;

  void join() {
    controller
      ..onStrokeStart = _onStart
      ..onStrokePoints = _onPoints
      ..onStrokeEnd = _onEnd
      ..onUndo = ((id) => _send('undo', {'id': id}))
      ..onClear = (() => _send('clear', {}));

    final channel = _db.channel(
      'room:$roomId:doodle',
      opts: RealtimeChannelConfig(key: myId),
    );
    channel
        .onPresenceSync((_) => _syncPresence())
        .onBroadcast(event: 'stroke', callback: _onRemoteStroke)
        .onBroadcast(event: 'undo', callback: _onRemoteUndo)
        .onBroadcast(event: 'clear', callback: _onRemoteClear)
        .onBroadcast(event: 'sync_request', callback: _onSyncRequest)
        .onBroadcast(event: 'sync_state', callback: _onSyncState)
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({'here': true});
        _send('sync_request', {});
      }
    });
    _channel = channel;
  }

  // ----------------------------------------------------------- gönderme

  void _send(String event, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || _disposed) return;
    channel
        .sendBroadcastMessage(event: event, payload: {...payload, 'from': myId})
        .catchError((_) {});
  }

  void _onStart(DoodleStroke s) {
    _flushNow();
    _send('stroke', {
      'phase': 'start',
      'id': s.id,
      'c': s.color,
      'w': s.width,
      'o': s.ownerId,
      'x': s.points.first.dx,
      'y': s.points.first.dy,
    });
  }

  void _onPoints(DoodleStroke s, List<Offset> added) {
    _pendingId = s.id;
    _pending.addAll(added);
    _flushTimer ??= Timer(_flushInterval, _flushNow);
  }

  void _onEnd(DoodleStroke s) {
    _flushNow();
    _send('stroke', {'phase': 'end', 'id': s.id});
  }

  void _flushNow() {
    _flushTimer?.cancel();
    _flushTimer = null;
    final id = _pendingId;
    if (id == null || _pending.isEmpty) return;
    _send('stroke', {
      'phase': 'update',
      'id': id,
      'p': [
        for (final p in _pending) ...[_round(p.dx), _round(p.dy)],
      ],
    });
    _pending.clear();
  }

  double _round(double v) => (v * 10000).roundToDouble() / 10000;

  // ------------------------------------------------------------- alma

  Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final nested = raw['payload'];
    return nested is Map ? nested.cast<String, dynamic>() : raw;
  }

  void _onRemoteStroke(Map<String, dynamic> raw) {
    try {
      final d = _unwrap(raw);
      if (d['from'] == myId) return;
      final id = d['id'] as String?;
      if (id == null) return;
      switch (d['phase']) {
        case 'start':
          controller.remoteStart(DoodleStroke(
            id: id,
            color: (d['c'] as num).toInt(),
            width: (d['w'] as num).toDouble(),
            ownerId: (d['o'] as String?) ?? '',
            points: [Offset((d['x'] as num).toDouble(), (d['y'] as num).toDouble())],
          ));
        case 'update':
          final flat = (d['p'] as List).map((e) => (e as num).toDouble()).toList();
          controller.remoteAppend(id, [
            for (var i = 0; i + 1 < flat.length; i += 2) Offset(flat[i], flat[i + 1]),
          ]);
        default:
          break; // 'end': ek işlem gerekmez
      }
    } catch (_) {}
  }

  void _onRemoteUndo(Map<String, dynamic> raw) {
    try {
      final d = _unwrap(raw);
      if (d['from'] == myId) return;
      final id = d['id'] as String?;
      if (id != null) controller.removeStroke(id);
    } catch (_) {}
  }

  void _onRemoteClear(Map<String, dynamic> raw) {
    final d = _unwrap(raw);
    if (d['from'] == myId) return;
    controller.remoteClear();
  }

  void _onSyncRequest(Map<String, dynamic> raw) {
    final d = _unwrap(raw);
    final requester = d['from'] as String?;
    if (requester == null || requester == myId || controller.isEmpty) return;
    _send('sync_state', {
      'to': requester,
      'strokes': [for (final s in controller.strokes) s.toMap()],
    });
  }

  void _onSyncState(Map<String, dynamic> raw) {
    try {
      final d = _unwrap(raw);
      if (d['to'] != myId) return;
      final list = (d['strokes'] as List)
          .map((e) => DoodleStroke.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      controller.mergeStrokes(list);
    } catch (_) {}
  }

  void _syncPresence() {
    var here = false;
    for (final s in _channel?.presenceState() ?? <SinglePresenceState>[]) {
      if (s.key != myId && s.presences.isNotEmpty) here = true;
    }
    if (!_disposed && partnerHere.value != here) partnerHere.value = here;
  }

  void dispose() {
    _disposed = true;
    _flushTimer?.cancel();
    controller
      ..onStrokeStart = null
      ..onStrokePoints = null
      ..onStrokeEnd = null
      ..onUndo = null
      ..onClear = null;
    final channel = _channel;
    if (channel != null) {
      channel.untrack();
      _db.removeChannel(channel);
    }
    partnerHere.dispose();
  }
}
