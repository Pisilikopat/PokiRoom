// lib/features/canvas/logic/coop_canvas_sync.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/drawing_stroke.dart';
import 'canvas_controller.dart';

class CoopCanvasSync {
  CoopCanvasSync({
    required this.roomId,
    required this.controller,
  });

  final String roomId;
  final CanvasController controller;

  final SupabaseClient _db = Supabase.instance.client;
  RealtimeChannel? _channel;

  // Çizim noktalarını paketleyip göndermek için throttle mekanizması (~35ms = ~30 fps ağ akışı)
  Timer? _chunkTimer;
  final List<DrawingPoint> _pendingChunkPoints = [];
  String? _pendingChunkStrokeId;

  // İmleç throttle (~50ms)
  Timer? _cursorTimer;
  Offset? _pendingCursorPos;

  Future<void> init() async {
    final channelName = 'room:$roomId:canvas';
    _channel = _db.channel(channelName);

    _channel!
      .onBroadcast(event: 'stroke_start', callback: (payload) {
        try {
          final map = payload['stroke'] as Map<String, dynamic>?;
          if (map != null) {
            final stroke = DrawingStroke.fromMap(map);
            if (stroke.authorId != controller.myId) {
              controller.onPartnerStrokeStart(stroke);
            }
          }
        } catch (e) {
          debugPrint('[CanvasSync] stroke_start error: $e');
        }
      })
      .onBroadcast(event: 'stroke_chunk', callback: (payload) {
        try {
          final strokeId = payload['id'] as String?;
          final pointsList = (payload['points'] as List?) ?? [];
          if (strokeId != null && pointsList.isNotEmpty) {
            final points = pointsList
                .map((p) => DrawingPoint.fromMap((p as Map).cast<String, dynamic>()))
                .toList();
            controller.onPartnerStrokeChunk(strokeId, points);
          }
        } catch (e) {
          debugPrint('[CanvasSync] stroke_chunk error: $e');
        }
      })
      .onBroadcast(event: 'stroke_end', callback: (payload) {
        try {
          final map = payload['stroke'] as Map<String, dynamic>?;
          if (map != null) {
            final stroke = DrawingStroke.fromMap(map);
            if (stroke.authorId != controller.myId) {
              controller.onPartnerStrokeEnd(stroke);
            }
          }
        } catch (e) {
          debugPrint('[CanvasSync] stroke_end error: $e');
        }
      })
      .onBroadcast(event: 'stroke_undo', callback: (payload) {
        try {
          final strokeId = payload['strokeId'] as String?;
          if (strokeId != null) {
            controller.onPartnerUndo(strokeId);
          }
        } catch (e) {
          debugPrint('[CanvasSync] stroke_undo error: $e');
        }
      })
      .onBroadcast(event: 'canvas_clear', callback: (payload) {
        try {
          controller.onPartnerClear();
        } catch (e) {
          debugPrint('[CanvasSync] canvas_clear error: $e');
        }
      })
      .onBroadcast(event: 'sync_request', callback: (payload) {
        try {
          final fromId = payload['fromId'] as String?;
          if (fromId != null && fromId != controller.myId && controller.strokes.isNotEmpty) {
            sendSyncResponse(fromId);
          }
        } catch (e) {
          debugPrint('[CanvasSync] sync_request error: $e');
        }
      })
      .onBroadcast(event: 'sync_response', callback: (payload) {
        try {
          final targetId = payload['targetId'] as String?;
          if (targetId == controller.myId) {
            final list = (payload['strokes'] as List?) ?? [];
            final strokes = list
                .map((s) => DrawingStroke.fromMap((s as Map).cast<String, dynamic>()))
                .toList();
            if (strokes.isNotEmpty && controller.strokes.isEmpty) {
              controller.loadInitialStrokes(strokes);
            }
          }
        } catch (e) {
          debugPrint('[CanvasSync] sync_response error: $e');
        }
      })
      .onBroadcast(event: 'cursor', callback: (payload) {
        try {
          final authorId = payload['authorId'] as String?;
          if (authorId != controller.myId) {
            final x = (payload['x'] as num).toDouble();
            final y = (payload['y'] as num).toDouble();
            final nick = payload['nick'] as String? ?? 'Partner';
            final colorInt = (payload['color'] as num?)?.toInt() ?? 0xFFE88A9A;
            controller.onPartnerCursor(Offset(x, y), nick, Color(colorInt));
          }
        } catch (e) {
          debugPrint('[CanvasSync] cursor error: $e');
        }
      })
      .subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          // Odaya girer girmez partnerden güncel tuvali iste
          _sendSyncRequest();
        }
      });
  }

  void _sendSyncRequest() {
    _channel?.sendBroadcastMessage(
      event: 'sync_request',
      payload: {'fromId': controller.myId},
    );
  }

  void sendSyncResponse(String targetId) {
    final strokesMap = controller.strokes.map((s) => s.toMap()).toList();
    _channel?.sendBroadcastMessage(
      event: 'sync_response',
      payload: {
        'targetId': targetId,
        'strokes': strokesMap,
      },
    );
  }

  void sendStrokeStart(DrawingStroke stroke) {
    _channel?.sendBroadcastMessage(
      event: 'stroke_start',
      payload: {'stroke': stroke.toMap()},
    );
  }

  void throttlePoint(String? strokeId, Offset point) {
    if (strokeId == null) return;
    _pendingChunkStrokeId = strokeId;
    _pendingChunkPoints.add(DrawingPoint(x: point.dx, y: point.dy));

    if (_chunkTimer == null || !_chunkTimer!.isActive) {
      _chunkTimer = Timer(const Duration(milliseconds: 35), _flushChunk);
    }
  }

  void _flushChunk() {
    if (_pendingChunkStrokeId != null && _pendingChunkPoints.isNotEmpty) {
      final pointsMap = _pendingChunkPoints.map((p) => p.toMap()).toList();
      _channel?.sendBroadcastMessage(
        event: 'stroke_chunk',
        payload: {
          'id': _pendingChunkStrokeId,
          'points': pointsMap,
        },
      );
      _pendingChunkPoints.clear();
    }
  }

  void sendStrokeEnd(DrawingStroke stroke) {
    _chunkTimer?.cancel();
    _pendingChunkPoints.clear();
    _pendingChunkStrokeId = null;

    _channel?.sendBroadcastMessage(
      event: 'stroke_end',
      payload: {'stroke': stroke.toMap()},
    );
  }

  void sendUndo(String strokeId) {
    _channel?.sendBroadcastMessage(
      event: 'stroke_undo',
      payload: {'strokeId': strokeId},
    );
  }

  void sendClear() {
    _channel?.sendBroadcastMessage(
      event: 'canvas_clear',
      payload: {'authorId': controller.myId},
    );
  }

  void throttleCursor(Offset worldPosition) {
    _pendingCursorPos = worldPosition;
    if (_cursorTimer == null || !_cursorTimer!.isActive) {
      _cursorTimer = Timer(const Duration(milliseconds: 50), () {
        if (_pendingCursorPos != null) {
          _channel?.sendBroadcastMessage(
            event: 'cursor',
            payload: {
              'authorId': controller.myId,
              'nick': controller.myNickname,
              'x': double.parse(_pendingCursorPos!.dx.toStringAsFixed(1)),
              'y': double.parse(_pendingCursorPos!.dy.toStringAsFixed(1)),
              'color': controller.selectedColor.toARGB32(),
            },
          );
        }
      });
    }
  }

  void dispose() {
    _chunkTimer?.cancel();
    _cursorTimer?.cancel();
    _channel?.unsubscribe();
  }
}
