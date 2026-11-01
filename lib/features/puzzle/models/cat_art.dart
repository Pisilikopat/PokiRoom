// lib/features/puzzle/models/cat_art.dart
import 'package:flutter/material.dart';

/// Hazır sevimli kedi çizimleri. Şimdilik küçük resim yer tutucusu;
/// gerçek çizimler bir sonraki adımda CustomPainter ile üretilecek (asset dosyası gerekmez).
class CatArt {
  const CatArt(this.id, this.name, this.color);

  final String id;
  final String name;
  final Color color;

  static const List<CatArt> all = [
    CatArt('pamuk', 'Pamuk', Color(0xFFFFE9E3)),
    CatArt('seftali', 'Şeftali', Color(0xFFFFB5A7)),
    CatArt('fistik', 'Fıstık', Color(0xFFE2F0CB)),
    CatArt('kakao', 'Kakao', Color(0xFFD9C3AE)),
    CatArt('bulut', 'Bulut', Color(0xFFD7E8F7)),
    CatArt('limon', 'Limon', Color(0xFFFFE169)),
  ];

  static CatArt? byId(String? id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
