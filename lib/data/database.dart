import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../content/models.dart';
import 'session_result.dart';

part 'database.g.dart';

/// Compared with yesterday, as answered in the morning check-in.
enum Change { less, same, more }

/// One finished session.
class SessionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programId => text()();
  TextColumn get phaseId => text()();
  TextColumn get kind => textEnum<SessionKind>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get painBefore => integer()();

  /// Worst pain during the session.
  IntColumn get painAfter => integer()();
}

/// Sets done for each exercise in a logged session.
class SessionItemLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(SessionLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  IntColumn get setsPlanned => integer()();
  IntColumn get setsDone => integer()();
  BoolColumn get optional => boolean()();
}

/// Morning check-in. One per calendar day; saving again replaces it.
class CheckIns extends Table {
  /// Local date, `yyyy-mm-dd`.
  TextColumn get day => text()();
  IntColumn get pain => integer()();
  TextColumn get swelling => textEnum<Change>()();
  TextColumn get stiffness => textEnum<Change>()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Why the current phase changed.
enum PhaseEventKind {
  /// Chosen after the entry check.
  entry,

  /// All gate checks passed.
  advance,

  /// Pain rules broken repeatedly; moved down a phase.
  dropBack,

  /// Last phase's checks passed: maintenance from here on.
  graduate,
}

/// Every phase change, oldest first. The latest one is where you are now.
class PhaseEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programId => text()();

  /// The phase you are in from [at] on.
  TextColumn get phaseId => text()();
  TextColumn get kind => textEnum<PhaseEventKind>()();
  DateTimeColumn get at => dateTime()();
}

/// Self-test answers for gate criteria. The newest per criterion counts.
class GateResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programId => text()();
  TextColumn get phaseId => text()();
  TextColumn get criterionId => text()();
  BoolColumn get passed => boolean()();

  /// Measured value for number criteria, e.g. seconds of balance.
  RealColumn get value => real().nullable()();
  DateTimeColumn get at => dateTime()();
}

/// Small app preferences as key → text (JSON where structured).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// A logged session with how many of its required exercises were completed.
class SessionSummary {
  const SessionSummary({
    required this.log,
    required this.exercisesDone,
    required this.exercisesPlanned,
  });

  final SessionLog log;
  final int exercisesDone;
  final int exercisesPlanned;
}

/// Local calendar day key, e.g. "2026-11-14".
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Everything the app records, on this device only.
@DriftDatabase(
  tables: [
    SessionLogs,
    SessionItemLogs,
    CheckIns,
    PhaseEvents,
    GateResults,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests, e.g. `NativeDatabase.memory()`.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'joint_plus'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(phaseEvents);
        await m.createTable(gateResults);
      }
      if (from < 3) await m.createTable(appSettings);
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  // ----------------------------------------------------------------- sessions

  Future<int> saveSession({
    required String programId,
    required String phaseId,
    required SessionResult result,
  }) => transaction(() async {
    final id = await into(sessionLogs).insert(
      SessionLogsCompanion.insert(
        programId: programId,
        phaseId: phaseId,
        kind: result.kind,
        startedAt: result.startedAt,
        endedAt: result.endedAt,
        painBefore: result.painBefore,
        painAfter: result.painAfter,
      ),
    );
    await batch(
      (b) => b.insertAll(sessionItemLogs, [
        for (final i in result.items)
          SessionItemLogsCompanion.insert(
            sessionId: id,
            exerciseId: i.exerciseId,
            setsPlanned: i.setsPlanned,
            setsDone: i.setsDone,
            optional: i.optional,
          ),
      ]),
    );
    return id;
  });

  /// Newest first.
  Stream<List<SessionSummary>> watchSessions() {
    final query = customSelect(
      'SELECT s.*, '
      'COALESCE(SUM(NOT i.optional), 0) AS planned, '
      'COALESCE(SUM(NOT i.optional AND i.sets_done >= i.sets_planned), 0) '
      'AS done '
      'FROM session_logs s '
      'LEFT JOIN session_item_logs i ON i.session_id = s.id '
      'GROUP BY s.id ORDER BY s.started_at DESC, s.id DESC',
      readsFrom: {sessionLogs, sessionItemLogs},
    );
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          SessionSummary(
            log: sessionLogs.map(row.data),
            exercisesDone: row.read<int>('done'),
            exercisesPlanned: row.read<int>('planned'),
          ),
      ],
    );
  }

  Future<List<SessionItemLog>> itemsFor(int sessionId) => (select(
    sessionItemLogs,
  )..where((i) => i.sessionId.equals(sessionId))).get();

  // ---------------------------------------------------------------- check-ins

  Future<void> saveCheckIn({
    required DateTime at,
    required int pain,
    required Change swelling,
    required Change stiffness,
  }) => into(checkIns).insertOnConflictUpdate(
    CheckInsCompanion.insert(
      day: dayKey(at),
      pain: pain,
      swelling: swelling,
      stiffness: stiffness,
      recordedAt: at,
    ),
  );

  Stream<CheckIn?> watchCheckIn(String day) =>
      (select(checkIns)..where((c) => c.day.equals(day))).watchSingleOrNull();

  /// Oldest first.
  Stream<List<CheckIn>> watchCheckIns() =>
      (select(checkIns)..orderBy([(c) => OrderingTerm.asc(c.day)])).watch();

  // ------------------------------------------------------------ progression

  /// Oldest first.
  Stream<List<PhaseEvent>> watchPhaseEvents(String programId) =>
      (select(phaseEvents)
            ..where((e) => e.programId.equals(programId))
            ..orderBy([
              (e) => OrderingTerm.asc(e.at),
              (e) => OrderingTerm.asc(e.id),
            ]))
          .watch();

  Future<void> addPhaseEvent({
    required String programId,
    required String phaseId,
    required PhaseEventKind kind,
    required DateTime at,
  }) => into(phaseEvents).insert(
    PhaseEventsCompanion.insert(
      programId: programId,
      phaseId: phaseId,
      kind: kind,
      at: at,
    ),
  );

  /// Oldest first.
  Stream<List<GateResult>> watchGateResults(String programId, String phaseId) =>
      (select(gateResults)
            ..where(
              (g) => g.programId.equals(programId) & g.phaseId.equals(phaseId),
            )
            ..orderBy([
              (g) => OrderingTerm.asc(g.at),
              (g) => OrderingTerm.asc(g.id),
            ]))
          .watch();

  Future<void> saveGateResult({
    required String programId,
    required String phaseId,
    required String criterionId,
    required bool passed,
    double? value,
    required DateTime at,
  }) => into(gateResults).insert(
    GateResultsCompanion.insert(
      programId: programId,
      phaseId: phaseId,
      criterionId: criterionId,
      passed: passed,
      value: Value(value),
      at: at,
    ),
  );

  // ----------------------------------------------------------------- settings

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> putSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
}
