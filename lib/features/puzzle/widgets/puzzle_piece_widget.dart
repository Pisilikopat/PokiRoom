// lib/features/puzzle/widgets/puzzle_piece_widget.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/cat_art.dart';
import '../models/puzzle_image_selection.dart';
import 'cat_art_widget.dart';

/// Belirtilen parça indeksine ait görsel dilimini çizen evrensel parça bileşeni.
class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.image,
    required this.grid,
    required this.pieceIndex,
    required this.size,
    this.isPlaced = false,
    this.placedByPartner = false,
    this.isDragging = false,
    this.showBorder = true,
  });

  final PuzzleImageSelection image;
  final int grid;
  final int pieceIndex;
  final double size;
  final bool isPlaced;
  final bool placedByPartner;
  final bool isDragging;
  final bool showBorder;

  Widget _buildArtwork(double totalSize) {
    if (image.type == PuzzleImageSourceType.cat) {
      final cat = CatArt.byId(image.catId) ?? CatArt.all.first;
      return CatArtWidget(cat: cat, size: totalSize);
    }

    if (image.type == PuzzleImageSourceType.gallery && image.bytes != null) {
      return Image.memory(
        image.bytes!,
        width: totalSize,
        height: totalSize,
        fit: BoxFit.cover,
      );
    }

    final cat = CatArt.all.first;
    return CatArtWidget(cat: cat, size: totalSize);
  }

  @override
  Widget build(BuildContext context) {
    final row = pieceIndex ~/ grid;
    final col = pieceIndex % grid;
    final totalSize = size * grid;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.14),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : (isPlaced ? null : PokiShadows.softOf(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: Stack(
          children: [
            // Dilimlenmiş görsel
            Positioned(
              left: -col * size,
              top: -row * size,
              width: totalSize,
              height: totalSize,
              child: _buildArtwork(totalSize),
            ),

            // Parça kenarlığı
            if (showBorder)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.14),
                    border: Border.all(
                      color: isPlaced
                          ? (placedByPartner
                              ? const Color(0xFF81C784)
                              : Colors.white.withOpacity(0.35))
                          : Colors.white.withOpacity(0.7),
                      width: isPlaced ? 1.5 : 2.0,
                    ),
                  ),
                ),
              ),

            // Partner yerleştirdiğinde tatlı yeşil pati rozeti
            if (isPlaced && placedByPartner)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xDD81C784),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
