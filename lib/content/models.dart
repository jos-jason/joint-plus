// Content models: everything a program is made of. These are immutable and
// built only by `ContentParser`, which validates them against each other.

enum ExerciseKind {
  /// Counted repetitions.
  reps,

  /// Static hold, timed in seconds.
  hold,

  /// Continuous activity, timed (e.g. walking).
  duration,
}

enum Sides {
  /// Both legs together (squat, bridge).
  together,

  /// One leg at a time, done on each side (split squat).
  each,

  /// Only the injured leg (heel slides, quad sets).
  affected,
}

enum Equipment { none, band, step, monkii, wall, towel, chair }

enum SessionKind { daily, strength }

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.summary,
    required this.kind,
    required this.sides,
    required this.equipment,
    required this.cues,
    required this.mistakes,
    this.easier,
    this.harder,
  });

  final String id;
  final String name;
  final String summary;
  final ExerciseKind kind;
  final Sides sides;
  final List<Equipment> equipment;
  final List<String> cues;
  final List<String> mistakes;

  /// Regression / progression exercise ids.
  final String? easier;
  final String? harder;

  /// Illustrations are found by convention, not listed in the data.
  String get illustrationAsset => 'assets/illustrations/$id.svg';
}

/// How much of one exercise to do in a session.
class Dose {
  const Dose({
    required this.exerciseId,
    required this.sets,
    this.reps,
    this.repsMax,
    this.seconds,
    this.secondsMax,
    this.restSec,
    this.note,
    this.optional = false,
  });

  final String exerciseId;

  /// Extra activity (e.g. a walk): shown, but not counted in the session's
  /// exercise count or time estimate, and skipping it never counts against you.
  final bool optional;
  final int sets;

  /// Exactly one of [reps] or [seconds] is set (checked by the parser).
  final int? reps;
  final int? repsMax;
  final int? seconds;
  final int? secondsMax;

  /// Overrides the session's default rest.
  final int? restSec;
  final String? note;

  bool get isTimed => seconds != null;

  /// e.g. "3 × 12–15 / side", "5 × 30–45 s", "1 × 10–20 min".
  String describe(Exercise ex) {
    final String amount;
    if (isTimed) {
      final lo = seconds!, hi = secondsMax;
      if (lo >= 120 && lo % 60 == 0 && (hi == null || hi % 60 == 0)) {
        amount = '${_range(lo ~/ 60, hi == null ? null : hi ~/ 60)} min';
      } else {
        amount = '${_range(lo, hi)} s';
      }
    } else {
      amount = _range(reps!, repsMax);
    }
    final side = ex.sides == Sides.each ? ' / side' : '';
    return sets == 1 && isTimed ? '$amount$side' : '$sets × $amount$side';
  }

  static String _range(int lo, int? hi) =>
      hi == null || hi == lo ? '$lo' : '$lo–$hi';
}

class SessionTemplate {
  const SessionTemplate({
    required this.kind,
    required this.name,
    required this.restSec,
    required this.items,
  });

  final SessionKind kind;
  final String name;

  /// Default rest between sets.
  final int restSec;
  final List<Dose> items;

  static const _secondsPerRep = 4;
  static const _transitionSec = 20;

  /// The items that make up the session proper.
  Iterable<Dose> get required => items.where((d) => !d.optional);

  /// Extras such as walks.
  Iterable<Dose> get optional => items.where((d) => d.optional);

  /// Rough length of the required items, using the top of each range.
  int estimateMinutes(Map<String, Exercise> exercises) {
    var total = 0;
    for (final d in required) {
      final ex = exercises[d.exerciseId]!;
      final work = d.isTimed
          ? (d.secondsMax ?? d.seconds!)
          : (d.repsMax ?? d.reps!) * _secondsPerRep;
      // Sides are done back to back, so rest only falls between sets.
      final sides = ex.sides == Sides.each ? 2 : 1;
      final rest = d.restSec ?? restSec;
      total += d.sets * work * sides + (d.sets - 1) * rest;
      total += _transitionSec;
    }
    return (total / 60).ceil();
  }
}

enum GateType {
  /// Yes/no self-test.
  check,

  /// Self-test with a measured number that must reach [GateCriterion.min].
  number,

  /// Computed from logs (e.g. days meeting the pain rules).
  auto,
}

/// Metrics an `auto` gate criterion can use. The engine (milestone 6) computes them.
enum GateMetric {
  /// Consecutive days the pain rules were met with no increase in swelling.
  painRuleDays,
}

class GateCriterion {
  const GateCriterion({
    required this.id,
    required this.type,
    required this.text,
    this.help,
    this.min,
    this.unit,
    this.metric,
  });

  final String id;
  final GateType type;
  final String text;
  final String? help;
  final num? min;
  final String? unit;
  final GateMetric? metric;
}

class Phase {
  const Phase({
    required this.id,
    required this.number,
    required this.name,
    required this.goal,
    required this.minDays,
    required this.cautions,
    required this.sessions,
    required this.gate,
  });

  final String id;

  /// 1-based position in the program.
  final int number;
  final String name;
  final String goal;
  final int minDays;
  final List<String> cautions;
  final Map<SessionKind, SessionTemplate> sessions;

  /// Criteria to pass before moving on. For the last phase this is graduation.
  final List<GateCriterion> gate;
}

class PainRules {
  const PainRules({
    required this.maxDuring,
    required this.settleHours,
    required this.morningNoWorse,
  });

  /// Highest acceptable pain (0–10) during exercise.
  final int maxDuring;

  /// Pain must return to baseline within this many hours.
  final int settleHours;

  /// Next-morning pain/stiffness must be no worse than baseline.
  final bool morningNoWorse;
}

class Program {
  const Program({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.strengthDaysPerWeek,
    required this.painRules,
    required this.redFlags,
    required this.phases,
    required this.maintenance,
  });

  final String id;
  final String name;
  final String shortName;
  final String description;
  final int strengthDaysPerWeek;
  final PainRules painRules;
  final List<String> redFlags;
  final List<Phase> phases;
  final String maintenance;
}

/// Everything loaded from assets: the shared exercise library and all programs.
class ContentLibrary {
  const ContentLibrary({required this.exercises, required this.programs});

  final Map<String, Exercise> exercises;
  final List<Program> programs;

  Exercise exercise(String id) => exercises[id]!;

  Program program(String id) => programs.firstWhere((p) => p.id == id);
}
