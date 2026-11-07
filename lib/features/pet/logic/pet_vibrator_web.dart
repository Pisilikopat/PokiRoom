// lib/features/pet/logic/pet_vibrator_web.dart

import 'dart:js_interop';

@JS('pokiVibrate')
external void _pokiVibrate(JSString patternCsv);

void vibratePet() {
  try {
    _pokiVibrate('80,50,80,50,150'.toJS);
  } catch (_) {}
}

void vibrateFeed() {
  try {
    _pokiVibrate('60,40,70'.toJS);
  } catch (_) {}
}

void vibrateWake() {
  try {
    _pokiVibrate('100,60,120'.toJS);
  } catch (_) {}
}
