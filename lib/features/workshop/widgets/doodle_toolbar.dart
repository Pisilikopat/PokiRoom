// lib/features/workshop/widgets/doodle_toolbar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../shared/widgets/poki_card.dart';
import '../doodle_controller.dart';

/// Renk paleti, fırça kalınlığı, geri al ve temizle.
class DoodleToolbar extends StatelessWidget {
  const DoodleToolbar({
    super.key,
    required this.controller,
    this.onClearRequested,
  });

  final DoodleController controller;

  /// Verilirse "Temizle" bunu çağırır (örn. onay penceresi için).
  final Future<void> Function()? onClearRequested;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final previewSize = (controller.width * 450).clamp(4.0, 28.0).toDouble();
        return PokiCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: DoodlePalette.colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final c = DoodlePalette.colors[i];
                    final selected = c.toARGB32() == controller.color.toARGB32();
                    return GestureDetector(
                      onTap: () => controller.setColor(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? PokiColors.text
                                : PokiColors.text.withOpacity(0.15),
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Container(
                        width: previewSize,
                        height: previewSize,
                        decoration: BoxDecoration(
                          color: controller.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PokiColors.text.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: controller.width,
                      min: DoodleController.minWidth,
                      max: DoodleController.maxWidth,
                      activeColor: PokiColors.primaryButton,
                      inactiveColor: PokiColors.primary.withOpacity(0.3),
                      onChanged: controller.setWidth,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Geri al',
                    icon: const Icon(Icons.undo_rounded),
                    onPressed: controller.canUndo ? controller.undo : null,
                  ),
                  IconButton(
                    tooltip: 'Temizle',
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: controller.isEmpty
                        ? null
                        : () {
                            if (onClearRequested != null) {
                              onClearRequested!();
                            } else {
                              controller.clear();
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
