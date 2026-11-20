import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'knees.dart';

/// The on-device database. Overridden with an in-memory one in tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// "Now", injectable so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Logged sessions, newest first.
final sessionLogsProvider = StreamProvider<List<SessionSummary>>(
  (ref) => ref.watch(databaseProvider).watchSessions(),
);

/// All check-ins, oldest first.
final checkInsProvider = StreamProvider<List<CheckIn>>(
  (ref) => ref.watch(databaseProvider).watchCheckIns(),
);

/// Today's morning check-in rows (one per knee); empty if not done yet.
final todayCheckInProvider = StreamProvider<List<CheckIn>>((ref) {
  final today = dayKey(ref.watch(clockProvider)());
  return ref.watch(databaseProvider).watchCheckIn(today);
});

const _kneesKey = 'knees';

/// Which knees are in rehab; null until chosen.
final kneeSetupProvider = StreamProvider<KneeSetup?>(
  (ref) =>
      ref.watch(databaseProvider).watchSetting(_kneesKey).map(KneeSetup.decode),
);

Future<void> saveKneeSetup(AppDatabase db, KneeSetup setup) =>
    db.putSetting(_kneesKey, setup.encode());
