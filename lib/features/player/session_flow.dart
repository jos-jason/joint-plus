import '../../content/models.dart';
import '../../data/session_result.dart';

export '../../data/session_result.dart';

/// Which leg a work step is for, when the exercise is one-sided.
enum LegSide { injured, other }

extension LegSideLabel on LegSide {
  String get label => switch (this) {
    LegSide.injured => 'Injured leg',
    LegSide.other => 'Other leg',
  };
}

/// One screen of the session player.
sealed class PlayerStep {
  const PlayerStep();
}

/// Pain 0–10, asked before starting and after the last exercise.
final class PainStep extends PlayerStep {
  const PainStep({required this.before});

  final bool before;
}

/// A step that belongs to one exercise in the session.
sealed class ItemStep extends PlayerStep {
  const ItemStep({required this.item});

  /// Index into [SessionFlow.items].
  final int item;
}

/// One set (on one side) of an exercise.
final class WorkStep extends ItemStep {
  const WorkStep({
    required super.item,
    required this.exercise,
    required this.dose,
    required this.set,
    required this.side,
    required this.lastSide,
  });

  final Exercise exercise;
  final Dose dose;

  /// 1-based.
  final int set;
  final LegSide? side;

  /// Completing this step completes the set.
  final bool lastSide;
}

/// Rest between sets of the same exercise. Sides run back to back, and moving
/// to the next exercise is up to you, so neither gets a timed rest.
final class RestStep extends ItemStep {
  const RestStep({required super.item, required this.seconds});

  final int seconds;
}

final class SummaryStep extends PlayerStep {
  const SummaryStep();
}

/// The session player's state: an ordered list of steps and where you are in
/// it. Plain Dart so the flow is easy to test without widgets.
class SessionFlow {
  SessionFlow({
    required this.session,
    required Map<String, Exercise> exercises,
    DateTime Function()? clock,
  }) : items = [...session.required, ...session.optional],
       _clock = clock ?? DateTime.now {
    steps = _buildSteps(exercises);
    _setsDone = List.filled(items.length, 0);
  }

  final SessionTemplate session;

  /// Required exercises first, then optional extras.
  final List<Dose> items;
  final DateTime Function() _clock;

  late final List<PlayerStep> steps;
  late final List<int> _setsDone;

  int _index = 0;
  int? painBefore;
  int? painAfter;
  DateTime? _startedAt;
  DateTime? _endedAt;

  int get index => _index;
  PlayerStep get step => steps[_index];

  /// Past the opening pain check: leaving now loses progress.
  bool get started => _index > 0;
  bool get finished => step is SummaryStep;

  int get requiredCount => session.required.length;

  /// 0 → 1 across the whole session.
  double get progress => _index / (steps.length - 1);

  /// The step after this one, e.g. to show "up next" during rest.
  PlayerStep? get upNext =>
      _index + 1 < steps.length ? steps[_index + 1] : null;

  int setsDone(int item) => _setsDone[item];

  List<PlayerStep> _buildSteps(Map<String, Exercise> exercises) {
    final out = <PlayerStep>[const PainStep(before: true)];
    for (final (i, d) in items.indexed) {
      final ex = exercises[d.exerciseId]!;
      final sides = switch (ex.sides) {
        Sides.each => const [LegSide.injured, LegSide.other],
        Sides.affected => const [LegSide.injured],
        Sides.together => const <LegSide?>[null],
      };
      for (var set = 1; set <= d.sets; set++) {
        for (final (s, side) in sides.indexed) {
          out.add(
            WorkStep(
              item: i,
              exercise: ex,
              dose: d,
              set: set,
              side: side,
              lastSide: s == sides.length - 1,
            ),
          );
        }
        if (set < d.sets) {
          out.add(RestStep(item: i, seconds: d.restSec ?? session.restSec));
        }
      }
    }
    out
      ..add(const PainStep(before: false))
      ..add(const SummaryStep());
    return out;
  }

  /// Completes the current step and moves on.
  void next() {
    final s = step;
    if (s is PainStep && s.before) {
      assert(painBefore != null, 'rate pain before starting');
      _startedAt = _clock();
    }
    if (s is WorkStep && s.lastSide) _setsDone[s.item]++;
    if (_index < steps.length - 1) _index++;
    if (step is SummaryStep) _endedAt = _clock();
  }

  /// Skips the rest of the current exercise, including its remaining sets.
  void skipExercise() {
    final s = step;
    if (s is! ItemStep) return;
    _index = steps.indexWhere((x) => x is! ItemStep || x.item > s.item, _index);
  }

  SessionResult result() {
    assert(finished && painBefore != null && painAfter != null);
    return SessionResult(
      kind: session.kind,
      startedAt: _startedAt!,
      endedAt: _endedAt!,
      painBefore: painBefore!,
      painAfter: painAfter!,
      items: [
        for (final (i, d) in items.indexed)
          ItemResult(
            exerciseId: d.exerciseId,
            setsPlanned: d.sets,
            setsDone: _setsDone[i],
            optional: d.optional,
          ),
      ],
    );
  }
}
