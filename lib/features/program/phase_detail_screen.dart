import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_providers.dart';
import '../../content/labels.dart';
import '../../content/models.dart';
import '../../engine/engine_providers.dart';
import '../../engine/progression.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_dialog.dart';
import '../../widgets/stark_primitives.dart';
import '../exercise/exercise_row.dart';

/// Everything about one phase: goal, cautions, both sessions, and the checks
/// that unlock the next phase.
class PhaseDetailScreen extends ConsumerWidget {
  const PhaseDetailScreen({super.key, required this.phaseId});

  final String phaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncContent(
          value: ref.watch(activeProgramProvider),
          builder: (program) {
            final phase = program.phases
                .where((p) => p.id == phaseId)
                .firstOrNull;
            if (phase == null) {
              return ContentErrorView(error: 'Unknown phase "$phaseId"');
            }
            final exercises = ref.watch(contentProvider).requireValue.exercises;
            final isLast = phase.number == program.phases.length;
            return ListView(
              children: [
                PageHeader(title: phase.name, onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    JSpace.gutter,
                    0,
                    JSpace.gutter,
                    JSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(
                        'Phase ${phase.number} of ${program.phases.length}'
                        '  ·  min ${phase.minDays} days',
                        color: JColors.green,
                      ),
                      const SizedBox(height: JSpace.md),
                      Text(phase.goal, style: JType.body),
                      for (final c in phase.cautions) ...[
                        const SizedBox(height: JSpace.sm),
                        Text('—  $c', style: JType.secondary),
                      ],
                    ],
                  ),
                ),
                for (final kind in [SessionKind.strength, SessionKind.daily])
                  if (phase.sessions[kind] case final session?)
                    _SessionSection(
                      program: program,
                      session: session,
                      exercises: exercises,
                    ),
                _GateSection(
                  program: program,
                  phase: phase,
                  title: isLast ? 'To graduate' : 'Checks to move on',
                ),
                if (isLast)
                  Padding(
                    padding: const EdgeInsets.all(JSpace.gutter),
                    child: Text(
                      'Then: ${program.maintenance}',
                      style: JType.secondary,
                    ),
                  ),
                const SizedBox(height: JSpace.xxl),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
    required this.program,
    required this.session,
    required this.exercises,
  });

  final Program program;
  final SessionTemplate session;
  final Map<String, Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            JSpace.gutter,
            JSpace.lg,
            JSpace.gutter,
            JSpace.sm,
          ),
          child: SectionLabel(
            '${session.name}  ·  ${session.kind.frequency(program)}'
            '  ·  ~${session.estimateMinutes(exercises)} min',
          ),
        ),
        const Hairline(),
        SessionExerciseList(session: session, exercises: exercises),
      ],
    );
  }
}

/// The phase's gate. For the phase you're in, checks are tappable self-tests
/// and the button to move on appears once everything is met.
class _GateSection extends ConsumerWidget {
  const _GateSection({
    required this.program,
    required this.phase,
    required this.title,
  });

  final Program program;
  final Phase phase;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;
    final isCurrent =
        progress != null &&
        progress.started &&
        !progress.graduated &&
        program.phases[progress.phaseIndex].id == phase.id;
    final status = isCurrent ? ref.watch(gateStatusProvider) : null;
    final isLast = phase.number == program.phases.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            JSpace.gutter,
            JSpace.xl,
            JSpace.gutter,
            JSpace.sm,
          ),
          child: SectionLabel(
            status == null
                ? title
                : '$title  ·  ${status.metCount}/${status.items.length}',
          ),
        ),
        const Hairline(),
        if (status == null)
          for (final g in phase.gate) _CriterionRow(criterion: g)
        else ...[
          for (final s in status.items)
            _CriterionRow(
              criterion: s.criterion,
              status: s,
              onTap: switch (s.criterion.type) {
                GateType.auto => null,
                GateType.check => () => _toggle(ref, s),
                GateType.number => () => _measure(context, ref, s),
              },
            ),
          _MinDaysRow(status: status),
          Padding(
            padding: const EdgeInsets.all(JSpace.gutter),
            child: StarkButton(
              label: isLast ? 'Graduate' : 'Move to Phase ${phase.number + 1}',
              onPressed: status.ready ? () => _advance(context, ref) : null,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggle(WidgetRef ref, CriterionStatus s) => ref
      .read(progressionActionsProvider)
      .answer(phaseId: phase.id, criterionId: s.criterion.id, passed: !s.met);

  Future<void> _measure(
    BuildContext context,
    WidgetRef ref,
    CriterionStatus s,
  ) async {
    final c = s.criterion;
    final v = await showNumberInput(
      context,
      title: c.text,
      body: 'Your best try today. Needed: ${_fmt(c.min)} ${c.unit ?? ''}.',
      unit: c.unit,
    );
    if (v == null) return;
    await ref
        .read(progressionActionsProvider)
        .answer(
          phaseId: phase.id,
          criterionId: c.id,
          passed: v >= (c.min ?? 0),
          value: v.toDouble(),
        );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    final isLast = phase.number == program.phases.length;
    final next = isLast ? null : program.phases[phase.number];
    final ok = await showStarkConfirm(
      context,
      title: isLast ? 'Graduate?' : 'Move to ${next!.name}?',
      body: isLast
          ? 'From now on: ${program.maintenance}'
          : 'Phase ${next!.number} starts today with new sessions and new '
                'checks. Ease into the new exercises.',
      confirm: isLast ? 'Graduate' : 'Move on',
      cancel: 'Not yet',
    );
    if (!ok) return;
    await ref.read(progressionActionsProvider).advance();
    if (context.mounted) context.pop();
  }
}

String _fmt(num? v) =>
    v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion, this.status, this.onTap});

  final GateCriterion criterion;
  final CriterionStatus? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final g = criterion;
    final met = status?.met ?? false;
    final failed = status != null && status!.answered && !met;
    final detail = [
      g.kindLabel,
      ?status?.progress,
      if (failed && g.type == GateType.check) 'Not yet',
    ].join('  ·  ');
    return Semantics(
      button: onTap != null,
      checked: status == null ? null : met,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: JSpace.gutter,
                vertical: JSpace.md + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckBox(met: met),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.text, style: JType.body),
                        const SizedBox(height: 2),
                        Text(detail, style: JType.secondary),
                        if (g.help != null) ...[
                          const SizedBox(height: JSpace.xs),
                          Text(g.help!, style: JType.secondary),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Hairline(),
          ],
        ),
      ),
    );
  }
}

class _MinDaysRow extends StatelessWidget {
  const _MinDaysRow({required this.status});

  final GateStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: JSpace.gutter,
            vertical: JSpace.md + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckBox(met: status.minDaysMet),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'At least ${status.minDays} days in this phase',
                      style: JType.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tracked by the app  ·  day ${status.daysInPhase}',
                      style: JType.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Hairline(),
      ],
    );
  }
}

/// Square box; green with a black tick when met.
class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.met});

  final bool met;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(top: 3, right: JSpace.md),
      decoration: BoxDecoration(
        color: met ? JColors.green : Colors.transparent,
        border: Border.all(color: met ? JColors.green : JColors.grey),
      ),
      child: met
          ? const Icon(Icons.check, size: 14, color: JColors.black)
          : null,
    );
  }
}
