// lib/features/puzzle/widgets/puzzle_board.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/cat_art.dart';
import '../models/puzzle_image_selection.dart';
import 'cat_art_widget.dart';
import 'puzzle_piece_widget.dart';

/// Puzzle tahtası: n x n yuvalardan oluşur. Sürükle-bırak (DragTarget) ve
/// dokun-yerleştir mekanizmasını destekler.
/// Parçalar arasında sıfır piksel boşluk bulunur; yerleşen parçalar tahtadaki
/// hayalet görsel ile piksel piksel kusursuz örtüşür.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.grid,
    required this.image,
    required this.placedSlots,
    this.placedByPartnerSlots = const {},
    this.showGhostHint = true,
    this.isCompleted = false,
    required this.onSlotDrop,
    this.onSlotTap,
    this.selectedTrayPiece,
  });

  final int grid;
  final PuzzleImageSelection image;
  final Map<int, int> placedSlots;
  final Set<int> placedByPartnerSlots;
  final bool showGhostHint;
  final bool isCompleted;
  final void Function(int slotIndex, int pieceIndex) onSlotDrop;
  final void Function(int slotIndex)? onSlotTap;
  final int? selectedTrayPiece;

  Widget _buildFullGhostArt(double boardSize) {
    if (image.type == PuzzleImageSourceType.cat) {
      final cat = CatArt.byId(image.catId) ?? CatArt.all.first;
      return CatArtWidget(cat: cat, size: boardSize);
    }
    if (image.type == PuzzleImageSourceType.gallery && image.bytes != null) {
      return Image.memory(
        image.bytes!,
        width: boardSize,
        height: boardSize,
        fit: BoxFit.cover,
      );
    }
    final cat = CatArt.all.first;
    return CatArtWidget(cat: cat, size: boardSize);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSize = constraints.maxWidth;
        const boardPadding = 8.0;
        final innerSize = availableSize - (boardPadding * 2);
        final slotSize = innerSize / grid;

        return AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(boardPadding),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.white.withOpacity(0.95)
                  : PokiColors.surfaceOf(context),
              borderRadius: PokiRadius.all,
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB74D).withOpacity(0.50),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ]
                  : PokiShadows.softOf(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // İpucu (Hayalet Resim): Oyun oynanırken tahtada hafif bir rehber olarak belirir,
                  // böylece oyuncu ne yaptığını ve hangi parçanın nereye geldiğini net görür.
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: isCompleted
                          ? 1.0
                          : (showGhostHint ? 0.36 : 0.14),
                      child: _buildFullGhostArt(innerSize),
                    ),
                  ),

                  // Parça Yuvaları (Sıfır piksel aralık ile kesintisiz bütünleşme)
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: grid,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    children: [
                      for (var i = 0; i < grid * grid; i++)
                        _buildSlot(
                          context,
                          slotIndex: i,
                          size: slotSize,
                          textTheme: textTheme,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlot(
    BuildContext context, {
    required int slotIndex,
    required double size,
    required TextTheme textTheme,
  }) {
    final isFilled = placedSlots.containsKey(slotIndex);

    // Dolu yuva: Yerleştirilmiş parça gösterilir
    if (isFilled) {
      final pieceIndex = placedSlots[slotIndex]!;
      final byPartner = placedByPartnerSlots.contains(slotIndex);

      return AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: PuzzlePieceWidget(
          image: image,
          grid: grid,
          pieceIndex: pieceIndex,
          size: size,
          isPlaced: true,
          placedByPartner: byPartner,
          showBorder: !isCompleted,
        ),
      );
    }

    // Boş yuva: DragTarget ve Tıklanabilir alan
    final isTargetMatch = selectedTrayPiece == slotIndex;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => !isFilled,
      onAcceptWithDetails: (details) {
        onSlotDrop(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => onSlotTap?.call(slotIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovered
                  ? PokiColors.primaryButton.withOpacity(0.35)
                  : (isTargetMatch
                      ? const Color(0x40FFA726)
                      : (showGhostHint
                          ? Colors.transparent
                          : PokiColors.backgroundOf(context).withOpacity(0.4))),
              border: Border.all(
                color: isHovered
                    ? PokiColors.primaryButton
                    : (isTargetMatch
                        ? const Color(0xFFFF9800)
                        : Colors.white.withOpacity(0.28)),
                width: isHovered || isTargetMatch ? 2.0 : 0.5,
              ),
            ),
            child: Center(
              child: isHovered
                  ? const Icon(Icons.download_rounded,
                      size: 20, color: PokiColors.primaryButton)
                  : (isTargetMatch
                      ? const Icon(Icons.pets_rounded,
                          size: 18, color: Color(0xFFFF9800))
                      : Text(
                          '${slotIndex + 1}',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.45),
                            fontWeight: FontWeight.bold,
                          ),
                        )),
            ),
          ),
        );
      },
    );
  }
}
