import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../content/content_providers.dart';
import '../../engine/engine_providers.dart';
import '../../engine/progression.dart';
import '../../widgets/stark_dialog.dart';
import '../../content/labels.dart';
import '../../content/models.dart';
import '../../data/data_providers.dart';
import '../../data/knees.dart';
import '../../util/dates.dart';
import 'day_plan.dart';
import '../checkin/checkin_screen.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_primitives.dart';
import '../../widgets/stark_tabs.dart';
import '../exercise/exercise_row.dart';

/// Today: whether it's a strength day or mobility only, what's done so far,
/// and the session to do next with one start button.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  static const _kinds = [SessionKind.strength, SessionKind.daily];

  /// The session the user picked; null follows the day plan.
  SessionKind? _kind;

  @override
  Widget build(BuildContext context) {
    final phaseIndex = ref.watch(currentPhaseIndexProvider);
    final plan = ref.watch(dayPlanProvider);
    final now = ref.watch(clockProvider)();
    return SafeArea(
      bottom: false,
      child: AsyncContent(
        value: ref.watch(activeProgramProvider),
        builder: (program) {
          final exercises = ref.watch(contentProvider).requireValue.exercises;
          final phase = program.phases[phaseIndex];
          final kinds = _kinds.where(phase.sessions.containsKey).toList();
          final picked = _kind;
          final kind = picked != null && kinds.contains(picked)
              ? picked
              : kinds.contains(plan.next)
              ? plan.next
              : kinds.first;
          final session = phase.sessions[kind]!;

          final summary = plan.allDone
              ? 'All done for today. Nice work.'
              : plan.strengthDay
              ? 'Mobility and strength today.'
              : [
                  'Mobility only today.',
                  if (plan.nextStrength case final d?)
                    'Next strength day: ${shortDate(d)}.',
                ].join(' ');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    PageHeader(
                      label: '${program.shortName}  ·  ${shortDate(now)}',
                      title: plan.strengthDay ? 'Strength day' : 'Mobility day',
                      trailing: StarkIconButton(
                        icon: Icons.tune,
                        semanticLabel: 'Settings',
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: JSpace.gutter,
                      ),
                      child: Text(summary, style: JType.secondary),
                    ),
                    const SizedBox(height: JSpace.lg),
                    _EngineNotice(program: program),
                    const Hairline(),
                    const _CheckInRow(),
                    for (final k in [SessionKind.daily, SessionKind.strength])
                      if (phase.sessions[k] case final s?)
                        _PlanRow(
                          kind: k,
                          session: s,
                          plan: plan,
                          minutes: s.estimateMinutes(exercises),
                          selected: k == kind,
                          onTap: () => setState(() => _kind = k),
                        ),
                    _PhaseRow(phase: phase, phaseCount: program.phases.length),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        JSpace.gutter,
                        JSpace.md,
                        JSpace.gutter,
                        0,
                      ),
                      child: StarkTabs(
                        labels: [for (final k in kinds) k.label],
                        index: kinds.indexOf(kind),
                        onChanged: (i) => setState(() => _kind = kinds[i]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        JSpace.gutter,
                        JSpace.md,
                        JSpace.gutter,
                        JSpace.sm,
                      ),
                      child: Text(
                        '${session.required.length} exercises  ·  '
                        '~${session.estimateMinutes(exercises)} min  ·  '
                        '${kind.frequency(program)}',
                        style: JType.secondary,
                      ),
                    ),
                    const Hairline(),
                    SessionExerciseList(session: session, exercises: exercises),
                  ],
                ),
              ),
              const Hairline(),
              Padding(
                padding: const EdgeInsets.all(JSpace.gutter),
                child: _StartButton(kind: kind, plan: plan),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One green button for what's due; an outlined one for doing more.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.kind, required this.plan});

  final SessionKind kind;
  final DayPlan plan;

  @override
  Widget build(BuildContext context) {
    final name = kind == SessionKind.strength ? 'strength' : 'mobility';
    void start() => context.push(Routes.session(kind));
    if (plan.isDone(kind)) {
      return StarkButton.secondary(label: 'Do $name again', onPressed: start);
    }
    if (!plan.planned.contains(kind)) {
      return StarkButton.secondary(
        label: 'Start $name anyway',
        onPressed: start,
      );
    }
    return StarkButton(label: 'Start $name', onPressed: start);
  }
}

/// Square status box: green with a tick when done, outlined when due, faint
/// when not planned today.
class _DoneBox extends StatelessWidget {
  const _DoneBox({required this.done, this.planned = true});

  final bool done;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? JColors.green : Colors.transparent,
        border: Border.all(
          color: done
              ? JColors.green
              : planned
              ? JColors.white
              : JColors.line,
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: JColors.black)
          : null,
    );
  }
}

