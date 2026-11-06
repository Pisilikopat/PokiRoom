// lib/features/pet/widgets/pet_card_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/poki_theme.dart';
import '../logic/pet_controller.dart';
import '../models/pet_state.dart';
import '../pet_strings.dart';
import 'action_progress_bar.dart';
import 'bedside_note_dialog.dart';
import 'effects_layer.dart';
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

              // ───────────── STAT BARLARI (Tokluk, Mutluluk, Enerji) ─────────────
              PetStatsBar(stats: controller.stats),

              // ───────────── BUTONLAR ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: isSleeping
                    ? Row(
                        children: [
                          const Expanded(
                            child: Text(
                              PetStrings.sleepingNotice,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
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
