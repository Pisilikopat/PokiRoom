// lib/features/puzzle/widgets/puzzle_piece_widget.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/cat_art.dart';
import '../models/puzzle_image_selection.dart';
import 'cat_art_widget.dart';

/// Belirtilen parça indeksine ait görsel dilimini çizen evrensel parça bileşeni.
/// Tahtaya yerleştirildiğinde kenarlarla kusursuz ve sıfır boşlukla birleşir;
/// tepsideyken ise tutulabilir, sevimli yuvarlak köşeli bir kart görünümü sunar.
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

    // Tahtaya yerleştiğinde dikişsiz olması için iç köşeler düzdür.
    // Tepside veya sürüklenirken sevimli kart görünümü için yuvarlatılır.
    final radius = isPlaced
        ? BorderRadius.zero
        : BorderRadius.circular(size * 0.16);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : (isPlaced ? null : PokiShadows.softOf(context)),
      ),
      child: ClipRRect(
        borderRadius: radius,
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
                    borderRadius: radius,
                    border: Border.all(
                      color: isPlaced
                          ? (placedByPartner
                              ? const Color(0xFF81C784)
                              : Colors.white.withOpacity(0.20))
                          : Colors.white.withOpacity(0.85),
                      width: isPlaced ? 0.5 : 2.0,
                    ),
                  ),
                ),
              ),

            // Tepsideyken parça numara rozeti (#1, #2...)
            if (!isPlaced)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.48),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${pieceIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

            // Partner yerleştirdiğinde tatlı yeşil pati rozeti
            if (isPlaced && placedByPartner)
              Positioned(
                right: 3,
                bottom: 3,
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
