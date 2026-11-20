import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models.dart';
import '../../data/data_providers.dart';
import '../../data/database.dart';
import '../../reminders/reminder_providers.dart';
import '../../reminders/reminder_settings.dart';

/// What today asks for and what has been done so far.
class DayPlan {
  const DayPlan({
    required this.strengthDay,
    required this.done,
    required this.nextStrength,
  });

  /// Today is one of the chosen strength days.
  final bool strengthDay;

  /// The latest logged session of each kind today.
  final Map<SessionKind, SessionSummary> done;

  /// The next strength day after today, or null if none are chosen.
  final DateTime? nextStrength;

  bool isDone(SessionKind kind) => done.containsKey(kind);

  /// Mobility every day, strength on strength days.
  List<SessionKind> get planned => [
    SessionKind.daily,
    if (strengthDay) SessionKind.strength,
  ];

  bool get allDone => planned.every(isDone);

  /// The session to show first: strength if it's due and not done, then
  /// mobility, then whatever today is about.
  SessionKind get next {
    if (strengthDay && !isDone(SessionKind.strength)) {
      return SessionKind.strength;
    }
    if (!isDone(SessionKind.daily)) return SessionKind.daily;
    return strengthDay ? SessionKind.strength : SessionKind.daily;
  }
}

DayPlan planDay({
  required DateTime now,
  required Set<int> strengthDays,
  required List<SessionSummary> sessions,
}) {
  final today = dayKey(now);
  final done = <SessionKind, SessionSummary>{};
  // Sessions arrive newest first: keep the first (latest) of each kind.
  for (final s in sessions) {
    if (dayKey(s.log.startedAt) == today) done.putIfAbsent(s.log.kind, () => s);
  }
  DateTime? next;
  for (var i = 1; i <= 7 && strengthDays.isNotEmpty; i++) {
    final d = DateTime(now.year, now.month, now.day + i);
    if (strengthDays.contains(d.weekday)) {
      next = d;
      break;
    }
  }
  return DayPlan(
    strengthDay: strengthDays.contains(now.weekday),
    done: done,
    nextStrength: next,
  );
}

/// The strength days chosen in Settings (Monday, Wednesday and Friday until
/// changed). The schedule applies whether or not the reminder is on.
final strengthDaysProvider = Provider<Set<int>>(
  (ref) =>
      (ref.watch(reminderSettingsProvider).value ?? ReminderSettings.defaults)
          .strengthDays,
);

final dayPlanProvider = Provider<DayPlan>(
  (ref) => planDay(
    now: ref.watch(clockProvider)(),
    strengthDays: ref.watch(strengthDaysProvider),
    sessions: ref.watch(sessionLogsProvider).value ?? const [],
  ),
);
