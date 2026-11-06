// lib/features/canvas/poki_canvas_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/room_presence.dart';
import 'logic/canvas_controller.dart';
import 'logic/coop_canvas_sync.dart';
import 'models/drawing_stroke.dart';
import 'widgets/collapsible_toolbar.dart';
import 'widgets/poki_canvas_painter.dart';

class PokiCanvasScreen extends StatefulWidget {
  const PokiCanvasScreen({
    super.key,
    required this.roomId,
    this.isCoop = false,
  });

  final String roomId;
  final bool isCoop;

  @override
  State<PokiCanvasScreen> createState() => _PokiCanvasScreenState();
}

class _PokiCanvasScreenState extends State<PokiCanvasScreen> {
  late final CanvasController _controller;
  CoopCanvasSync? _sync;

  bool _isToolbarExpanded = false;
  bool _isMultiTouch = false;
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;

  // Çizim kağıdı sanal boyutları (Yüksek çözünürlüklü dijital eskiz defteri)
  static const double paperWidth = 1800.0;
  static const double paperHeight = 2400.0;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    final myId = client.auth.currentUser?.id ?? 'anon';
    final myNickname = client.auth.currentUser?.userMetadata?['nickname'] as String? ?? 'Poki';

    _controller = CanvasController(
      myId: myId,
      myNickname: myNickname,
      isCoop: widget.isCoop,
    );
    _controller.addListener(_onCanvasUpdated);

    if (widget.isCoop) {
      _sync = CoopCanvasSync(roomId: widget.roomId, controller: _controller);
      _sync!.init();
    }

    RoomPresence.current?.setActivity(PokiActivity.inApp);

