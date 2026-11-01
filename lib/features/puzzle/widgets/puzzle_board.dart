// lib/features/puzzle/widgets/puzzle_board.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Tahta İSKELETİ: n x n boş yuva. Parçalar, sürükle-bırak, manyetik oturma ve
/// animasyonlar sonraki adımlarda eklenecek.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({super.key, required this.grid});

  final int grid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: PokiColors.surfaceOf(context),
          borderRadius: PokiRadius.all,
          boxShadow: PokiShadows.softOf(context),
        ),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: grid,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < grid * grid; i++)
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PokiColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PokiColors.textOf(context).withOpacity(0.12),
                    width: 1.5,
                  ),
                ),
                child: Text('${i + 1}',
                    style: textTheme.labelMedium?.copyWith(
                        color: PokiColors.textOf(context).withOpacity(0.25))),
              ),
          ],
        ),
      ),
    );
  }
}
