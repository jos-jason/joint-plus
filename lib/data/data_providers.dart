import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

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

/// Today's morning check-in, or null if it hasn't been done.
final todayCheckInProvider = StreamProvider<CheckIn?>((ref) {
  final today = dayKey(ref.watch(clockProvider)());
  return ref.watch(databaseProvider).watchCheckIn(today);
});