    // İlk açılışta tuvali ekranın ortasına sığdır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCanvasToScreen();
    });
  }

  void _onCanvasUpdated() {
    if (mounted) setState(() {});
  }

  void _fitCanvasToScreen() {
    final size = MediaQuery.of(context).size;
    final scaleX = (size.width - 32) / paperWidth;
    final scaleY = (size.height - 140) / paperHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.15, 1.0);

    final tx = (size.width - paperWidth * scale) / 2;
    final ty = 80.0;

    final matrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);

    _controller.transformController.value = matrix;
    setState(() {});
  }

  @override
  void dispose() {
    _sync?.dispose();
    _controller.removeListener(_onCanvasUpdated);
    _controller.dispose();
    super.dispose();
  }

  // --- Dokunma & Çizim & Zoom Olayları ---

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _isMultiTouch = true;
      _lastFocalPoint = details.localFocalPoint;
      _lastScale = 1.0;
      // İki parmak algılanınca tek parmakla başlamış olabilecek yanlış dokunuşu iptal et
      _controller.cancelCurrentStroke();
    } else {
      _isMultiTouch = false;
      // Çizime başlandığı an fırça paneli açıksa ekranı açmak için otomatik kapat
      if (_isToolbarExpanded) {
        setState(() => _isToolbarExpanded = false);
      }
      final worldPoint = _controller.toWorld(details.localFocalPoint);
      _controller.startStroke(worldPoint);
      if (widget.isCoop && _controller.currentStroke != null) {
        _sync?.sendStrokeStart(_controller.currentStroke!);
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2 || _isMultiTouch) {
      _isMultiTouch = true;
      if (_lastFocalPoint != null) {
        final delta = details.localFocalPoint - _lastFocalPoint!;
        final scaleFactor = details.scale / _lastScale;
        _lastScale = details.scale;
        _lastFocalPoint = details.localFocalPoint;

        // Zoom & Pan Dönüşümü
        final matrix = _controller.transformController.value.clone();
        final focal = details.localFocalPoint;

        matrix.translate(focal.dx, focal.dy);
        matrix.scale(scaleFactor);
        matrix.translate(-focal.dx, -focal.dy);
        matrix.translate(delta.dx, delta.dy);

        _controller.transformController.value = matrix;
        setState(() {});
      }
    } else {
      final worldPoint = _controller.toWorld(details.localFocalPoint);
      _controller.appendPoint(worldPoint);

      if (widget.isCoop) {
        _sync?.throttlePoint(_controller.currentStroke?.id, worldPoint);
        _sync?.throttleCursor(worldPoint);
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isMultiTouch) {
      _isMultiTouch = false;
      _lastFocalPoint = null;
    } else {
      final finished = _controller.endStroke();
      if (finished != null && widget.isCoop) {
        _sync?.sendStrokeEnd(finished);
      }
    }
  }

  void _onUndo() {
    final undone = _controller.undo();
    if (undone != null && widget.isCoop) {
      _sync?.sendUndo(undone.id);
    }
  }

  void _onRedo() {
    _controller.redo();
  }

  void _onClear() {
    final subtextColor = PokiColors.textOf(context).withOpacity(0.6);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PokiColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tuvali Temizle 🎨', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tuvaldeki tüm çizimler silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç', style: TextStyle(color: subtextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE88A9A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Temizle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _controller.clearCanvas();
        if (widget.isCoop) {
          _sync?.sendClear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCoop ? 'İki Pati Bir Tuval 🐾' : 'Poki Tuval 🎨';
    final textColor = PokiColors.textOf(context);
    final subtextColor = PokiColors.textOf(context).withOpacity(0.6);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC), // Sıcak pastel çalışma masası
      body: SafeArea(
        child: Stack(
          children: [
            // 1. İnteraktif Çizim ve Zoom Alanı
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: CustomPaint(
                  painter: PokiCanvasPainter(
                    transformMatrix: _controller.transformController.value,
                    strokes: _controller.strokes,
                    currentStroke: _controller.currentStroke,
                    partnerStrokes: _controller.partnerActiveStrokes,
                    partnerCursor: _controller.partnerCursor,
                    paperWidth: paperWidth,
                    paperHeight: paperHeight,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),

            // 2. Üst Bar (Başlık, Geri Al, İleri Al, Zoom Sıfırla, Temizle)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PokiColors.surfaceOf(context).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PokiColors.textOf(context).withOpacity(0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Geri Dön',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (widget.isCoop)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF67C29C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Canlı Ortak Çizim',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Geri Al
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 22),
                      tooltip: 'Geri Al',
                      color: _controller.canUndo ? textColor : Colors.grey.shade400,
                      onPressed: _controller.canUndo ? _onUndo : null,
                    ),
                    // İleri Al
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, size: 22),
                      tooltip: 'İleri Al',
                      color: _controller.canRedo ? textColor : Colors.grey.shade400,
                      onPressed: _controller.canRedo ? _onRedo : null,
                    ),
                    // Zoom Sıfırla
                    IconButton(
                      icon: const Icon(Icons.fit_screen_rounded, size: 22),
                      tooltip: 'Ekrana Sığdır',
                      onPressed: _fitCanvasToScreen,
                    ),
                    // Temizle
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      tooltip: 'Tuvali Temizle',
                      color: const Color(0xFFE88A9A),
                      onPressed: _controller.strokes.isNotEmpty ? _onClear : null,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Alt Katlanabilir Araç Çubuğu (Collapsible Toolbar)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: CollapsibleToolbar(
                  isExpanded: _isToolbarExpanded,
                  selectedTool: _controller.selectedTool,
                  selectedColor: _controller.selectedColor,
                  strokeWidth: _controller.strokeWidth,
                  opacity: _controller.opacity,
                  onToggleExpanded: (val) {
                    setState(() => _isToolbarExpanded = val);
                  },
                  onToolSelected: (tool) {
                    setState(() => _controller.selectedTool = tool);
                  },
                  onColorSelected: (col) {
                    setState(() => _controller.selectedColor = col);
                  },
                  onWidthChanged: (w) {
                    setState(() => _controller.strokeWidth = w);
                  },
                  onOpacityChanged: (op) {
                    setState(() => _controller.opacity = op);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
