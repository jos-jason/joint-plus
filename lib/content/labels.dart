import 'models.dart';

/// Human-readable labels for content enums. Kept out of the models so the
/// content layer stays free of UI wording.
extension EquipmentLabel on Equipment {
  String get label => switch (this) {
    Equipment.none => 'No equipment',
    Equipment.band => 'Resistance band',
    Equipment.step => 'Step / box',
    Equipment.monkii => 'Pocket Monkii',
    Equipment.wall => 'Wall',
    Equipment.towel => 'Towel',
    Equipment.chair => 'Chair',
  };
}

extension SidesLabel on Sides {
  String get label => switch (this) {
    Sides.together => 'Both legs',
    Sides.each => 'Each leg',
    Sides.affected => 'Injured leg',
  };
}

extension SessionKindLabel on SessionKind {
  /// Short tab label.
  String get label => switch (this) {
    SessionKind.strength => 'Strength',
    SessionKind.daily => 'Mobility',
  };

  String frequency(Program p) => switch (this) {
    SessionKind.daily => 'Daily',
    SessionKind.strength => '${p.strengthDaysPerWeek}× a week',
  };
}

extension GateCriterionLabel on GateCriterion {
  String get kindLabel => switch (type) {
    GateType.check => 'Self-test',
    GateType.number =>
      'Measure · ${min ?? ''}${unit == null ? '' : ' $unit'} or more',
    GateType.auto => 'Tracked by the app',
  };
}

extension ExerciseFacts on Exercise {
  /// e.g. "Each leg · Step / box · 1 rep every 4 s".
  String get facts {
    final gear = equipment
        .where((e) => e != Equipment.none)
        .map((e) => e.label);
    return [
      sides.label,
      if (gear.isEmpty) Equipment.none.label else ...gear,
      if (kind == ExerciseKind.reps) '1 rep every $repSec s',
    ].join('  ·  ');
  }
}
