// lib/features/room/widgets/chat_search_bar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onClose,
    this.totalMatches = 0,
    this.currentMatchIndex = -1,
    this.onPrevMatch,
    this.onNextMatch,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClose;
  final int totalMatches;
  final int currentMatchIndex;
  final VoidCallback? onPrevMatch;
  final VoidCallback? onNextMatch;
  final bool isLoading;

  static const _filters = [
    ('all', '🐾 Tümü'),
    ('text', '📝 Yazılar'),
    ('voice', '🎙️ Sesliler'),
    ('foggy', '🌫️ Buğulu'),
    ('sticker', '🐱 Çıkartmalar'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = PokiColors.surfaceOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PokiRadius.card),
        ),
        boxShadow: PokiShadows.softOf(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst arama kutusu ve Kapat butonu
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: PokiColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: PokiColors.textOf(context).withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Sohbette ara... 🐾',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: PokiColors.textOf(context).withOpacity(0.45),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: PokiColors.primaryButton,
                          ),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    onQueryChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onChanged: onQueryChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onClose,
                    style: TextButton.styleFrom(
                      foregroundColor: PokiColors.primaryButton,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filtre hapları (Filter Chips)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final (key, label) = _filters[index];
                    final isSelected = selectedFilter == key;

                    return GestureDetector(
                      onTap: () => onFilterChanged(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PokiColors.primaryButton
                              : PokiColors.backgroundOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? PokiColors.primaryButton
                                : PokiColors.textOf(context).withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : PokiColors.textOf(context)
                                    .withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Arama durumu / Navigasyon çubuğu
              if (isLoading ||
                  controller.text.trim().isNotEmpty ||
                  selectedFilter != 'all') ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PokiColors.backgroundOf(context).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isLoading) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PokiColors.primaryButton,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aranıyor... 🐾',
                              style: textTheme.bodySmall?.copyWith(
                                color: PokiColors.textOf(context)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ] else if (totalMatches > 0) ...[
                        Text(
                          '🐾 ${currentMatchIndex + 1} / $totalMatches sonuç',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PokiColors.textOf(context),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 22),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Önceki Eşleşme',
                              onPressed: onPrevMatch,
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 22),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Sonraki Eşleşme',
                              onPressed: onNextMatch,
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '😿 Eşleşen mesaj bulunamadı',
                          style: textTheme.bodySmall?.copyWith(
                            color: PokiColors.textOf(context)
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
