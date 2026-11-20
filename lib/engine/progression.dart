// Progression rules: pain rules, gate evaluation, flare-up advice, phase
// state and the entry check. Pure functions over logged data, no I/O, so every
// rule can be unit tested.

import '../content/models.dart';
import '../data/database.dart';
import '../data/knees.dart';

// ------------------------------------------------------------- phase state

/// Where you are in a program, derived from the phase event log.
class ProgramProgress {
  const ProgramProgress({
    required this.phaseIndex,
    required this.stintStart,
    required this.started,
    required this.graduated,
  });

  /// Before the entry check: Phase 1, not started.
  const ProgramProgress.notStarted()
    : phaseIndex = 0,
      stintStart = null,
      started = false,
      graduated = false;

  factory ProgramProgress.from(Program program, List<PhaseEvent> events) {
    if (events.isEmpty) return const ProgramProgress.notStarted();
    final last = events.last;
    final i = program.phases.indexWhere((p) => p.id == last.phaseId);
    return ProgramProgress(
      phaseIndex: i < 0 ? 0 : i,
      stintStart: last.at,
      started: true,
      graduated: last.kind == PhaseEventKind.graduate,
    );
  }

  final int phaseIndex;

  /// When the current phase began. Gate results and pain-rule days only
  /// count from here, so each phase (and each return to it) earns its own.
  final DateTime? stintStart;
  final bool started;

  /// All phases passed: maintenance mode.
  final bool graduated;
}

// -------------------------------------------------------------- pain rules

/// One morning's verdict on the day before.
class RuleDay {
  const RuleDay({required this.day, required this.reasons});

  /// Check-in day, `yyyy-mm-dd`.
  final String day;

  /// Why the rules were broken. Empty when they were met.
  final List<String> reasons;

  bool get met => reasons.isEmpty;
}

/// Judges each check-in morning against the pain rules:
/// - no session the day before went above [PainRules.maxDuring],
/// - swelling and stiffness are not worse than the morning before,
/// - pain is no higher than the previous check-in (when [PainRules.morningNoWorse]),
/// - the load test, if the program has one, rose by no more than its limit.
///
/// With two knees each is checked against its own previous morning, and a
/// morning only meets the rules if every knee does. Days without a check-in
/// are skipped: they neither count nor break a streak.
List<RuleDay> evaluateRuleDays({
  required List<CheckIn> checkIns,
  required List<SessionLog> sessions,
  required PainRules rules,
}) {
  final worstByDay = <String, int>{};
  for (final s in sessions) {
    final d = dayKey(s.startedAt);
    final prev = worstByDay[d];
    if (prev == null || s.painAfter > prev) worstByDay[d] = s.painAfter;
  }
  final byDay = <String, List<CheckIn>>{};
  for (final c in checkIns) {
    (byDay[c.day] ??= []).add(c);
  }
  final days = byDay.keys.toList()..sort();

  final out = <RuleDay>[];
  final previous = <String, CheckIn>{};
  final load = rules.loadTest;
  for (final day in days) {
    final reasons = <String>[];
    final worst = worstByDay[dayKey(_dayBefore(day))];
    if (worst != null && worst > rules.maxDuring) {
      reasons.add('Pain reached $worst/10 in yesterday\'s session');
    }
    final rows = byDay[day]!..sort((a, b) => a.knee.compareTo(b.knee));
    for (final c in rows) {
      final who = c.knee == singleKneeKey ? '' : '${checkInKeyLabel(c.knee)}: ';
      final before = previous[c.knee];
      if (c.swelling == Change.more) {
        reasons.add('${who}more swelling this morning');
      }
      if (c.stiffness == Change.more) {
        reasons.add('${who}more stiffness this morning');
      }
      if (rules.morningNoWorse && before != null && c.pain > before.pain) {
        reasons.add('${who}morning pain up from ${before.pain} to ${c.pain}');
      }
      final was = before?.loadPain, now = c.loadPain;
      if (load != null &&
          was != null &&
          now != null &&
          now - was > load.maxRise) {
        reasons.add('$who${load.name.toLowerCase()} up from $was to $now');
      }
      previous[c.knee] = c;
    }
    out.add(
      RuleDay(day: day, reasons: [for (final r in reasons) _capitalise(r)]),
    );
  }
  return out;
}

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime _dayBefore(String day) {
  final d = DateTime.parse(day);
  return DateTime(d.year, d.month, d.day - 1);
}

/// Rule days on or after [since], newest last.
List<RuleDay> _since(List<RuleDay> days, DateTime? since) {
  if (since == null) return days;
  final from = dayKey(since);
  return [
    for (final d in days)
      if (d.day.compareTo(from) >= 0) d,
  ];
}

