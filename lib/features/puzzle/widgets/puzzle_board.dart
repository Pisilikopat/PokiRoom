// lib/features/puzzle/widgets/puzzle_board.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/cat_art.dart';
import '../models/puzzle_image_selection.dart';
import 'cat_art_widget.dart';
import 'puzzle_piece_widget.dart';

/// Puzzle tahtası: n x n yuvalardan oluşur. Sürükle-bırak (DragTarget) ve
/// dokun-yerleştir mekanizmasını destekler.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.grid,
    required this.image,
    required this.placedSlots,
    this.placedByPartnerSlots = const {},
    this.showGhostHint = false,
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
        final boardPadding = 10.0;
        final spacing = 4.0;
        final innerSize = availableSize - (boardPadding * 2);
        final slotSize = (innerSize - ((grid - 1) * spacing)) / grid;

        return AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: EdgeInsets.all(boardPadding),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.white.withOpacity(0.9)
                  : PokiColors.surfaceOf(context),
              borderRadius: PokiRadius.all,
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB74D).withOpacity(0.45),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : PokiShadows.softOf(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // İpucu (Hayalet Resim) veya Oyun Sonu Bütünleşmesi
                  if (showGhostHint || isCompleted)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: isCompleted ? 1.0 : 0.22,
                        child: _buildFullGhostArt(innerSize),
                      ),
                    ),

                  // Parça Yuvaları
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: grid,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
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
                      ? const Color(0xFFFFE082).withOpacity(0.3)
                      : (showGhostHint
                          ? Colors.transparent
                          : PokiColors.backgroundOf(context))),
              borderRadius: BorderRadius.circular(size * 0.14),
              border: Border.all(
                color: isHovered
                    ? PokiColors.primaryButton
                    : (isTargetMatch
                        ? const Color(0xFFFFB74D)
                        : PokiColors.textOf(context).withOpacity(0.12)),
                width: isHovered || isTargetMatch ? 2.0 : 1.2,
              ),
            ),
            child: Center(
              child: isHovered
                  ? const Icon(Icons.download_rounded,
                      size: 20, color: PokiColors.primaryButton)
                  : (isTargetMatch
                      ? const Icon(Icons.pets_rounded,
                          size: 16, color: Color(0xFFFFB74D))
                      : Text(
                          '${slotIndex + 1}',
                          style: textTheme.labelSmall?.copyWith(
                            color: PokiColors.textOf(context)
                                .withOpacity(showGhostHint ? 0.35 : 0.18),
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
