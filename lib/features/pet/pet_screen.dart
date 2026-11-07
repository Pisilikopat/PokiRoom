// lib/features/pet/pet_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import 'logic/pet_controller.dart';
import 'pet_strings.dart';
import 'widgets/pet_card_widget.dart';
import 'widgets/pet_history_sheet.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({
    super.key,
    required this.roomId,
    this.myNickname = 'Sen',
    this.partnerNickname = 'Partnerin',
  });

  final String roomId;
  final String myNickname;
  final String partnerNickname;

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late final PetController _controller;

  @override
  void initState() {
    super.initState();
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _controller = PetController(
      roomId: widget.roomId,
      myId: myId,
      myNickname: widget.myNickname,
      partnerNickname: widget.partnerNickname,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokiColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: PokiColors.backgroundOf(context),
        foregroundColor: PokiColors.textOf(context),
        elevation: 0,
        title: Row(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              PetStrings.title,
              style: TextStyle(
                color: PokiColors.textOf(context),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'İşlem Geçmişi',
            icon: const Icon(Icons.history_rounded, size: 24),
            onPressed: () => PetHistorySheet.show(context, _controller),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PetCardWidget(controller: _controller),
            const SizedBox(height: 14),

            // İşlem Geçmişi Hızlı Kartı
            InkWell(
              onTap: () => PetHistorySheet.show(context, _controller),
              borderRadius: PokiRadius.all,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: PokiColors.surfaceOf(context),
                  borderRadius: PokiRadius.all,
                  boxShadow: PokiShadows.softOf(context),
                  border: Border.all(
                    color: PokiColors.textOf(context).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('📜', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İşlem Geçmişi',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: PokiColors.textOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ne zaman ne yaptınız? Tüm besleme, sevgi ve notlar',
                            style: TextStyle(
                              fontSize: 12,
                              color: PokiColors.textOf(context).withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: PokiColors.textOf(context).withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bilgi ve İpucu Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PokiColors.surfaceOf(context),
                borderRadius: PokiRadius.all,
                boxShadow: PokiShadows.softOf(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_controller.myNickname} & ${_controller.partnerNickname} Bakım Rehberi',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _guideItem('🍖', 'Tokluk', 'Zamanla yavaşça azalır (-1 / 6 dk). Balıkla besleyin (+25).'),
                  const SizedBox(height: 8),
                  _guideItem('❤️', 'Mutluluk', 'Sevgi azaldıkça düşer (-1 / 8 dk). Sevin ve mırıldatın (+20).'),
                  const SizedBox(height: 8),
                  _guideItem('⚡', 'Enerji', 'Kedi uyanıkken yorulur. Başucuna not bırakıp uyutursanız dinlenerek dolar!'),
                  const SizedBox(height: 8),
                  _guideItem('🛡️', 'Cezasız Kural', 'Kedi asla ölmez; aç veya uykusuz kaldığında sadece tatlı ipuçları verir.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideItem(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5, color: PokiColors.textOf(context).withOpacity(0.85)),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
