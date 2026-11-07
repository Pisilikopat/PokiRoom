// lib/features/pet/widgets/pet_history_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/theme/poki_theme.dart';
import '../logic/pet_controller.dart';
import '../models/pet_event.dart';

class PetHistorySheet extends StatefulWidget {
  const PetHistorySheet({
    super.key,
    required this.controller,
  });

  final PetController controller;

  static Future<void> show(BuildContext context, PetController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PetHistorySheet(controller: controller),
    );
  }

  @override
  State<PetHistorySheet> createState() => _PetHistorySheetState();
}

class _PetHistorySheetState extends State<PetHistorySheet> {
  late Future<List<PetEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.fetchHistory();
  }

  void _reload() {
    setState(() {
      _future = widget.controller.fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = PokiColors.surfaceOf(context);
    final textCol = PokiColors.textOf(context);
    final ctrl = widget.controller;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutma çubuğu
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Üst Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
            child: Row(
              children: [
                const Text('📜', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kedi İşlem Geçmişi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ctrl.myNickname} & ${ctrl.partnerNickname} bakım günlüğü',
                        style: TextStyle(
                          fontSize: 12,
                          color: textCol.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Yenile',
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: _reload,
                ),
                IconButton(
                  tooltip: 'Kapat',
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Liste Görünümü
          Flexible(
            child: FutureBuilder<List<PetEvent>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    widget.controller.history.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final events = (snapshot.data != null && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : widget.controller.history;

                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🐾', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz işlem kaydı yok',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kediyi besleyerek, severek veya başucuna not bırakıp uyutarak ortak anılar oluşturun!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: textCol.withOpacity(0.65),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ev = events[index];
                    return _buildEventItem(context, ev, ctrl, textCol);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    PetEvent ev,
    PetController ctrl,
    Color textCol,
  ) {
    Color badgeBg;
    Color badgeText;
    Color iconCircleBg;

    switch (ev.type) {
      case 'feed':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        iconCircleBg = const Color(0xFFFDE68A);
        break;
      case 'pet':
        badgeBg = const Color(0xFFFCE7F3);
        badgeText = const Color(0xFFBE185D);
        iconCircleBg = const Color(0xFFFBCFE8);
        break;
      case 'sleep':
        badgeBg = const Color(0xFFEEF2FF);
        badgeText = const Color(0xFF4338CA);
        iconCircleBg = const Color(0xFFE0E7FF);
        break;
      case 'wake':
      default:
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF047857);
        iconCircleBg = const Color(0xFFA7F3D0);
        break;
    }

    final actorName = ev.formattedActor(ctrl.myId, ctrl.myNickname, ctrl.partnerNickname);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PokiColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PokiColors.textOf(context).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // İkon dairesi
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  ev.actionEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),

              // Aktör ve Eylem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            actorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ev.actionTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: textCol.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ev.timeAgo} • ${ev.formattedTime}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textCol.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Rozet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ev.effectBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),

          // Başucu notu varsa göster
          if (ev.note != null && ev.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF312E81).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      ev.note!.trim(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: textCol.withOpacity(0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
