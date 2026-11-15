import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../content/content_providers.dart';
import '../../engine/engine_providers.dart';
import '../../content/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_primitives.dart';

/// Program: the phases as a vertical list, current one in green.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPhaseIndexProvider);
    return SafeArea(
      bottom: false,
      child: AsyncContent(
        value: ref.watch(activeProgramProvider),
        builder: (program) => ListView(
          children: [
            PageHeader(label: 'Program', title: program.name),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                JSpace.gutter,
                0,
                JSpace.gutter,
                JSpace.lg,
              ),
              child: Text(program.description, style: JType.secondary),
            ),
            const Hairline(),
            for (final (i, phase) in program.phases.indexed)
              _PhaseTile(phase: phase, state: _stateFor(i, current)),
            _RedFlags(program: program),
          ],
        ),
      ),
    );
  }

  static _PhaseState _stateFor(int i, int current) => i < current
      ? _PhaseState.done
      : i == current
      ? _PhaseState.current
      : _PhaseState.locked;
}

enum _PhaseState { done, current, locked }

/// Always visible on the Program tab: when to stop and see a clinician.
class _RedFlags extends StatelessWidget {
  const _RedFlags({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JSpace.gutter,
        JSpace.xl,
        JSpace.gutter,
        JSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            'Stop and contact your clinician if',
            color: JColors.white,
          ),
          const SizedBox(height: JSpace.md),
          for (final f in program.redFlags)
            Padding(
              padding: const EdgeInsets.only(bottom: JSpace.sm),
              child: Text('—  $f', style: JType.body),
            ),
        ],
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile({required this.phase, required this.state});

  final Phase phase;
  final _PhaseState state;

  @override
  Widget build(BuildContext context) {
    return StarkRow(
      leading: _PhaseNumber(n: phase.number, state: state),
      title: phase.name,
      subtitle: 'Min ${phase.minDays} days  ·  ${phase.gate.length} checks',
      // Locked phases can still be browsed, just not started.
      onTap: () => context.push(Routes.phase(phase.id)),
      trailing: switch (state) {
        _PhaseState.current => const SectionLabel(
          'Current',
          color: JColors.green,
        ),
        _PhaseState.locked => const Icon(
          Icons.lock_outline,
          size: 16,
          color: JColors.grey,
        ),
        _PhaseState.done => const Icon(
          Icons.check,
          size: 18,
          color: JColors.green,
        ),
      },
    );
  }
}

class _PhaseNumber extends StatelessWidget {
  const _PhaseNumber({required this.n, required this.state});

  final int n;
  final _PhaseState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _PhaseState.current => JColors.green,
      _PhaseState.done => JColors.white,
      _PhaseState.locked => JColors.grey,
    };
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: Text('$n', style: JType.number.copyWith(color: color)),
    );
  }
}
