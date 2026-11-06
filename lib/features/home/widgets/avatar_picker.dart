// lib/features/home/widgets/avatar_picker.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

/// Web-uyumlu profil fotoğrafı seçici.
/// Web'de file_picker kullanılmadan sadece gösterim yapar;
/// Fotoğraf yükleme desteği ileride eklenecek.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    String? imageUrl,
    String? avatarUrl,
    required this.onPicked,
  }) : imageUrl = imageUrl ?? avatarUrl;

  final String? imageUrl;
  final void Function(Uint8List bytes) onPicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı desteği yakında geliyor 🐾'),
            ),
          );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: PokiColors.surface,
            backgroundImage: (imageUrl != null && imageUrl!.trim().isNotEmpty)
                ? NetworkImage(imageUrl!)
                : null,
            onBackgroundImageError: (imageUrl != null && imageUrl!.trim().isNotEmpty)
                ? (exception, stackTrace) {
                    // Avatar URL'i 400 dönerse veya bucket henüz yoksa güvenle yut ve pati ikonuna dön
                  }
                : null,
            child: (imageUrl == null || imageUrl!.trim().isEmpty)
                ? const Icon(Icons.pets_rounded,
                    size: 32, color: PokiColors.primary)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PokiColors.primaryButton,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PokiColors.backgroundOf(context),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
