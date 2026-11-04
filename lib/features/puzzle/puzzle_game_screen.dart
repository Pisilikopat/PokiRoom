// lib/features/puzzle/puzzle_game_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/room_presence.dart';
import 'logic/puzzle_sync.dart';
import 'models/puzzle_config.dart';
import 'widgets/piece_tray.dart';
import 'widgets/puzzle_board.dart';
import 'widgets/puzzle_top_bar.dart';

/// Poki Puzzle ana oyun ekranı.
/// Gerçek zamanlı eş zamanlı oynanış, sürükle-bırak, sayaç ve kutlama akışı.
class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    this.isHost = true,
  });

  final String roomId;
  final PuzzleConfig config;
  final bool isHost;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  PuzzleSync? _sync;
  StreamSubscription<PuzzlePieceMove>? _moveSub;
  StreamSubscription<void>? _restartSub;
  StreamSubscription<void>? _abandonSub;

  String get _myId => Supabase.instance.client.auth.currentUser?.id ?? '';

  late final int _grid;
  late final int _totalPieces;

  final Map<int, int> _placedSlots = {}; // slotIndex -> pieceIndex
  final Set<int> _placedByPartnerSlots = {};
  final List<int> _unplacedPieces = [];

  int? _selectedTrayPiece;
  bool _showGhostHint = true;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isCompleted = false;
  bool _abandonDialogShown = false;

  int _myPlacedCount = 0;
  int _partnerPlacedCount = 0;

  @override
  void initState() {
    super.initState();
    _grid = widget.config.difficulty.grid;
    _totalPieces = widget.config.difficulty.pieceCount;

    _initPieces();
    _startTimer();
    _initSync();

    RoomPresence.current?.setActivity(
      widget.isHost ? PokiActivity.inPuzzleWaiting : PokiActivity.inPuzzlePlaying,
    );
  }

  void _initPieces() {
    _placedSlots.clear();
    _placedByPartnerSlots.clear();
    _unplacedPieces.clear();
    _myPlacedCount = 0;
    _partnerPlacedCount = 0;
    _isCompleted = false;
    _selectedTrayPiece = null;

    final pieces = List.generate(_totalPieces, (i) => i);
    pieces.shuffle(math.Random());
    _unplacedPieces.addAll(pieces);
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCompleted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _initSync() {
    final myId = _myId;
    if (myId.isEmpty) return;

    final sync = PuzzleSync(roomId: widget.roomId, myId: myId);
    _sync = sync;

    _moveSub = sync.onPiecePlaced.listen(_onRemotePiecePlaced);
    _restartSub = sync.onRestart.listen((_) => _onRemoteRestart());
    _abandonSub = sync.onAbandon.listen((_) => _onPartnerLeft());
  }

  void _onRemotePiecePlaced(PuzzlePieceMove move) {
    if (!mounted || _isCompleted) return;

    setState(() {
      _placedSlots[move.slotIndex] = move.pieceIndex;
      _placedByPartnerSlots.add(move.slotIndex);
      _unplacedPieces.remove(move.pieceIndex);
      _partnerPlacedCount++;
      if (_selectedTrayPiece == move.pieceIndex) {
        _selectedTrayPiece = null;
      }
    });

    HapticFeedback.lightImpact();

    if (_placedSlots.length >= _totalPieces) {
      _handleVictory();
    }
  }

  void _onRemoteRestart() {
    if (!mounted) return;
    setState(() {
      _initPieces();
      _startTimer();
    });
  }

  void _onPartnerLeft() {
    if (!mounted || _abandonDialogShown || _isCompleted) return;
    _abandonDialogShown = true;
    HapticFeedback.heavyImpact();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('😿', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Partnerin Ayrıldı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Arkadaşın oyundan çıktı veya bağlantısı kesildi 🐾\n\nOyunu tek başına tamamlayabilir veya sohbete geri dönebilirsin.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PokiColors.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sohbete Dön'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_isCompleted) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Oyundan Çıkılsın mı?'),
          ],
        ),
        content: const Text(
          'Oyundan ayrılırsan oyun sonlanacak ve karşı tarafa bildirim gidecek.\n\nEmin misin?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Devam Et', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Evet, Ayrıl'),
          ),
        ],
      ),
    );

    if (leave == true) {
      _sync?.sendAbandon();
      return true;
    }
    return false;
  }

  void _onSlotDrop(int slotIndex, int pieceIndex) {
    if (_isCompleted) return;

    if (slotIndex == pieceIndex) {
      // Doğru yuva!
      setState(() {
        _placedSlots[slotIndex] = pieceIndex;
        _unplacedPieces.remove(pieceIndex);
        _myPlacedCount++;
        _selectedTrayPiece = null;
      });

      HapticFeedback.mediumImpact();
      _sync?.sendPiecePlaced(slotIndex: slotIndex, pieceIndex: pieceIndex);

      if (_placedSlots.length >= _totalPieces) {
        _handleVictory();
      }
    } else {
      // Yanlış yuvaya bırakıldığında nazikçe doğru yuvayı ışıldat
      HapticFeedback.lightImpact();
      setState(() {
        _selectedTrayPiece = pieceIndex;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bu parça #${pieceIndex + 1} numaralı yuvaya ait 🐾 Işıldayan yere dokunabilirsin!'),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSlotTap(int slotIndex) {
    if (_selectedTrayPiece != null) {
      _onSlotDrop(slotIndex, _selectedTrayPiece!);
    }
  }

  void _onPieceTap(int pieceIndex) {
    setState(() {
      if (_selectedTrayPiece == pieceIndex) {
        // İkinci kez aynı parçaya dokunulunca otomatik kendi yuvasına yerleştirilsin!
        _onSlotDrop(pieceIndex, pieceIndex);
      } else {
        _selectedTrayPiece = pieceIndex;
        HapticFeedback.selectionClick();
      }
    });
  }

  void _handleVictory() {
    _isCompleted = true;
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Column(
            children: [
              Text('🏆✨', style: TextStyle(fontSize: 44)),
              SizedBox(height: 6),
              Text(
                'Harika İş Çıkardınız!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Puzzle\'ı başarıyla tamamladınız! 🐾💖',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PokiColors.backgroundOf(ctx),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('⏱️ Toplam Süre:'),
                      Text(
                        _formatTime(_elapsedSeconds),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🐾 Katkı Payı:'),
                      Text(
                        'Sen: $_myPlacedCount · Partner: $_partnerPlacedCount',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sohbete Dön',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PokiColors.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _sync?.sendRestart();
              setState(() {
                _initPieces();
                _startTimer();
              });
            },
            child: const Text('Tekrar Oyna 🔄'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _moveSub?.cancel();
    _restartSub?.cancel();
    _abandonSub?.cancel();
    _sync?.dispose();
    RoomPresence.current?.setActivity(PokiActivity.chatting);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _confirmExit();
        if (canExit && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: PokiColors.backgroundOf(context),
        appBar: AppBar(
          title: const Text('Poki Puzzle 🧩'),
          backgroundColor: PokiColors.backgroundOf(context),
          foregroundColor: PokiColors.textOf(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final canExit = await _confirmExit();
              if (canExit && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                // Üst Durum Çubuğu
                ValueListenableBuilder<bool>(
                  valueListenable:
                      _sync?.partnerPresent ?? ValueNotifier(false),
                  builder: (context, partnerHere, _) {
                    return PuzzleTopBar(
                      mode: widget.config.mode,
                      placed: _placedSlots.length,
                      total: _totalPieces,
                      elapsedSeconds: _elapsedSeconds,
                      showGhostHint: _showGhostHint,
                      onToggleHint: () {
                        setState(() {
                          _showGhostHint = !_showGhostHint;
                        });
                      },
                      partnerHere: partnerHere,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Puzzle Tahtası
                Expanded(
                  child: Center(
                    child: PuzzleBoard(
                      grid: _grid,
                      image: widget.config.image,
                      placedSlots: _placedSlots,
                      placedByPartnerSlots: _placedByPartnerSlots,
                      showGhostHint: _showGhostHint,
                      isCompleted: _isCompleted,
                      onSlotDrop: _onSlotDrop,
                      onSlotTap: _onSlotTap,
                      selectedTrayPiece: _selectedTrayPiece,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Parça Tepsisi
                PieceTray(
                  image: widget.config.image,
                  grid: _grid,
                  unplacedPieces: _unplacedPieces,
                  selectedPiece: _selectedTrayPiece,
                  onPieceTap: _onPieceTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
