import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/database.dart';
import 'package:joint_plus/data/export.dart';
import 'package:joint_plus/data/session_result.dart';
import 'package:joint_plus/features/history/pain_trend.dart';

void main() {
  SessionLog log(DateTime start, int pain) => SessionLog(
    id: 0,
    programId: 'p',
    phaseId: 'p1',
    kind: SessionKind.strength,
    startedAt: start,
    endedAt: start.add(const Duration(minutes: 30)),
    painBefore: 1,
    painAfter: pain,
  );

  test('pain trend: one entry per day, worst session pain per day', () {
    final days = buildPainTrend(
      checkIns: [
        CheckIn(
          day: '2026-11-13',
          pain: 2,
          swelling: Change.same,
          stiffness: Change.same,
          recordedAt: DateTime(2026, 11, 13, 7),
        ),
      ],
      sessions: [
        log(DateTime(2026, 11, 14, 9), 2),
        log(DateTime(2026, 11, 14, 18), 4),
        log(DateTime(2026, 10, 1), 9), // outside the window
      ],
      now: DateTime(2026, 11, 15, 8),
      days: 7,
    );
    expect(days, hasLength(7));
    expect(dayKey(days.first.date), '2026-11-09');
    expect(dayKey(days.last.date), '2026-11-15');
    expect(days[4].morningPain, 2);
    expect(days[5].sessionPain, 4);
    expect(days.where((d) => d.sessionPain != null), hasLength(1));
  });

  test('export contains every record and is valid JSON', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveSession(
      programId: 'knee',
      phaseId: 'p1',
      result: SessionResult(
        kind: SessionKind.daily,
        startedAt: DateTime(2026, 11, 14, 8),
        endedAt: DateTime(2026, 11, 14, 8, 12),
        painBefore: 1,
        painAfter: 2,
        items: const [
          ItemResult(
            exerciseId: 'heel_slide',
            setsPlanned: 2,
            setsDone: 2,
            optional: false,
          ),
        ],
      ),
    );
    await db.saveCheckIn(
      at: DateTime(2026, 11, 15, 7),
      pain: 1,
      swelling: Change.less,
      stiffness: Change.same,
    );
    await db.addPhaseEvent(
      programId: 'knee',
      phaseId: 'p1',
      kind: PhaseEventKind.entry,
      at: DateTime(2026, 11, 14, 7),
    );
    await db.saveGateResult(
      programId: 'knee',
      phaseId: 'p1',
      criterionId: 'balance_30',
      passed: true,
      value: 31,
      at: DateTime(2026, 11, 15, 9),
    );

    final data = await buildExport(db, now: DateTime(2026, 11, 15, 10));
    final round = jsonDecode(encodeExport(data)) as Map<String, Object?>;
    expect(round['format'], exportFormat);
    final sessions = round['sessions']! as List;
    expect(sessions.single, containsPair('kind', 'daily'));
    expect((sessions.single as Map)['exercises'], [
      {
        'exercise': 'heel_slide',
        'setsPlanned': 2,
        'setsDone': 2,
        'optional': false,
      },
    ]);
    expect(round['checkIns'], [
      {'day': '2026-11-15', 'pain': 1, 'swelling': 'less', 'stiffness': 'same'},
    ]);
    expect(
      (round['phaseChanges']! as List).single,
      containsPair('kind', 'entry'),
    );
    expect((round['selfTests']! as List).single, containsPair('value', 31.0));
  });
}
