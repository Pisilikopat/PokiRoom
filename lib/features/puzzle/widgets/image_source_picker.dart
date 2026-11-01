// lib/features/puzzle/widgets/image_source_picker.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/cat_art.dart';
import '../models/puzzle_image_selection.dart';

/// Görsel kaynağı: Galeri / Kedi çizimleri / Anılar (yakında).
class ImageSourcePicker extends StatefulWidget {
  const ImageSourcePicker({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  final PuzzleImageSelection? selection;
  final ValueChanged<PuzzleImageSelection?> onChanged;

  @override
  State<ImageSourcePicker> createState() => _ImageSourcePickerState();
}

class _ImageSourcePickerState extends State<ImageSourcePicker> {
  PuzzleImageSourceType _tab = PuzzleImageSourceType.cat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _TabButton(
              label: 'Galeri',
              icon: Icons.photo_library_rounded,
              selected: _tab == PuzzleImageSourceType.gallery,
              onTap: () => setState(() => _tab = PuzzleImageSourceType.gallery),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Kediler',
              icon: Icons.pets_rounded,
              selected: _tab == PuzzleImageSourceType.cat,
              onTap: () => setState(() => _tab = PuzzleImageSourceType.cat),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Anılar',
              icon: Icons.push_pin_rounded,
              selected: _tab == PuzzleImageSourceType.memory,
              onTap: () => setState(() => _tab = PuzzleImageSourceType.memory),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_tab) {
            PuzzleImageSourceType.gallery =>
              const _GalleryCard(key: ValueKey('gallery')),
            PuzzleImageSourceType.cat => _CatGrid(
                key: const ValueKey('cat'),
                selectedId: widget.selection?.catId,
                onSelect: (id) => widget.onChanged(PuzzleImageSelection.cat(id)),
              ),
            PuzzleImageSourceType.memory =>
              const _MemoryCard(key: ValueKey('memory')),
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? PokiColors.primary : PokiColors.surfaceOf(context),
        borderRadius: PokiRadius.all,
        child: InkWell(
          borderRadius: PokiRadius.all,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PokiColors.surfaceOf(context),
      borderRadius: PokiRadius.all,
      child: InkWell(
        borderRadius: PokiRadius.all,
        onTap: () {
          // TODO(adım 2): image_picker ile galeriden seç, Uint8List olarak oku.
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Galeriden seçme bir sonraki adımda geliyor 📷'),
            ));
        },
        child: Container(
          height: 150,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_photo_alternate_rounded,
                  size: 44, color: PokiColors.primaryButton),
              const SizedBox(height: 8),
              Text('Anı fotoğrafını yükle',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('Galerinden bir fotoğraf seç',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatGrid extends StatelessWidget {
  const _CatGrid({super.key, required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final cat in CatArt.all)
          GestureDetector(
            onTap: () => onSelect(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: PokiRadius.all,
                border: Border.all(
                  color: selectedId == cat.id
                      ? PokiColors.textOf(context)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: PokiShadows.softOf(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(cat.name,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context).withOpacity(0.6),
        borderRadius: PokiRadius.all,
      ),
      child: Text(
        'Yakında: Anılar panosundan bir görsel seçebileceksin 📌',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
