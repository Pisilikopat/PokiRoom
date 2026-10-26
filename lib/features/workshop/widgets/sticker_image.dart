// lib/features/workshop/widgets/sticker_image.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/repositories/sticker_repository.dart';

/// Sticker id'sinden görseli yükleyip gösterir (Image.memory; web + mobil uyumlu).
class StickerImage extends StatefulWidget {
  const StickerImage({super.key, required this.stickerId, this.size});

  final String stickerId;
  final double? size;

  @override
  State<StickerImage> createState() => _StickerImageState();
}

class _StickerImageState extends State<StickerImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = StickerRepository.instance.imageBytes(widget.stickerId);
  }

  @override
  void didUpdateWidget(covariant StickerImage old) {
    super.didUpdateWidget(old);
    if (old.stickerId != widget.stickerId) {
      _future = StickerRepository.instance.imageBytes(widget.stickerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        }
        if (snapshot.hasError) {
          return GestureDetector(
            onTap: () => setState(() {
              _future = StickerRepository.instance.imageBytes(widget.stickerId);
            }),
            child: Center(
              child: Text('🐾\nYenile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          );
        }
        return Center(
          child: Icon(Icons.pets_rounded,
              color: PokiColors.primary.withOpacity(0.5)),
        );
      },
    );
    final size = widget.size;
    return size == null ? child : SizedBox(width: size, height: size, child: child);
  }
}
