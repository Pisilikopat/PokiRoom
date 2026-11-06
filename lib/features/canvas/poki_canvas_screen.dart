// Poki Tuval & İki Pati Bir Tuval - v1.1.0
// lib/features/canvas/poki_canvas_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/room_presence.dart';
import 'logic/canvas_controller.dart';
import 'logic/coop_canvas_sync.dart';
import 'models/drawing_stroke.dart';
import 'services/image_saver.dart';
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
  bool _isPinching = false;
  bool _isMiddleClickPanning = false;
  Offset? _middlePanLastPos;
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;
  bool _isSaving = false;

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

  void _zoomStep(double factor) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final matrix = _controller.transformController.value.clone();
    final currentScale = matrix.storage[0];
    final targetScale = (currentScale * factor).clamp(0.25, 5.0);
    final effectiveFactor = targetScale / currentScale;

    final oldTx = matrix.storage[12];
    final oldTy = matrix.storage[13];

    final newTx = cx * (1.0 - effectiveFactor) + effectiveFactor * oldTx;
    final newTy = cy * (1.0 - effectiveFactor) + effectiveFactor * oldTy;

    matrix.storage[0] = targetScale;
    matrix.storage[5] = targetScale;
    matrix.storage[12] = newTx;
    matrix.storage[13] = newTy;

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
    if (_isMiddleClickPanning) return;
    if (details.pointerCount >= 2) {
      _isMultiTouch = true;
      _isPinching = false;
      _lastFocalPoint = details.localFocalPoint;
      _lastScale = 1.0;
      _controller.cancelCurrentStroke();
      return;
    }

    _isMultiTouch = false;
    _isPinching = false;
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;

    // 1. Kaydır (El) Aracı: Sadece gezinme
    if (_controller.selectedTool == DrawingTool.hand) {
      return;
    }

    // 2. Çizgi Silgisi Modu: Dokunulan çizgiyi tamamen sil
    if (_controller.selectedTool == DrawingTool.strokeEraser) {
      final worldPoint = _controller.toWorld(details.localFocalPoint);
      _deleteStrokeAtWorld(worldPoint);
      return;
    }

    // 3. Boya Kovası (Bucket Tool): Dokunulan kapalı alanı pürüzsüz doldur
    if (_controller.selectedTool == DrawingTool.bucket) {
      final worldPoint = _controller.toWorld(details.localFocalPoint);
      final fillStroke = _controller.fillAt(
        worldPoint: worldPoint,
        paperWidth: paperWidth,
        paperHeight: paperHeight,
      );
      if (fillStroke != null) {
        HapticFeedback.lightImpact();
        if (widget.isCoop) {
          _sync?.sendStrokeStart(fillStroke);
          _sync?.sendStrokeEnd(fillStroke);
        }
      }
      return;
    }

    // 4. Normal Çizim Araçları
    if (_isToolbarExpanded) {
      setState(() => _isToolbarExpanded = false);
    }
    final worldPoint = _controller.toWorld(details.localFocalPoint);
    _controller.startStroke(worldPoint);
    if (widget.isCoop && _controller.currentStroke != null) {
      _sync?.sendStrokeStart(_controller.currentStroke!);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isMiddleClickPanning) return;
    // 2 parmakla pinch zoom veya pan (veya çoklu dokunma devam ediyorsa)
    if (details.pointerCount >= 2 || _isMultiTouch) {
      _isMultiTouch = true;
      // İlk parmak önce değip çizgi başlatmışsa derhal iptal et
      _controller.cancelCurrentStroke();

      if (_lastFocalPoint != null) {
        final delta = details.localFocalPoint - _lastFocalPoint!;
        _lastFocalPoint = details.localFocalPoint;

        final rawRatio = details.scale / _lastScale;
        _lastScale = details.scale;

        // Deadband: Ekranda gezinirken parmak mesafesi doğal olarak titrer.
        // Başlangıç mesafesine göre %6'dan az değişim varsa tamamen DÜZ KAYDIR (Pan).
        // Böylece hareket ettirirken ileri-geri zoomlama kesinlikle engellenir!
        if (!_isPinching) {
          if ((details.scale - 1.0).abs() > 0.06) {
            _isPinching = true;
          }
        }

        double scaleFactor = 1.0;
        if (_isPinching && (rawRatio - 1.0).abs() >= 0.004) {
          // Mikro titreşimleri filtrele ve yumuşat
          scaleFactor = 1.0 + (rawRatio - 1.0) * 0.85;
        }

        final matrix = _controller.transformController.value.clone();
        final currentScale = matrix.storage[0];

        // 0.25x - 5.0x zoom aralığı
        final targetScale = (currentScale * scaleFactor).clamp(0.25, 5.0);
        final effectiveFactor = targetScale / currentScale;

        final fx = details.localFocalPoint.dx;
        final fy = details.localFocalPoint.dy;
        final oldTx = matrix.storage[12];
        final oldTy = matrix.storage[13];

        // Ekran koordinatında doğrudan 1:1 kaydırma + odak noktasında kusursuz zoom
        final newTx = fx * (1.0 - effectiveFactor) + effectiveFactor * oldTx + delta.dx;
        final newTy = fy * (1.0 - effectiveFactor) + effectiveFactor * oldTy + delta.dy;

        matrix.storage[0] = targetScale;
        matrix.storage[5] = targetScale;
        matrix.storage[12] = newTx;
        matrix.storage[13] = newTy;

        _controller.transformController.value = matrix;
        setState(() {});
      }
      return;
    }

    // 1. Kaydır (El) Aracı: Tek parmak / mouse sürükleme ile sayfayı taşı
    if (_controller.selectedTool == DrawingTool.hand) {
      if (_lastFocalPoint != null) {
        final delta = details.localFocalPoint - _lastFocalPoint!;
        _lastFocalPoint = details.localFocalPoint;

        final matrix = _controller.transformController.value.clone();
        // Doğrudan 1:1 ekran koordinatında dümdüz kaydırma
        matrix.storage[12] += delta.dx;
        matrix.storage[13] += delta.dy;

        _controller.transformController.value = matrix;
        setState(() {});
      }
      return;
    }

    // 2. Çizgi Silgisi: Sürüklenen yoldaki tüm çizgileri sil
    if (_controller.selectedTool == DrawingTool.strokeEraser) {
      final worldPoint = _controller.toWorld(details.localFocalPoint);
      _deleteStrokeAtWorld(worldPoint);
      return;
    }

    // 3. Normal Çizim
    final worldPoint = _controller.toWorld(details.localFocalPoint);
    _controller.appendPoint(worldPoint);

    if (widget.isCoop) {
      _sync?.throttlePoint(_controller.currentStroke?.id, worldPoint);
      _sync?.throttleCursor(worldPoint);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isMultiTouch) {
      _isMultiTouch = false;
      _isPinching = false;
      _lastFocalPoint = null;
      _lastScale = 1.0;
    } else if (_controller.selectedTool == DrawingTool.hand) {
      _lastFocalPoint = null;
    } else if (_controller.selectedTool == DrawingTool.strokeEraser) {
      // Çizgi silgisi bitti
    } else {
      final finished = _controller.endStroke();
      if (finished != null && widget.isCoop) {
        _sync?.sendStrokeEnd(finished);
      }
    }
  }

  void _deleteStrokeAtWorld(Offset worldPoint) {
    final deleted = _controller.deleteStrokeAt(worldPoint);
    if (deleted != null) {
      HapticFeedback.lightImpact();
      if (widget.isCoop) {
        _sync?.sendDeleteStroke(deleted.id);
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

  // --- Tuvali Yüksek Çözünürlüklü Resim Olarak Kaydetme ---

  Future<void> _saveCanvasImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final paperRect = Rect.fromLTWH(0, 0, paperWidth, paperHeight);
      final paperRRect = RRect.fromRectAndRadius(paperRect, const Radius.circular(16));

      // Kağıt tabanı
      canvas.drawRRect(paperRRect, Paint()..color = const Color(0xFFFFFDF8));

      // Kağıt sınırları içine çizimleri kırp
      canvas.save();
      canvas.clipRRect(paperRRect);

      // Tüm çizgileri tam 1800x2400 piksel kalitesinde çiz
      for (final stroke in _controller.strokes) {
        PokiCanvasPainter.drawStrokeDirect(canvas, stroke, const Color(0xFFFFFDF8));
      }

      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(paperWidth.toInt(), paperHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final fileName = 'PokiTuval_${DateTime.now().millisecondsSinceEpoch}.png';
        await CanvasImageSaver.save(bytes, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tuval resmi başarıyla kaydedildi! 🎨🐾'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCoop ? 'İki Pati 🐾' : 'Poki Tuval 🎨';
    final fullTitle = widget.isCoop ? 'İki Pati Bir Tuval 🐾' : 'Poki Tuval 🎨';
    final textColor = PokiColors.textOf(context);
    final isWide = MediaQuery.of(context).size.width >= 640;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Ctrl + Z / Cmd + Z: Geri Al
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (_controller.canUndo) _onUndo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (_controller.canUndo) _onUndo();
        },
        // Ctrl + Y: İleri Al
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (_controller.canRedo) _onRedo();
        },
        // Ctrl + Shift + Z / Cmd + Shift + Z: İleri Al
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          if (_controller.canRedo) _onRedo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          if (_controller.canRedo) _onRedo();
        },
        // Ctrl + S / Cmd + S: Kaydet
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (_controller.strokes.isNotEmpty && !_isSaving) _saveCanvasImage();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (_controller.strokes.isNotEmpty && !_isSaving) _saveCanvasImage();
        },
        // Araç Kısayolları (F, B, E, H)
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          _controller.setTool(DrawingTool.brush);
          HapticFeedback.selectionClick();
          setState(() {});
        },
        const SingleActivator(LogicalKeyboardKey.keyB): () {
          _controller.setTool(DrawingTool.bucket);
          HapticFeedback.selectionClick();
          setState(() {});
        },
        const SingleActivator(LogicalKeyboardKey.keyE): () {
          _controller.setTool(DrawingTool.strokeEraser);
          HapticFeedback.selectionClick();
          setState(() {});
        },
        const SingleActivator(LogicalKeyboardKey.keyH): () {
          _controller.setTool(DrawingTool.hand);
          HapticFeedback.selectionClick();
          setState(() {});
        },
        // Zoom Kısayolları (+, -, 0)
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () => _zoomStep(1.18),
        const SingleActivator(LogicalKeyboardKey.add): () => _zoomStep(1.18),
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () => _zoomStep(0.85),
        const SingleActivator(LogicalKeyboardKey.numpadSubtract): () => _zoomStep(0.85),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): _fitCanvasToScreen,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      backgroundColor: const Color(0xFFF7F3EC), // Sıcak pastel çalışma masası
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Bilgisayar Mouse Scroll + Dokunmatik İnteraktif Çizim Alanı
            Positioned.fill(
              child: Listener(
                onPointerDown: (event) {
                  // Bilgisayarda mouse orta tuşu (tekerlek tuşu / kMiddleMouseButton) ile basılı tutup kaydırma
                  if ((event.buttons & kMiddleMouseButton) != 0) {
                    _isMiddleClickPanning = true;
                    _middlePanLastPos = event.localPosition;
                    _controller.cancelCurrentStroke();
                    setState(() {});
                  }
                },
                onPointerMove: (event) {
                  if (_isMiddleClickPanning && _middlePanLastPos != null) {
                    final delta = event.localPosition - _middlePanLastPos!;
                    _middlePanLastPos = event.localPosition;

                    final matrix = _controller.transformController.value.clone();
                    matrix.storage[12] += delta.dx;
                    matrix.storage[13] += delta.dy;
                    _controller.transformController.value = matrix;
                    setState(() {});
                  }
                },
                onPointerUp: (event) {
                  if (_isMiddleClickPanning) {
                    _isMiddleClickPanning = false;
                    _middlePanLastPos = null;
                    setState(() {});
                  }
                },
                onPointerCancel: (event) {
                  if (_isMiddleClickPanning) {
                    _isMiddleClickPanning = false;
                    _middlePanLastPos = null;
                    setState(() {});
                  }
                },
                onPointerSignal: (pointerSignal) {
                  // Bilgisayarda mouse tekerleğiyle yakınlaşma / uzaklaşma
                  if (pointerSignal is PointerScrollEvent) {
                    final delta = pointerSignal.scrollDelta.dy;
                    if (delta == 0) return;

                    final factor = delta < 0 ? 1.12 : 0.89;
                    final matrix = _controller.transformController.value.clone();
                    final currentScale = matrix.storage[0];
                    final targetScale = (currentScale * factor).clamp(0.25, 5.0);
                    final effectiveFactor = targetScale / currentScale;

                    final fx = pointerSignal.localPosition.dx;
                    final fy = pointerSignal.localPosition.dy;
                    final oldTx = matrix.storage[12];
                    final oldTy = matrix.storage[13];

                    final newTx = fx * (1.0 - effectiveFactor) + effectiveFactor * oldTx;
                    final newTy = fy * (1.0 - effectiveFactor) + effectiveFactor * oldTy;

                    matrix.storage[0] = targetScale;
                    matrix.storage[5] = targetScale;
                    matrix.storage[12] = newTx;
                    matrix.storage[13] = newTy;

                    _controller.transformController.value = matrix;
                    setState(() {});
                  }
                },
                child: MouseRegion(
                  cursor: _isMiddleClickPanning
                      ? SystemMouseCursors.grabbing
                      : (_controller.selectedTool == DrawingTool.hand
                          ? SystemMouseCursors.grab
                          : SystemMouseCursors.precise),
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
              ),
            ),

            // 2A. Sol Üst Kapsül (Geri Dön + Başlık) — Asla Harf Kırılmaz, Kusursuz Ferah Tasarım
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: PokiColors.surfaceOf(context).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: PokiColors.textOf(context).withOpacity(0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Geri Dön',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isWide ? fullTitle : title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (widget.isCoop) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF67C29C),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2B. Sağ Üst Kapsül (Geri Al, İleri Al, Zoom, Sığdır, Kaydet, Menü)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: PokiColors.surfaceOf(context).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: PokiColors.textOf(context).withOpacity(0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Geri Al (Ctrl+Z)
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 19),
                      tooltip: 'Geri Al (Ctrl+Z)',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: _controller.canUndo ? textColor : Colors.grey.shade400,
                      onPressed: _controller.canUndo ? _onUndo : null,
                    ),
                    // İleri Al (Ctrl+Y)
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, size: 19),
                      tooltip: 'İleri Al (Ctrl+Y)',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: _controller.canRedo ? textColor : Colors.grey.shade400,
                      onPressed: _controller.canRedo ? _onRedo : null,
                    ),
                    if (isWide) ...[
                      // Uzaklaş (-)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 19),
                        tooltip: 'Uzaklaş (-)',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _zoomStep(0.85),
                      ),
                      // Yakınlaş (+)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                        tooltip: 'Yakınlaş (+)',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _zoomStep(1.18),
                      ),
                    ],
                    // Ekrana Sığdır (Ctrl+0)
                    IconButton(
                      icon: const Icon(Icons.fit_screen_rounded, size: 19),
                      tooltip: 'Ekrana Sığdır (Ctrl+0)',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _fitCanvasToScreen,
                    ),
                    // Tuvali Kaydet (Ctrl+S)
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 19),
                      tooltip: 'Resim Olarak Kaydet (Ctrl+S)',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: PokiColors.primaryButton,
                      onPressed: _controller.strokes.isNotEmpty && !_isSaving
                          ? _saveCanvasImage
                          : null,
                    ),
                    if (isWide)
                      // Temizle (Geniş ekranda doğrudan buton)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 19),
                        tooltip: 'Tuvali Temizle',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: const Color(0xFFE88A9A),
                        onPressed: _controller.strokes.isNotEmpty ? _onClear : null,
                      )
                    else
                      // Mobilde Daha Fazla Menüsü (...)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 19),
                        tooltip: 'Daha Fazla',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: PokiColors.surfaceOf(context),
                        onSelected: (val) {
                          if (val == 'zoom_in') _zoomStep(1.18);
                          if (val == 'zoom_out') _zoomStep(0.85);
                          if (val == 'clear') _onClear();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'zoom_in',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Yakınlaş (+)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'zoom_out',
                            child: Row(
                              children: [
                                Icon(Icons.remove_circle_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Uzaklaş (-)'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'clear',
                            enabled: _controller.strokes.isNotEmpty,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE88A9A)),
                                SizedBox(width: 8),
                                Text(
                                  'Tuvali Temizle',
                                  style: TextStyle(
                                    color: _controller.strokes.isNotEmpty ? Color(0xFFE88A9A) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
    ),
    ),
    );
  }
}
