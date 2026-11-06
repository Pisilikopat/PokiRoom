// lib/features/pet/models/pet_state.dart

enum PetActionKind {
  idle,
  eating,
  petting,
}

extension PetActionKindExt on PetActionKind {
  static PetActionKind fromString(String? val) {
    switch (val) {
      case 'eating':
        return PetActionKind.eating;
      case 'petting':
        return PetActionKind.petting;
      default:
        return PetActionKind.idle;
    }
  }

  String get nameStr {
    switch (this) {
      case PetActionKind.eating:
        return 'eating';
      case PetActionKind.petting:
        return 'petting';
      case PetActionKind.idle:
        return 'idle';
    }
  }
}

class PetState {
  const PetState({
    required this.roomId,
    this.petName = 'Mırnav',
    this.hunger = 70,
    this.affection = 70,
    this.energy = 80,
    required this.statsUpdatedAt,
    this.isSleeping = false,
    this.sleepNote,
    this.sleepStartedAt,
    this.currentAction = PetActionKind.idle,
    this.actionEndsAt,
    this.lastActionBy,
    this.lastActionType,
    this.lastActionAt,
  });

  final String roomId;
  final String petName;
  final int hunger;
  final int affection;
  final int energy;
  final DateTime statsUpdatedAt;
  final bool isSleeping;
  final String? sleepNote;
  final DateTime? sleepStartedAt;
  final PetActionKind currentAction;
  final DateTime? actionEndsAt;
  final String? lastActionBy;
  final String? lastActionType;
  final DateTime? lastActionAt;

  bool get isActionActive {
    if (currentAction == PetActionKind.idle) return false;
    if (actionEndsAt == null) return false;
    return actionEndsAt!.isAfter(DateTime.now());
  }

  PetState copyWith({
    String? roomId,
    String? petName,
    int? hunger,
    int? affection,
    int? energy,
    DateTime? statsUpdatedAt,
    bool? isSleeping,
    String? sleepNote,
    DateTime? sleepStartedAt,
    PetActionKind? currentAction,
    DateTime? actionEndsAt,
    String? lastActionBy,
    String? lastActionType,
    DateTime? lastActionAt,
  }) {
    return PetState(
      roomId: roomId ?? this.roomId,
      petName: petName ?? this.petName,
      hunger: hunger ?? this.hunger,
      affection: affection ?? this.affection,
      energy: energy ?? this.energy,
      statsUpdatedAt: statsUpdatedAt ?? this.statsUpdatedAt,
      isSleeping: isSleeping ?? this.isSleeping,
      sleepNote: sleepNote ?? this.sleepNote,
      sleepStartedAt: sleepStartedAt ?? this.sleepStartedAt,
      currentAction: currentAction ?? this.currentAction,
      actionEndsAt: actionEndsAt ?? this.actionEndsAt,
      lastActionBy: lastActionBy ?? this.lastActionBy,
      lastActionType: lastActionType ?? this.lastActionType,
      lastActionAt: lastActionAt ?? this.lastActionAt,
    );
  }

  factory PetState.fromMap(Map<String, dynamic> map) {
    return PetState(
      roomId: map['room_id'] as String,
      petName: (map['pet_name'] as String?) ?? 'Mırnav',
      hunger: (map['hunger'] as int?) ?? 70,
      affection: (map['affection'] as int?) ?? 70,
      energy: (map['energy'] as int?) ?? 80,
      statsUpdatedAt: map['stats_updated_at'] != null
          ? DateTime.parse(map['stats_updated_at'] as String)
          : DateTime.now(),
      isSleeping: (map['is_sleeping'] as bool?) ?? false,
      sleepNote: map['sleep_note'] as String?,
      sleepStartedAt: map['sleep_started_at'] != null
          ? DateTime.parse(map['sleep_started_at'] as String)
          : null,
      currentAction: PetActionKindExt.fromString(map['current_action'] as String?),
      actionEndsAt: map['action_ends_at'] != null
          ? DateTime.parse(map['action_ends_at'] as String)
          : null,
      lastActionBy: map['last_action_by'] as String?,
      lastActionType: map['last_action_type'] as String?,
      lastActionAt: map['last_action_at'] != null
          ? DateTime.parse(map['last_action_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'pet_name': petName,
      'hunger': hunger,
      'affection': affection,
      'energy': energy,
      'stats_updated_at': statsUpdatedAt.toIso8601String(),
      'is_sleeping': isSleeping,
      'sleep_note': sleepNote,
      'sleep_started_at': sleepStartedAt?.toIso8601String(),
      'current_action': currentAction.nameStr,
      'action_ends_at': actionEndsAt?.toIso8601String(),
      'last_action_by': lastActionBy,
      'last_action_type': lastActionType,
      'last_action_at': lastActionAt?.toIso8601String(),
    };
  }
}
