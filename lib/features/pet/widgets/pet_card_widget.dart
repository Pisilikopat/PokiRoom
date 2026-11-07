// lib/features/pet/widgets/pet_card_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/poki_theme.dart';
import '../logic/pet_controller.dart';
import '../models/pet_state.dart';
import '../pet_strings.dart';
import 'action_progress_bar.dart';
import 'bedside_note_dialog.dart';
import 'effects_layer.dart';
import 'pet_history_sheet.dart';
import 'pet_stats_bar.dart';
import 'tuxedo_cat_widget.dart';

class PetCardWidget extends StatelessWidget {
  const PetCardWidget({
    super.key,
    required this.controller,
    this.onTapHeader,
  });

  final PetController controller;
  final VoidCallback? onTapHeader;

  void _showFullNoteDialog(BuildContext context, String note, PetController controller) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🌙', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Başucu Notu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: SelectableText(
              note,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC7D2FE),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.state;
        if (controller.loading && s == null) {
          return Container(
            height: 380,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PokiColors.surfaceOf(context),
              borderRadius: PokiRadius.all,
            ),
            child: const CircularProgressIndicator(),
          );
        }

        final isSleeping = s?.isSleeping ?? false;
        final isBusy = s?.isActionActive ?? false;

        return Container(
          decoration: BoxDecoration(
            color: PokiColors.surfaceOf(context),
            borderRadius: PokiRadius.all,
            boxShadow: PokiShadows.softOf(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ───────────── BAŞLIK ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onTapHeader,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          const Text('🐾', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            s?.petName ?? PetStrings.defaultPetName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İşlem Geçmişi Butonu
                        InkWell(
                          onTap: () => PetHistorySheet.show(context, controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: PokiColors.cardOf(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: PokiColors.borderOf(context)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📜', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  'Geçmiş',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: PokiColors.textOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Uyku Durum Rozeti
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSleeping
                                ? const Color(0xFF312E81)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isSleeping ? '💤 Uyuyor' : '☀️ Uyanık',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSleeping
                                      ? const Color(0xFFC7D2FE)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ───────────── ACTION PROGRESS BAR ─────────────
              ActionProgressBar(
                action: s?.currentAction ?? PetActionKind.idle,
                progress: controller.actionProgress,
              ),

              // ───────────── SAHNE (KEDİ + MİNDER + EFEKTLER) ─────────────
              SizedBox(
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TuxedoCatWidget(
                      action: s?.currentAction ?? PetActionKind.idle,
                      isSleeping: isSleeping,
                      isGrooming: controller.isGrooming,
                      isMeowing: controller.isMeowing,
                    ),
                    Positioned.fill(
                      child: EffectsLayer(
                        isSleeping: isSleeping,
                        sleepNote: s?.sleepNote,
                        speechBubble: controller.speechBubble,
                        heartBurstCount: controller.heartBurstCount,
                        sparkleCount: controller.sparkleCount,
                      ),
                    ),
                  ],
                ),
              ),

              // ───────────── BAŞUCU NOTU KARTI (Uyurken belirgin görünüm) ─────────────
              if (isSleeping && s?.sleepNote != null && s!.sleepNote!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: InkWell(
                    onTap: () => _showFullNoteDialog(context, s.sleepNote!, controller),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Başucu Notu (${s.lastActionBy == controller.myId ? (controller.myNickname.isNotEmpty ? controller.myNickname : "Sen") : controller.partnerNickname})',
                                      style: const TextStyle(
                                        color: Color(0xFFC7D2FE),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Tamamını gör',
                                          style: TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF818CF8)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.sleepNote!.trim(),
                                  style: const TextStyle(
                                    color: Color(0xFFF8FAFC),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ───────────── STAT BARLARI ─────────────
              PetStatsBar(
                stats: controller.stats,
                isSleeping: isSleeping,
              ),

              // ───────────── AKSİYON BUTONLARI ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: isSleeping
                    ? Row(
                        children: [
                          const Expanded(
                            child: Text(
                              PetStrings.sleepingNotice,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(120, 44),
                            ),
                            icon: const Icon(Icons.wb_sunny_rounded, size: 18),
                            label: const Text(PetStrings.wakeButton),
                            onPressed: isBusy ? null : controller.wake,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size(0, 44),
                              ),
                              icon: const Text('🐟', style: TextStyle(fontSize: 16)),
                              label: const Text(PetStrings.feedButton),
                              onPressed: isBusy ? null : controller.feed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size(0, 44),
                              ),
                              icon: const Text('🤚', style: TextStyle(fontSize: 16)),
                              label: const Text(PetStrings.petButton),
                              onPressed: isBusy ? null : controller.pet,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(44, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            icon: const Icon(Icons.bedtime_rounded, size: 18),
                            label: const Text(PetStrings.sleepButton),
                            onPressed: isBusy
                                ? null
                                : () async {
                                    final note = await showDialog<String>(
                                      context: context,
                                      builder: (_) => const BedsideNoteDialog(),
                                    );
                                    if (note != null) {
                                      controller.sleep(note);
                                    }
                                  },
                          ),
                        ],
                      ),
              ),

              // ───────────── ALT BİLGİ (Son İşlem) ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  controller.lastActionFormatted,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
