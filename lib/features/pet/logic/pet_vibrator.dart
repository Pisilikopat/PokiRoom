// lib/features/pet/logic/pet_vibrator.dart

import 'package:flutter/services.dart';
import 'pet_vibrator_stub.dart'
    if (dart.library.js_interop) 'pet_vibrator_web.dart' as vibrator;

class PetVibrator {
  const PetVibrator._();

  /// Sevme titreşimi (Mrrr~ kalp atışı ritmi: pıt-pıt-pıııt)
  static void pet() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    vibrator.vibratePet();
  }

  /// Besleme titreşimi (çıtır çıtır balık atıştırması)
  static void feed() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    vibrator.vibrateFeed();
  }

  /// Uyandırma titreşimi (neşeli uyanış)
  static void wake() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    vibrator.vibrateWake();
  }
}
