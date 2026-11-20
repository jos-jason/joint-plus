import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/content_loader.dart';
import 'package:joint_plus/content/content_parser.dart';
import 'package:joint_plus/content/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled content', () {
    late ContentLibrary lib;

    setUpAll(() async {
      lib = await ContentLoader(rootBundle).load();
    });

    test('loads and validates with no errors', () {
      expect(lib.programs, isNotEmpty);
      expect(lib.exercises, isNotEmpty);
    });

    test(
      'knee program has 4 phases, each with daily + strength and a gate',
      () {
        final knee = lib.program('knee_meniscus');
        expect(knee.phases, hasLength(4));
        for (final p in knee.phases) {
          expect(
            p.sessions.keys,
            containsAll(SessionKind.values),
            reason: p.id,
          );
          expect(p.gate, isNotEmpty, reason: p.id);
        }
        expect(knee.phases.map((p) => p.number), [1, 2, 3, 4]);
      },
    );

    test(
      'every exercise is in a session or reachable as an easier/harder swap',
      () {
        final used = {
          for (final prog in lib.programs)
            for (final ph in prog.phases)
              for (final s in ph.sessions.values)
                for (final d in s.items) d.exerciseId,
        };
        final reachable = {
          ...used,
          for (final id in used) ...[
            ?lib.exercise(id).easier,
            ?lib.exercise(id).harder,
          ],
        };
        expect(lib.exercises.keys.toSet().difference(reachable), isEmpty);
      },
    );

    test('session estimates are in a sensible range', () {
      for (final ph in lib.program('knee_meniscus').phases) {
        final daily = ph.sessions[SessionKind.daily]!.estimateMinutes(
          lib.exercises,
        );
        final strength = ph.sessions[SessionKind.strength]!.estimateMinutes(
          lib.exercises,
        );
        expect(daily, inInclusiveRange(4, 15), reason: '${ph.id} daily');
        // Slow 3 s down / 3 s up reps for the tendon make these ~40 min.
        expect(strength, inInclusiveRange(20, 42), reason: '${ph.id} strength');
      }
    });

    test('strength sessions have at most 6 required exercises', () {
      for (final ph in lib.program('knee_meniscus').phases) {
        expect(
          ph.sessions[SessionKind.strength]!.required.length,
          lessThanOrEqualTo(6),
          reason: ph.id,
        );
      }
    });

    test('every exercise has a line drawing', () async {
      for (final ex in lib.exercises.values) {
        final svg = await rootBundle.loadString(ex.illustrationAsset);
        expect(svg, startsWith('<svg'), reason: ex.id);
        expect(svg, contains('viewBox="0 0 400 300"'), reason: ex.id);
      }
    });

    test('every gate-tested movement is trained in that phase', () {
      // Spot-check the gate ↔ session link for the key test movements.
      final knee = lib.program('knee_meniscus');
      Set<String> trained(int i) => {
        for (final s in knee.phases[i].sessions.values)
          for (final d in s.items) d.exerciseId,
      };
      expect(
        trained(0),
        containsAll(['straight_leg_raise', 'single_leg_balance']),
      );
      expect(trained(1), containsAll(['monkii_squat_90', 'step_up']));
      expect(
        trained(2),
        containsAll([
          'single_leg_box_squat',
          'forward_step_down',
          'deep_squat',
          'single_leg_balance_eyes_closed',
        ]),
      );
      expect(trained(3), containsAll(['forward_hop_stick', 'pivot_drill']));
    });
  });

  group('parser validation', () {
    Map<String, Object?> ex(
      String id, {
      String kind = 'reps',
      String? easier,
    }) => {
      'id': id,
      'name': id,
      'summary': 's',
      'kind': kind,
      'sides': 'together',
      'equipment': ['none'],
      'cues': ['c'],
      'easier': ?easier,
    };

    Map<String, Object?> program(List<Map<String, Object?>> items) => {
      'id': 'p',
      'name': 'P',
      'shortName': 'P',
      'description': 'd',
      'strengthDaysPerWeek': 3,
      'painRules': {'maxDuring': 3, 'settleHours': 24, 'morningNoWorse': true},
      'redFlags': ['x'],
      'maintenance': 'm',
      'phases': [
        {
          'id': 'p1',
          'name': 'One',
          'goal': 'g',
          'minDays': 7,
          'sessions': {
            'strength': {'name': 'S', 'restSec': 60, 'items': items},
          },
          'gate': [
            {'id': 'a', 'type': 'auto', 'text': 't'},
          ],
        },
      ],
    };

    List<String> errorsFor(
      List<Map<String, Object?>> exercises,
      List<Map<String, Object?>> items,
    ) {
      try {
        ContentParser.parse(
          exercisesJson: {'exercises': exercises},
          programsJson: [program(items)],
        );
        return const [];
      } on ContentException catch (e) {
        return e.errors;
      }
    }

    test('reports every problem at once', () {
      final errors = errorsFor(
        [ex('squat', easier: 'ghost'), ex('hold', kind: 'hold')],
        [
          {'ex': 'missing', 'sets': 3, 'reps': 10},
          {'ex': 'hold', 'sets': 3, 'reps': 10},
          {'ex': 'squat', 'sets': 3, 'reps': 10, 'seconds': 5},
        ],
      );
      expect(errors, hasLength(6));
      expect(errors, contains(contains('easier "ghost" does not exist')));
      expect(errors, contains(contains('"missing" does not exist')));
      expect(errors, contains(contains('is a hold exercise')));
      expect(errors, contains(contains('exactly one of "reps" or "seconds"')));
      expect(errors, contains(contains('auto criterion needs "metric"')));
      expect(errors, contains(contains('auto criterion needs "min"')));
    });

    test('rejects unknown enum values with the allowed list', () {
      final errors = errorsFor([ex('a', kind: 'jumping')], []);
      expect(
        errors,
        contains(contains('"jumping" is not one of reps, hold, duration')),
      );
    });
  });

  test('optional items are excluded from the estimate', () {
    const walk = Exercise(
      id: 'w',
      name: 'W',
      summary: '',
      kind: ExerciseKind.duration,
      sides: Sides.together,
      equipment: [],
      cues: [],
      mistakes: [],
    );
    const lift = Exercise(
      id: 'l',
      name: 'L',
      summary: '',
      kind: ExerciseKind.reps,
      sides: Sides.together,
      equipment: [],
      cues: [],
      mistakes: [],
    );
    const base = [Dose(exerciseId: 'l', sets: 3, reps: 10)];
    const withWalk = [
      ...base,
      Dose(exerciseId: 'w', sets: 1, seconds: 1800, optional: true),
    ];
    final ex = {'w': walk, 'l': lift};
    int minutes(List<Dose> items) => SessionTemplate(
      kind: SessionKind.daily,
      name: 'D',
      restSec: 30,
      items: items,
    ).estimateMinutes(ex);
    expect(minutes(withWalk), minutes(base));
  });

  group('dose formatting', () {
    const each = Exercise(
      id: 'x',
      name: 'X',
      summary: '',
      kind: ExerciseKind.reps,
      sides: Sides.each,
      equipment: [],
      cues: [],
      mistakes: [],
    );
    const hold = Exercise(
      id: 'h',
      name: 'H',
      summary: '',
      kind: ExerciseKind.hold,
      sides: Sides.together,
      equipment: [],
      cues: [],
      mistakes: [],
    );

    test('reps, ranges, sides, seconds and minutes', () {
      expect(
        const Dose(exerciseId: 'x', sets: 3, reps: 10).describe(each),
        '3 × 10 / side',
      );
      expect(
        const Dose(
          exerciseId: 'x',
          sets: 3,
          reps: 12,
          repsMax: 15,
        ).describe(each),
        '3 × 12–15 / side',
      );
      expect(
        const Dose(
          exerciseId: 'h',
          sets: 5,
          seconds: 30,
          secondsMax: 45,
        ).describe(hold),
        '5 × 30–45 s',
      );
      expect(
        const Dose(
          exerciseId: 'h',
          sets: 1,
          seconds: 600,
          secondsMax: 1200,
        ).describe(hold),
        '10–20 min',
      );
    });
  });
}
