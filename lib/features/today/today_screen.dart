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
import '../checkin/checkin_screen.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_primitives.dart';
import '../../widgets/stark_tabs.dart';
import '../exercise/exercise_row.dart';

/// Today: current phase, today's session and its exercises, one green START.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  static const _kinds = [SessionKind.strength, SessionKind.daily];

  // Placeholder default until the engine picks by schedule (milestone 6).
  SessionKind _kind = SessionKind.strength;

  @override
  Widget build(BuildContext context) {
    final phaseIndex = ref.watch(currentPhaseIndexProvider);
    return SafeArea(
      bottom: false,
      child: AsyncContent(
        value: ref.watch(activeProgramProvider),
        builder: (program) {
          final exercises = ref.watch(contentProvider).requireValue.exercises;
          final phase = program.phases[phaseIndex];
          final kinds = _kinds.where(phase.sessions.containsKey).toList();
          final kind = kinds.contains(_kind) ? _kind : kinds.first;
          final session = phase.sessions[kind]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    PageHeader(
                      label: 'Joint+  ·  ${program.shortName}',
                      title: session.name,
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
                      child: Text(
                        '${session.required.length} exercises  ·  '
                        '~${session.estimateMinutes(exercises)} min  ·  '
                        '${kind.frequency(program)}',
                        style: JType.secondary,
                      ),
                    ),
                    const SizedBox(height: JSpace.lg),
                    _EngineNotice(program: program),
                    const Hairline(),
                    _PhaseRow(phase: phase, phaseCount: program.phases.length),
                    const _CheckInRow(),
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
                    const Hairline(),
                    SessionExerciseList(session: session, exercises: exercises),
                  ],
                ),
              ),
              const Hairline(),
              Padding(
                padding: const EdgeInsets.all(JSpace.gutter),
                child: StarkButton(
                  label: 'Start session',
                  onPressed: () => context.push(Routes.session(kind)),
                ),
              ),
            ],
          );
        },
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
      trailing: !done
          ? null
          : const Icon(Icons.check, size: 20, color: JColors.green),
      onTap: () => context.push(Routes.checkIn),
    );
  }
}
