import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/database.dart';
import 'package:joint_plus/engine/progression.dart';

void main() {
  const rules = PainRules(maxDuring: 3, settleHours: 24, morningNoWorse: true);

  CheckIn checkIn(
    String day, {
    int pain = 2,
    Change swelling = Change.same,
    Change stiffness = Change.same,
  }) => CheckIn(
    day: day,
    pain: pain,
    swelling: swelling,
    stiffness: stiffness,
    recordedAt: DateTime.parse(day).add(const Duration(hours: 7)),
  );

  SessionLog session(String day, int painAfter) => SessionLog(
    id: 0,
    programId: 'p',
    phaseId: 'p1',
    kind: SessionKind.strength,
    startedAt: DateTime.parse(day).add(const Duration(hours: 18)),
    endedAt: DateTime.parse(day).add(const Duration(hours: 18, minutes: 30)),
    painBefore: 1,
    painAfter: painAfter,
  );

  group('pain rule days', () {
    test('judges each morning on yesterday and the previous check-in', () {
      final days = evaluateRuleDays(
        checkIns: [
          checkIn('2026-11-10'),
          checkIn('2026-11-11'), // after a session at 4/10
          checkIn('2026-11-12', swelling: Change.more),
          checkIn('2026-11-13', pain: 4), // up from 2
          checkIn('2026-11-14', pain: 3, stiffness: Change.less),
        ],
        sessions: [session('2026-11-10', 4), session('2026-11-13', 3)],
        rules: rules,
      );
      expect(days.map((d) => d.met), [true, false, false, false, true]);
      expect(days[1].reasons.single, contains('4/10'));
      expect(days[2].reasons.single, contains('swelling'));
      expect(days[3].reasons.single, contains('from 2 to 4'));
    });

    test('streak counts back to the last broken day, from the stint start', () {
      final days = [
        for (final (d, met) in [
          ('2026-11-01', true),
          ('2026-11-02', false),
          ('2026-11-03', true),
          ('2026-11-05', true), // a missed check-in on the 4th doesn't break it
          ('2026-11-06', true),
        ])
          RuleDay(day: d, reasons: met ? [] : ['x']),
      ];
      expect(painRuleStreak(days), 3);
      expect(painRuleStreak(days, since: DateTime(2026, 11, 5)), 2);
    });
  });

  group('advice', () {
    final now = DateTime(2026, 11, 14, 8);
    RuleDay d(String day, bool met) =>
        RuleDay(day: day, reasons: met ? [] : ['why']);

    test('once broken → hold, twice in a row → drop back', () {
      expect(
        adviseFrom([
          d('2026-11-13', true),
          d('2026-11-14', false),
        ], now: now).kind,
        AdviceKind.hold,
      );
      expect(
        adviseFrom([
          d('2026-11-13', false),
          d('2026-11-14', false),
        ], now: now).kind,
        AdviceKind.dropBack,
      );
      expect(
        adviseFrom([
          d('2026-11-13', false),
          d('2026-11-14', true),
        ], now: now).kind,
        AdviceKind.none,
      );
    });

    test('ignores stale check-ins and days before the stint', () {
      expect(
        adviseFrom([d('2026-11-10', false)], now: now).kind,
        AdviceKind.none,
      );
      expect(
        adviseFrom(
          [d('2026-11-13', false), d('2026-11-14', false)],
          now: now,
          since: DateTime(2026, 11, 14),
        ).kind,
        AdviceKind.hold,
      );
    });
  });

  group('gate', () {
    const phase = Phase(
      id: 'p1',
      number: 1,
      name: 'One',
      goal: '',
      minDays: 7,
      cautions: [],
      sessions: {},
      gate: [
        GateCriterion(id: 'ext', type: GateType.check, text: ''),
        GateCriterion(
          id: 'bal',
          type: GateType.number,
          text: '',
          min: 30,
          unit: 's',
        ),
        GateCriterion(
          id: 'days',
          type: GateType.auto,
          text: '',
          min: 3,
          metric: GateMetric.painRuleDays,
        ),
      ],
    );
    final start = DateTime(2026, 11, 1, 9);

    GateResult result(String id, int day, {bool passed = true, double? v}) =>
        GateResult(
          id: 0,
          programId: 'p',
          phaseId: 'p1',
          criterionId: id,
          passed: passed,
          value: v,
          at: DateTime(2026, 11, day, 12),
        );

    final goodDays = [
      for (final day in ['2026-11-05', '2026-11-06', '2026-11-07'])
        RuleDay(day: day, reasons: const []),
    ];

    test('ready only when every criterion and the minimum days are met', () {
      final status = evaluateGate(
        phase: phase,
        results: [
          result('ext', 2, passed: false),
          result('ext', 3), // newest wins
          result('bal', 4, v: 32),
        ],
        ruleDays: goodDays,
        stintStart: start,
        now: DateTime(2026, 11, 7, 8),
      );
      expect(status.items.map((i) => i.met), [true, true, true]);
      expect(status.items[1].progress, '32 s');
      expect(status.items[2].progress, '3 / 3 days');
      expect(status.daysInPhase, 7);
      expect(status.ready, isTrue);

      final early = evaluateGate(
        phase: phase,
        results: [result('ext', 3), result('bal', 4, v: 32)],
        ruleDays: goodDays,
        stintStart: start,
        now: DateTime(2026, 11, 6, 8),
      );
      expect(early.minDaysMet, isFalse);
      expect(early.ready, isFalse);
    });

    test(
      'results from before the stint and short measurements do not count',
      () {
        final status = evaluateGate(
          phase: phase,
          results: [
            GateResult(
              id: 0,
              programId: 'p',
              phaseId: 'p1',
              criterionId: 'ext',
              passed: true,
              at: DateTime(2026, 10, 20),
            ),
            result('bal', 4, v: 24),
          ],
          ruleDays: goodDays.sublist(1),
          stintStart: start,
          now: DateTime(2026, 11, 9),
        );
        expect(status.items.map((i) => i.met), [false, false, false]);
        expect(status.items[0].answered, isFalse);
        expect(status.items[2].progress, '2 / 3 days');
      },
    );
  });

  group('progress from events', () {
    const program = Program(
      id: 'p',
      name: 'P',
      shortName: 'P',
      description: '',
      strengthDaysPerWeek: 3,
      painRules: rules,
      redFlags: [],
      maintenance: '',
      phases: [
        Phase(
          id: 'a',
          number: 1,
          name: 'A',
          goal: '',
          minDays: 1,
          cautions: [],
          sessions: {},
          gate: [GateCriterion(id: 'x', type: GateType.check, text: '')],
        ),
        Phase(
          id: 'b',
          number: 2,
          name: 'B',
          goal: '',
          minDays: 1,
          cautions: [],
          sessions: {},
          gate: [GateCriterion(id: 'y', type: GateType.check, text: '')],
        ),
      ],
    );

    PhaseEvent e(String phase, PhaseEventKind kind, int day) => PhaseEvent(
      id: day,
      programId: 'p',
      phaseId: phase,
      kind: kind,
      at: DateTime(2026, 11, day),
    );

    test('the latest event decides the phase', () {
      expect(ProgramProgress.from(program, []).started, isFalse);
      final p = ProgramProgress.from(program, [
        e('a', PhaseEventKind.entry, 1),
        e('b', PhaseEventKind.advance, 8),
      ]);
      expect(
        (p.phaseIndex, p.stintStart, p.graduated),
        (1, DateTime(2026, 11, 8), false),
      );
      expect(
        ProgramProgress.from(program, [
          e('b', PhaseEventKind.graduate, 20),
        ]).graduated,
        isTrue,
      );
    });

    test('entry check suggests phase 2 only when every answer is yes', () {
      expect(suggestStartPhase(program, {'x': true}), 1);
      expect(suggestStartPhase(program, {'x': false}), 0);
      expect(suggestStartPhase(program, {}), 0);
    });
  });
}
