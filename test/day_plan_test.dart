import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/database.dart';
import 'package:joint_plus/features/today/day_plan.dart';

void main() {
  const mwf = {DateTime.monday, DateTime.wednesday, DateTime.friday};

  SessionSummary done(SessionKind kind, DateTime at) => SessionSummary(
    log: SessionLog(
      id: 0,
      programId: 'p',
      phaseId: 'p1',
      kind: kind,
      startedAt: at,
      endedAt: at.add(const Duration(minutes: 20)),
      painBefore: 1,
      painAfter: 1,
    ),
    exercisesDone: 4,
    exercisesPlanned: 4,
  );

  test('a strength day plans both and starts with strength', () {
    final plan = planDay(
      now: DateTime(2026, 11, 16, 8), // Monday
      strengthDays: mwf,
      sessions: const [],
    );
    expect(plan.strengthDay, isTrue);
    expect(plan.planned, [SessionKind.daily, SessionKind.strength]);
    expect(plan.next, SessionKind.strength);
    expect(plan.nextStrength, DateTime(2026, 11, 18));
  });

  test('a rest day plans mobility and points to the next strength day', () {
    final plan = planDay(
      now: DateTime(2026, 11, 14, 8), // Saturday
      strengthDays: mwf,
      sessions: const [],
    );
    expect(plan.strengthDay, isFalse);
    expect(plan.planned, [SessionKind.daily]);
    expect(plan.next, SessionKind.daily);
    expect(plan.nextStrength, DateTime(2026, 11, 16));
  });

  test('ticks off only today\'s sessions and moves on to what is left', () {
    final now = DateTime(2026, 11, 16, 19);
    final plan = planDay(
      now: now,
      strengthDays: mwf,
      sessions: [
        done(SessionKind.strength, DateTime(2026, 11, 16, 18)),
        done(SessionKind.daily, DateTime(2026, 11, 15, 8)), // yesterday
      ],
    );
    expect(plan.isDone(SessionKind.strength), isTrue);
    expect(plan.isDone(SessionKind.daily), isFalse);
    expect(plan.next, SessionKind.daily);
    expect(plan.allDone, isFalse);
  });

  test('with no strength days chosen every day is mobility only', () {
    final plan = planDay(
      now: DateTime(2026, 11, 16),
      strengthDays: const {},
      sessions: const [],
    );
    expect(plan.strengthDay, isFalse);
    expect(plan.nextStrength, isNull);
  });
}