/// Days meeting the pain rules since the last day that broke them, counting
/// only days on or after [since].
int painRuleStreak(List<RuleDay> days, {DateTime? since}) {
  var n = 0;
  for (final d in _since(days, since).reversed) {
    if (!d.met) break;
    n++;
  }
  return n;
}

// ------------------------------------------------------------------ advice

enum AdviceKind {
  /// Nothing to adjust.
  none,

  /// Rules broken once: repeat the same dose, don't progress.
  hold,

  /// Rules broken twice in a row: suggest moving down a phase.
  dropBack,
}

class Advice {
  const Advice(this.kind, [this.reasons = const []]);

  final AdviceKind kind;

  /// From the most recent broken day.
  final List<String> reasons;
}

/// Flare-up advice from the latest check-ins in this phase. A check-in older
/// than yesterday is stale and gives no advice.
Advice adviseFrom(
  List<RuleDay> days, {
  required DateTime now,
  DateTime? since,
}) {
  final recent = _since(days, since);
  if (recent.isEmpty) return const Advice(AdviceKind.none);
  final last = recent.last;
  final yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
  if (last.met || last.day.compareTo(yesterday) < 0) {
    return const Advice(AdviceKind.none);
  }
  final twice = recent.length >= 2 && !recent[recent.length - 2].met;
  return Advice(twice ? AdviceKind.dropBack : AdviceKind.hold, last.reasons);
}

// -------------------------------------------------------------------- gate

class CriterionStatus {
  const CriterionStatus({
    required this.criterion,
    required this.met,
    required this.answered,
    this.progress,
  });

  final GateCriterion criterion;
  final bool met;

  /// A self-test result exists (always false for tracked criteria).
  final bool answered;

  /// e.g. "4 / 7 days" or "Best 24 s".
  final String? progress;
}

class GateStatus {
  const GateStatus({
    required this.items,
    required this.daysInPhase,
    required this.minDays,
  });

  final List<CriterionStatus> items;
  final int daysInPhase;
  final int minDays;

  bool get minDaysMet => daysInPhase >= minDays;
  bool get ready => minDaysMet && items.every((i) => i.met);
  int get metCount => items.where((i) => i.met).length;
}

/// Evaluates [phase]'s gate. [results] are this phase's self-test answers;
/// only those since [stintStart] count, and the newest per criterion wins.
GateStatus evaluateGate({
  required Phase phase,
  required List<GateResult> results,
  required List<RuleDay> ruleDays,
  required DateTime stintStart,
  required DateTime now,
}) {
  final latest = <String, GateResult>{};
  for (final r in results) {
    if (r.at.isBefore(stintStart)) continue;
    final prev = latest[r.criterionId];
    if (prev == null || !r.at.isBefore(prev.at)) latest[r.criterionId] = r;
  }
  final streak = painRuleStreak(ruleDays, since: stintStart);

  final items = [
    for (final c in phase.gate)
      switch (c.type) {
        GateType.check => CriterionStatus(
          criterion: c,
          met: latest[c.id]?.passed ?? false,
          answered: latest.containsKey(c.id),
        ),
        GateType.number => _number(c, latest[c.id]),
        GateType.auto => CriterionStatus(
          criterion: c,
          met: streak >= (c.min ?? 0),
          answered: false,
          progress: '${streak.clamp(0, c.min ?? streak)} / ${_n(c.min)} days',
        ),
      },
  ];

  return GateStatus(
    items: items,
    daysInPhase: _calendarDaysBetween(stintStart, now) + 1,
    minDays: phase.minDays,
  );
}

CriterionStatus _number(GateCriterion c, GateResult? r) {
  final v = r?.value;
  return CriterionStatus(
    criterion: c,
    met: v != null && v >= (c.min ?? 0),
    answered: r != null,
    progress: v == null
        ? null
        : '${_n(v)}${c.unit == null ? '' : ' ${c.unit}'}',
  );
}

String _n(num? v) =>
    v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

int _calendarDaysBetween(DateTime a, DateTime b) {
  final da = DateTime.utc(a.year, a.month, a.day);
  final db = DateTime.utc(b.year, b.month, b.day);
  return db.difference(da).inDays;
}

// ------------------------------------------------------------- entry check

/// Suggests a starting phase from the entry check: the second phase when
/// every one of the first phase's criteria is answered yes, else the first.
/// [answers] maps criterion id → yes/no; tracked criteria are asked as
/// "has the knee settled after activity this past week?".
int suggestStartPhase(Program program, Map<String, bool> answers) {
  final first = program.phases.first;
  final allYes = first.gate.every((c) => answers[c.id] ?? false);
  return allYes && program.phases.length > 1 ? 1 : 0;
}
