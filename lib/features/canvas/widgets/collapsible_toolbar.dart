// lib/features/canvas/widgets/collapsible_toolbar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../models/drawing_stroke.dart';

class CollapsibleToolbar extends StatelessWidget {
  const CollapsibleToolbar({
    super.key,
    required this.isExpanded,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
    required this.opacity,
    required this.onToggleExpanded,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onWidthChanged,
    required this.onOpacityChanged,
  });

  final bool isExpanded;
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final double opacity;
  final ValueChanged<bool> onToggleExpanded;
  final ValueChanged<DrawingTool> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onOpacityChanged;

  static const List<Color> palette = [
    Color(0xFFE88A9A), // Poki Pembesi
    Color(0xFFF8A978), // Sıcak Şeftali
    Color(0xFFF6D186), // Krem Limon
    Color(0xFFA8D5BA), // Nane Yeşili
    Color(0xFF95B8D1), // Bebek Mavisi
    Color(0xFFB8A9C9), // Pastel Lavanta
    Color(0xFF8B5E3C), // Sütlü Kakao
    Color(0xFF383331), // Sıcak Kömür
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: isExpanded ? _buildExpanded(context) : _buildCollapsed(context),
    );
  }

  /// Katlanmış, minik floating hap (Mobil ekranı ferah tutar)
  Widget _buildCollapsed(BuildContext context) {
    final subtextColor = PokiColors.textOf(context).withOpacity(0.6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onToggleExpanded(true),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PokiColors.surfaceOf(context).withOpacity(0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: PokiColors.textOf(context).withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedTool.icon,
                size: 20,
                color: selectedTool.isEraser ? subtextColor : selectedColor,
              ),
              const SizedBox(width: 8),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: subtextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Açık, tüm fırça ve renk araçlarını gösteren tatlı panel
  Widget _buildExpanded(BuildContext context) {
    final subtextColor = PokiColors.textOf(context).withOpacity(0.6);

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PokiColors.textOf(context).withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Satır: Araçlar & Kapat Butonu
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: DrawingTool.values.map((tool) {
                      final isSelected = selectedTool == tool;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => onToolSelected(tool),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? PokiColors.primaryButton.withOpacity(0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? PokiColors.primaryButton
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tool.icon,
                                  size: 18,
                                  color: isSelected
                                      ? PokiColors.primaryButton
                                      : subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tool.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? PokiColors.primaryButton
                                        : subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                tooltip: 'Gizle',
                onPressed: () => onToggleExpanded(false),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Satır: Renk Paleti
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: palette.map((color) {
                final isSelected = selectedColor == color;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.black.withOpacity(0.1),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 3. Satır: Fırça Kalınlığı Slider + Canlı Önizleme
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Container(
                  width: strokeWidth.clamp(3.0, 22.0),
                  height: strokeWidth.clamp(3.0, 22.0),
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: PokiColors.primaryButton,
                    thumbColor: PokiColors.primaryButton,
                  ),
                  child: Slider(
                    value: strokeWidth,
                    min: 1.5,
                    max: 32.0,
                    onChanged: onWidthChanged,
                  ),
                ),
              ),
              Text(
                '${strokeWidth.toInt()} px',
                style: TextStyle(fontSize: 11, color: subtextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
