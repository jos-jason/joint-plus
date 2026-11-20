import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Version of the export file format. Bump when its shape changes.
const exportFormat = 1;

/// Everything Joint+ has recorded, as plain JSON-ready data. Dates are ISO
/// 8601 in local time; check-in days are `yyyy-mm-dd`.
Future<Map<String, Object?>> buildExport(
  AppDatabase db, {
  required DateTime now,
}) async {
  final sessions = await (db.select(
    db.sessionLogs,
  )..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).get();
  final items = await db.select(db.sessionItemLogs).get();
  final byId = <int, List<SessionItemLog>>{};
  for (final i in items) {
    (byId[i.sessionId] ??= []).add(i);
  }

  return {
    'app': 'Joint+',
    'format': exportFormat,
    'exportedAt': now.toIso8601String(),
    'sessions': [
      for (final s in sessions)
        {
          'program': s.programId,
          'phase': s.phaseId,
          'kind': s.kind.name,
          'startedAt': s.startedAt.toIso8601String(),
          'endedAt': s.endedAt.toIso8601String(),
          'painBefore': s.painBefore,
          'painWorst': s.painAfter,
          'exercises': [
            for (final i in byId[s.id] ?? const <SessionItemLog>[])
              {
                'exercise': i.exerciseId,
                'setsPlanned': i.setsPlanned,
                'setsDone': i.setsDone,
                'optional': i.optional,
              },
          ],
        },
    ],
    'checkIns': [
      for (final c in await (db.select(
        db.checkIns,
      )..orderBy([(c) => OrderingTerm.asc(c.day)])).get())
        {
          'day': c.day,
          'knee': c.knee,
          'pain': c.pain,
          'swelling': c.swelling.name,
          'stiffness': c.stiffness.name,
          'loadTestPain': ?c.loadPain,
        },
    ],
    'phaseChanges': [
      for (final e in await (db.select(
        db.phaseEvents,
      )..orderBy([(e) => OrderingTerm.asc(e.at)])).get())
        {
          'program': e.programId,
          'phase': e.phaseId,
          'kind': e.kind.name,
          'at': e.at.toIso8601String(),
        },
    ],
    'selfTests': [
      for (final g in await (db.select(
        db.gateResults,
      )..orderBy([(g) => OrderingTerm.asc(g.at)])).get())
        {
          'program': g.programId,
          'phase': g.phaseId,
          'check': g.criterionId,
          'passed': g.passed,
          'value': ?g.value,
          'at': g.at.toIso8601String(),
        },
    ],
  };
}

String encodeExport(Map<String, Object?> data) =>
    const JsonEncoder.withIndent('  ').convert(data);
