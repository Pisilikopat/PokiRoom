// lib/features/puzzle/widgets/piece_tray.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../shared/widgets/poki_card.dart';
import '../models/puzzle_image_selection.dart';
import 'puzzle_piece_widget.dart';

/// Parça tepsisi: Karışık haldeki parçaların yatay kaydırılabilir listesi.
/// Hem sürükle-bırak (Draggable) hem de dokun-yerleştir mekanizmasını destekler.
class PieceTray extends StatelessWidget {
  const PieceTray({
    super.key,
    required this.image,
    required this.grid,
    required this.unplacedPieces,
    this.selectedPiece,
    this.onPieceTap,
  });

  final PuzzleImageSelection image;
  final int grid;
  final List<int> unplacedPieces;
  final int? selectedPiece;
  final ValueChanged<int>? onPieceTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pieceSize = 64.0;

    return PokiCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🐾 Kalan Parçalar (${unplacedPieces.length})',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (selectedPiece != null)
                Text(
                  'Yuvasına veya tekrar dokun ➔',
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: pieceSize + 8,
            child: unplacedPieces.isEmpty
                ? Center(
                    child: Text(
                      'Tüm parçalar yerleştirildi! 🎉',
                      style: textTheme.bodyMedium?.copyWith(
                        color: PokiColors.primaryButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unplacedPieces.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final pieceIndex = unplacedPieces[i];
                      final isSelected = selectedPiece == pieceIndex;

                      final pieceWidget = PuzzlePieceWidget(
                        image: image,
                        grid: grid,
                        pieceIndex: pieceIndex,
                        size: pieceSize,
                        isPlaced: false,
                        showBorder: true,
                      );

                      return GestureDetector(
                        onTap: () => onPieceTap?.call(pieceIndex),
                        child: Draggable<int>(
                          data: pieceIndex,
                          feedback: Material(
                            type: MaterialType.transparency,
                            child: Transform.scale(
                              scale: 1.15,
                              child: Opacity(
                                opacity: 0.9,
                                child: PuzzlePieceWidget(
                                  image: image,
                                  grid: grid,
                                  pieceIndex: pieceIndex,
                                  size: pieceSize * 1.1,
                                  isDragging: true,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.25,
                            child: pieceWidget,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(pieceSize * 0.16),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFFFFB74D),
                                      width: 2.5,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      const BoxShadow(
                                        color: Color(0x66FFB74D),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: pieceWidget,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
