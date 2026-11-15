import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_providers.dart';
import '../data/data_providers.dart';
import '../data/database.dart';
import 'progression.dart';

/// Where you are in the active program, live from the phase event log.
final progressProvider = StreamProvider<ProgramProgress>((ref) async* {
  final program = await ref.watch(activeProgramProvider.future);
  yield* ref
      .watch(databaseProvider)
      .watchPhaseEvents(program.id)
      .map((events) => ProgramProgress.from(program, events));
});

/// Every phase change in the active program, oldest first.
final phaseEventsProvider = StreamProvider<List<PhaseEvent>>((ref) async* {
  final program = await ref.watch(activeProgramProvider.future);
  yield* ref.watch(databaseProvider).watchPhaseEvents(program.id);
});

/// 0-based index of the current phase (Phase 1 until the entry check).
final currentPhaseIndexProvider = Provider<int>(
  (ref) => ref.watch(progressProvider).value?.phaseIndex ?? 0,
);

/// Every check-in morning judged against the pain rules. Empty while loading.
final ruleDaysProvider = Provider<List<RuleDay>>((ref) {
  final program = ref.watch(activeProgramProvider).value;
  final checkIns = ref.watch(checkInsProvider).value;
  final sessions = ref.watch(sessionLogsProvider).value;
  if (program == null || checkIns == null || sessions == null) return const [];
  return evaluateRuleDays(
    checkIns: checkIns,
    sessions: [for (final s in sessions) s.log],
    rules: program.painRules,
  );
});

/// Flare-up advice for today.
final adviceProvider = Provider<Advice>((ref) {
  final progress = ref.watch(progressProvider).value;
  if (progress == null || !progress.started) {
    return const Advice(AdviceKind.none);
  }
  return adviseFrom(
    ref.watch(ruleDaysProvider),
    now: ref.watch(clockProvider)(),
    since: progress.stintStart,
  );
});

/// Self-test answers for one phase of the active program.
final gateResultsProvider = StreamProvider.family<List<GateResult>, String>((
  ref,
  phaseId,
) async* {
  final program = await ref.watch(activeProgramProvider.future);
  yield* ref.watch(databaseProvider).watchGateResults(program.id, phaseId);
});

/// The current phase's gate, or null until the entry check is done.
final gateStatusProvider = Provider<GateStatus?>((ref) {
  final program = ref.watch(activeProgramProvider).value;
  final progress = ref.watch(progressProvider).value;
  if (program == null || progress == null || !progress.started) return null;
  final phase = program.phases[progress.phaseIndex];
  return evaluateGate(
    phase: phase,
    results: ref.watch(gateResultsProvider(phase.id)).value ?? const [],
    ruleDays: ref.watch(ruleDaysProvider),
    stintStart: progress.stintStart!,
    now: ref.watch(clockProvider)(),
  );
});

/// Writes phase changes and self-test answers.
class ProgressionActions {
  ProgressionActions(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);
  DateTime get _now => _ref.read(clockProvider)();

  Future<String> _programId() async =>
      (await _ref.read(activeProgramProvider.future)).id;

  Future<void> startAt(int phaseIndex) async {
    final program = await _ref.read(activeProgramProvider.future);
    await _db.addPhaseEvent(
      programId: program.id,
      phaseId: program.phases[phaseIndex].id,
      kind: PhaseEventKind.entry,
      at: _now,
    );
  }

  /// Moves to the next phase, or graduates from the last one.
  Future<void> advance() async {
    final program = await _ref.read(activeProgramProvider.future);
    final i = _ref.read(currentPhaseIndexProvider);
    final last = i == program.phases.length - 1;
    await _db.addPhaseEvent(
      programId: program.id,
      phaseId: program.phases[last ? i : i + 1].id,
      kind: last ? PhaseEventKind.graduate : PhaseEventKind.advance,
      at: _now,
    );
  }

  Future<void> dropBack() async {
    final program = await _ref.read(activeProgramProvider.future);
    final i = _ref.read(currentPhaseIndexProvider);
    if (i == 0) return;
    await _db.addPhaseEvent(
      programId: program.id,
      phaseId: program.phases[i - 1].id,
      kind: PhaseEventKind.dropBack,
      at: _now,
    );
  }

  Future<void> answer({
    required String phaseId,
    required String criterionId,
    required bool passed,
    double? value,
  }) async => _db.saveGateResult(
    programId: await _programId(),
    phaseId: phaseId,
    criterionId: criterionId,
    passed: passed,
    value: value,
    at: _now,
  );
}

final progressionActionsProvider = Provider(ProgressionActions.new);
