import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/database.dart';
import 'package:joint_plus/data/session_result.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  SessionResult result(DateTime start, List<(int, int, bool)> items) =>
      SessionResult(
        kind: SessionKind.strength,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 30)),
        painBefore: 2,
        painAfter: 3,
        items: [
          for (final (i, (planned, done, optional)) in items.indexed)
            ItemResult(
              exerciseId: 'ex$i',
              setsPlanned: planned,
              setsDone: done,
              optional: optional,
            ),
        ],
      );

  test('saves a session and summarises completed required exercises', () async {
    final id = await db.saveSession(
      programId: 'knee',
      phaseId: 'p1',
      result: result(DateTime(2026, 11, 14, 8), [
        (3, 3, false), // complete
        (3, 1, false), // partly done
        (1, 1, true), // optional extra: not counted
      ]),
    );

    final summaries = await db.watchSessions().first;
    expect(summaries, hasLength(1));
    final s = summaries.single;
    expect(s.log.id, id);
    expect(s.log.kind, SessionKind.strength);
    expect(s.log.painAfter, 3);
    expect((s.exercisesDone, s.exercisesPlanned), (1, 2));
    expect(await db.itemsFor(id), hasLength(3));
  });

  test('lists sessions newest first', () async {
    for (final day in [10, 14, 12]) {
      await db.saveSession(
        programId: 'knee',
        phaseId: 'p1',
        result: result(DateTime(2026, 11, day), [(1, 1, false)]),
      );
    }
    final days = (await db.watchSessions().first).map(
      (s) => s.log.startedAt.day,
    );
    expect(days, [14, 12, 10]);
  });

  test('deleting a session removes its items', () async {
    final id = await db.saveSession(
      programId: 'knee',
      phaseId: 'p1',
      result: result(DateTime(2026, 11, 14), [(1, 1, false)]),
    );
    await (db.delete(db.sessionLogs)..where((s) => s.id.equals(id))).go();
    expect(await db.itemsFor(id), isEmpty);
  });

  test('one check-in per day: saving again replaces it', () async {
    final morning = DateTime(2026, 11, 14, 7);
    await db.saveCheckIn(
      at: morning,
      pain: 3,
      swelling: Change.same,
      stiffness: Change.more,
    );
    await db.saveCheckIn(
      at: morning.add(const Duration(hours: 1)),
      pain: 2,
      swelling: Change.less,
      stiffness: Change.same,
    );
    await db.saveCheckIn(
      at: DateTime(2026, 11, 15, 7),
      pain: 1,
      swelling: Change.less,
      stiffness: Change.less,
    );

    final today = (await db.watchCheckIn('2026-11-14').first).single;
    expect(today.pain, 2);
    expect(today.swelling, Change.less);
    expect((await db.watchCheckIns().first).map((c) => c.day), [
      '2026-11-14',
      '2026-11-15',
    ]);
    expect(await db.watchCheckIn('2026-11-13').first, isEmpty);
  });

  test('with two knees each gets its own check-in row', () async {
    final at = DateTime(2026, 11, 14, 7);
    for (final (knee, pain) in [('left', 2), ('right', 4)]) {
      await db.saveCheckIn(
        at: at,
        knee: knee,
        pain: pain,
        swelling: Change.same,
        stiffness: Change.same,
        loadPain: pain + 1,
      );
    }
    final rows = await db.watchCheckIn('2026-11-14').first;
    expect(
      [for (final r in rows) (r.knee, r.pain, r.loadPain)],
      [('left', 2, 3), ('right', 4, 5)],
    );
  });

  test('dayKey pads to yyyy-mm-dd', () {
    expect(dayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