/// A session in today's checklist: done, due, or not planned today.
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.kind,
    required this.session,
    required this.plan,
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final SessionKind kind;
  final SessionTemplate session;
  final DayPlan plan;
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strength = kind == SessionKind.strength;
    final done = plan.done[kind];
    final planned = plan.planned.contains(kind);
    final String subtitle;
    if (done != null) {
      subtitle =
          'Done  ·  ${done.exercisesDone}/${done.exercisesPlanned} exercises'
          '${planned ? '' : '  ·  extra'}';
    } else if (planned) {
      subtitle = '~$minutes min  ·  ${strength ? 'due today' : 'every day'}';
    } else {
      subtitle = [
        'Rest day',
        if (plan.nextStrength case final d?) 'next ${shortDate(d)}',
      ].join('  ·  ');
    }
    return Semantics(
      selected: selected,
      child: StarkRow(
        leading: _DoneBox(done: done != null, planned: planned),
        title: strength ? 'Strength' : 'Mobility',
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}

class _PhaseRow extends ConsumerWidget {
  const _PhaseRow({required this.phase, required this.phaseCount});

  final Phase phase;
  final int phaseCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(gateStatusProvider);
    return StarkRow(
      title: phase.name,
      subtitle: [
        'Phase ${phase.number} of $phaseCount',
        if (gate == null)
          'min ${phase.minDays} days'
        else ...[
          'day ${gate.daysInPhase}',
          '${gate.metCount}/${gate.items.length} checks',
        ],
      ].join('  ·  '),
      onTap: () => context.push(Routes.phase(phase.id)),
    );
  }
}

/// The one thing the engine wants you to know today, if anything: start
/// here, a flare-up, ready to move on, or maintenance.
class _EngineNotice extends ConsumerWidget {
  const _EngineNotice({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;
    if (progress == null) return const SizedBox.shrink();
    final advice = ref.watch(adviceProvider);
    final gate = ref.watch(gateStatusProvider);
    final i = progress.phaseIndex;
    final why = advice.reasons.join('. ');

    final (label, text, color, onTap) = switch (()) {
      _ when !progress.started => (
        'Start here',
        'Take the 2-minute entry check to find your starting phase.',
        JColors.green,
        () => context.push(Routes.start),
      ),
      _ when advice.kind == AdviceKind.dropBack && i > 0 => (
        'Flare-up',
        '$why. Two mornings in a row over the pain rules: consider dropping '
            'back to Phase $i.',
        JColors.white,
        () => _confirmDropBack(context, ref),
      ),
      _ when advice.kind == AdviceKind.dropBack => (
        'Flare-up',
        '$why. Two mornings in a row over the pain rules. Keep the doses '
            'gentle, and contact your clinician if it does not settle.',
        JColors.white,
        null,
      ),
      _ when advice.kind == AdviceKind.hold => (
        'Repeat this dose',
        '$why. Keep the same exercises and doses today; '
            "don't move to harder versions.",
        JColors.white,
        null,
      ),
      _ when progress.graduated => (
        'Maintenance',
        program.maintenance,
        JColors.green,
        null,
      ),
      _ when gate != null && gate.ready => (
        'Ready',
        i == program.phases.length - 1
            ? 'All checks passed. You can graduate to maintenance.'
            : 'All checks passed. You can move on to Phase ${i + 2}.',
        JColors.green,
        () => context.push(Routes.phase(program.phases[i].id)),
      ),
      _ => (null, null, null, null),
    };
    if (label == null) return const SizedBox.shrink();

    return Column(
      children: [
        const Hairline(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: JSpace.gutter,
              vertical: JSpace.md + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(label, color: color!),
                      const SizedBox(height: JSpace.xs),
                      Text(text!, style: JType.body),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: JSpace.md),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: JColors.grey,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDropBack(BuildContext context, WidgetRef ref) async {
    final i = ref.read(currentPhaseIndexProvider);
    final ok = await showStarkConfirm(
      context,
      title: 'Drop back to Phase $i?',
      body:
          'You go back to ${program.phases[i - 1].name} and its doses. '
          'Its checks start fresh, so you move up again once the knee has '
          'settled.',
      confirm: 'Drop back',
      cancel: 'Stay in Phase ${i + 1}',
    );
    if (ok) await ref.read(progressionActionsProvider).dropBack();
  }
}

/// Prompts for today's check-in, or summarises it once done (tap to edit).
class _CheckInRow extends ConsumerWidget {
  const _CheckInRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(todayCheckInProvider).value ?? const [];
    final done = rows.isNotEmpty;
    return StarkRow(
      leading: _DoneBox(done: done),
      title: 'Morning check-in',
      subtitle: !done
          ? 'Pain, swelling, stiffness — 3 taps'
          : rows.length == 1
          ? 'Pain ${rows.single.pain}'
                '  ·  swelling ${rows.single.swelling.label.toLowerCase()}'
                '  ·  stiffness ${rows.single.stiffness.label.toLowerCase()}'
          : [
              for (final c in rows)
                '${checkInKeyLabel(c.knee).split(' ').first} pain ${c.pain}',
            ].join('  ·  '),
      onTap: () => context.push(Routes.checkIn),
    );
  }
}
