// lib/features/pet/logic/pet_vibrator_stub.dart

import 'package:flutter/services.dart';

void vibratePet() {
  try {
    HapticFeedback.selectionClick();
  } catch (_) {}
}

void vibrateFeed() {
  try {
    HapticFeedback.lightImpact();
  } catch (_) {}
}

void vibrateWake() {
  try {
    HapticFeedback.mediumImpact();
  } catch (_) {}
}
