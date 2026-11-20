import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/knees.dart';
import 'package:joint_plus/features/player/session_flow.dart';

void main() {
  Exercise ex(String id, ExerciseKind kind, Sides sides) => Exercise(
    id: id,
    name: id,
    summary: '',
    kind: kind,
    sides: sides,
    equipment: const [],
    cues: const ['c'],
    mistakes: const [],
  );

  final exercises = {
    'squat': ex('squat', ExerciseKind.reps, Sides.together),
    'lunge': ex('lunge', ExerciseKind.reps, Sides.each),
    'hold': ex('hold', ExerciseKind.hold, Sides.affected),
    'walk': ex('walk', ExerciseKind.duration, Sides.together),
  };

  const session = SessionTemplate(
    kind: SessionKind.strength,
    name: 'S',
    restSec: 60,
    items: [
      Dose(exerciseId: 'walk', sets: 1, seconds: 600, optional: true),
      Dose(exerciseId: 'squat', sets: 2, reps: 10),
      Dose(exerciseId: 'lunge', sets: 2, reps: 8, restSec: 90),
      Dose(exerciseId: 'hold', sets: 1, seconds: 30),
    ],
  );

  SessionFlow newFlow() {
    var t = DateTime(2026, 11, 14, 8);
    return SessionFlow(
      session: session,
      exercises: exercises,
      clock: () => t = t.add(const Duration(minutes: 15)),
    );
  }

  String describe(PlayerStep s) => switch (s) {
    PainStep(:final before) => before ? 'pain-before' : 'pain-after',
    WorkStep(:final exercise, :final set, :final side) =>
      '${exercise.id}#$set${side == null ? '' : '-${side.name}'}',
    RestStep(:final seconds) => 'rest$seconds',
    SwitchStep() => 'switch',
    UpNextStep(:final exercise) => 'next:${exercise.id}',
    SummaryStep() => 'summary',
  };

  test('builds sets, sides and breaks in order, extras last', () {
    expect(newFlow().steps.map(describe), [
      'pain-before',
      'next:squat',
      'squat#1',
      'rest60',
      'squat#2',
      'next:lunge',
      // A short switch between sides; the dose's own rest overrides the default.
      'lunge#1-injured',
      'switch',
      'lunge#1-other',
      'rest90',
      'lunge#2-injured',
      'switch',
      'lunge#2-other',
      'next:hold',
      'hold#1-injured',
      'next:walk',
      'walk#1',
      'pain-after',
      'summary',
    ]);
  });

  test('breaks use the session template timings', () {
    final f = newFlow();
    expect(f.steps.whereType<UpNextStep>().map((s) => s.seconds).toSet(), {
      SessionTemplate.transitionSec,
    });
    expect(f.steps.whereType<SwitchStep>().map((s) => s.seconds).toSet(), {
      SessionTemplate.sideSwitchSec,
    });
  });

  test('counts a set only once every side is done', () {
    final f = newFlow()..painBefore = 1;
    while (describe(f.step) != 'lunge#1-other') {
      f.next();
    }
    expect(f.setsDone(1), 0);
    f.next();
    expect(f.setsDone(1), 1);
  });

  test('skipping jumps past remaining sets and rests of that exercise', () {
    final f = newFlow()..painBefore = 1;
    f.next(); // next:squat
    f.next(); // squat#1
    f.skipExercise();
    expect(describe(f.step), 'next:lunge');
    f.next(); // lunge#1-injured
    f.next(); // switch
    f.next(); // lunge#1-other
    f.next(); // rest90
    f.skipExercise(); // works during rest too
    expect(describe(f.step), 'next:hold');
    f.skipExercise(); // skipping from "up next" skips that exercise
    expect(describe(f.step), 'next:walk');
    f.skipExercise(); // the optional walk
    expect(describe(f.step), 'pain-after');
    f.skipExercise(); // no-op outside exercises
    expect(describe(f.step), 'pain-after');
  });

  test('result reports sets done, pain and timing', () {
    final f = newFlow()..painBefore = 2;
    expect(f.started, isFalse);
    f.next();
    expect(f.started, isTrue);
    f.next(); // next:squat
    f.next(); // squat#1 done
    f.skipExercise(); // skip squat set 2
    while (f.step is! PainStep) {
      f.next();
    }
    f.painAfter = 3;
    f.next();
    expect(f.finished, isTrue);
    expect(f.progress, 1);

    final r = f.result();
    expect(r.painBefore, 2);
    expect(r.painAfter, 3);
    expect(r.endedAt.difference(r.startedAt), const Duration(minutes: 15));
    expect(
      {for (final i in r.items) i.exerciseId: (i.setsDone, i.complete)},
      {
        'squat': (1, false),
        'lunge': (2, true),
        'hold': (1, true),
        'walk': (1, true),
      },
    );
  });

  test(
    'with both knees, recovering-leg work runs on each, chosen knee first',
    () {
      final f = SessionFlow(
        session: session,
        exercises: exercises,
        knees: const KneeSetup.both(first: Knee.right),
      );
      final work = f.steps.whereType<WorkStep>().map(describe).toList();
      // Lunge is done on each leg; the hold is "recovering leg only".
      expect(work, containsAllInOrder(['lunge#1-right', 'lunge#1-left']));
      expect(work, containsAllInOrder(['hold#1-right', 'hold#1-left']));
      expect(f.steps.whereType<SwitchStep>(), hasLength(3));
    },
  );

  test('with one knee set, recovering-leg work runs on that leg only', () {
    final f = SessionFlow(
      session: session,
      exercises: exercises,
      knees: KneeSetup.one(Knee.left),
    );
    final work = f.steps.whereType<WorkStep>().map(describe).toList();
    expect(work.where((w) => w.startsWith('hold')), ['hold#1-left']);
    expect(work, containsAllInOrder(['lunge#1-left', 'lunge#1-right']));
  });

  test('starts and ends with pain checks, then a summary', () {
    final f = newFlow();
    expect(f.steps.first, isA<PainStep>());
    expect(f.steps[f.steps.length - 2], isA<PainStep>());
    expect(f.steps.last, isA<SummaryStep>());
    expect(f.requiredCount, 3);
    expect(f.items.last.optional, isTrue);
  });
}
