// lib/features/pet/logic/pet_math.dart

import 'dart:math' as math;
import '../models/pet_state.dart';

class PetStats {
  const PetStats({
    required this.hunger,
    required this.affection,
    required this.energy,
  });

  final int hunger;
  final int affection;
  final int energy;

  bool get isHungry => hunger < 15;
  bool get isTired => energy < 15;
}

class PetMath {
  const PetMath._();

  // Uyanıkken decay süreleri (dakika başına -1 puan)
  static const double awakeHungerMinutes = 6.0;
  static const double awakeAffectionMinutes = 8.0;
  static const double awakeEnergyMinutes = 10.0;

  // Uyurken decay süreleri
  static const double sleepEnergyGainMinutes = 1.5; // Her 1.5 dakikada +1 enerji
  static const double sleepHungerMinutes = 20.0; // Her 20 dakikada -1 tokluk

  static PetStats computeStats(PetState state, DateTime now) {
    final deltaMins = now.difference(state.statsUpdatedAt).inSeconds / 60.0;
    if (deltaMins <= 0) {
      return PetStats(
        hunger: state.hunger.clamp(0, 100),
        affection: state.affection.clamp(0, 100),
        energy: state.energy.clamp(0, 100),
      );
    }

    if (state.isSleeping) {
      final newEnergy = (state.energy + (deltaMins / sleepEnergyGainMinutes).floor()).clamp(0, 100);
      final newHunger = (state.hunger - (deltaMins / sleepHungerMinutes).floor()).clamp(0, 100);
      final newAffection = state.affection.clamp(0, 100);

      return PetStats(
        hunger: newHunger,
        affection: newAffection,
        energy: newEnergy,
      );
    } else {
      final newHunger = (state.hunger - (deltaMins / awakeHungerMinutes).floor()).clamp(0, 100);
      final newAffection = (state.affection - (deltaMins / awakeAffectionMinutes).floor()).clamp(0, 100);
      final newEnergy = (state.energy - (deltaMins / awakeEnergyMinutes).floor()).clamp(0, 100);

      return PetStats(
        hunger: newHunger,
        affection: newAffection,
        energy: newEnergy,
      );
    }
  }
}
