import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_providers.dart';
import '../../content/models.dart';
import '../../engine/engine_providers.dart';
import '../../engine/progression.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/choice_cells.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_primitives.dart';

/// Entry check: the first phase's gate asked as yes/no questions. All yes →
/// start at Phase 2, otherwise Phase 1. You can always pick the other one.
class EntryCheckScreen extends ConsumerStatefulWidget {
  const EntryCheckScreen({super.key});

  @override
  ConsumerState<EntryCheckScreen> createState() => _EntryCheckScreenState();
}

class _EntryCheckScreenState extends ConsumerState<EntryCheckScreen> {
  final _answers = <String, bool>{};
  bool _saving = false;

  static String question(GateCriterion c) => switch (c.type) {
    GateType.check => c.text,
    GateType.number => '${c.text}: ${_num(c.min)} ${c.unit ?? ''}'.trim(),
    GateType.auto =>
      'Over the past week, the knee has settled after activity, with no '
          'increase in swelling',
  };

  static String _num(num? v) =>
      v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

  Future<void> _start(Program program, int phaseIndex) async {
    setState(() => _saving = true);
    final actions = ref.read(progressionActionsProvider);
    await actions.startAt(phaseIndex);
    // Starting in Phase 1: keep the yes/no checks as its first gate answers.
    if (phaseIndex == 0) {
      for (final c in program.phases.first.gate) {
        if (c.type != GateType.check) continue;
        if (_answers[c.id] case final yes?) {
          await actions.answer(
            phaseId: program.phases.first.id,
            criterionId: c.id,
            passed: yes,
          );
        }
      }
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AsyncContent(
          value: ref.watch(activeProgramProvider),
          builder: (program) {
            final gate = program.phases.first.gate;
            final done = gate.every((c) => _answers.containsKey(c.id));
            final suggested = suggestStartPhase(program, _answers);
            final other = suggested == 0 ? 1 : 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      PageHeader(
                        title: 'Where to start',
                        onBack: () => context.pop(),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          JSpace.gutter,
                          0,
                          JSpace.gutter,
                          JSpace.xl,
                        ),
                        child: Text(
                          'The same checks that unlock Phase 2. Answer for '
                          "today. If you're not sure, answer No.",
                          style: JType.secondary,
                        ),
                      ),
                      for (final c in gate)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            JSpace.gutter,
                            0,
                            JSpace.gutter,
                            JSpace.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(question(c), style: JType.body),
                              if (c.help != null) ...[
                                const SizedBox(height: JSpace.xs),
                                Text(c.help!, style: JType.secondary),
                              ],
                              const SizedBox(height: JSpace.md),
                              ChoiceCells(
                                semanticPrefix: question(c),
                                labels: const ['No', 'Yes'],
                                value: switch (_answers[c.id]) {
                                  null => null,
                                  false => 0,
                                  true => 1,
                                },
                                onChanged: (i) =>
                                    setState(() => _answers[c.id] = i == 1),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Hairline(),
                Padding(
                  padding: const EdgeInsets.all(JSpace.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (done) ...[
                        SectionLabel(
                          'Suggested: Phase ${suggested + 1}',
                          color: JColors.green,
                        ),
                        const SizedBox(height: JSpace.md),
                      ],
                      StarkButton(
                        label: done
                            ? 'Start ${program.phases[suggested].name}'
                            : 'Answer all ${gate.length}',
                        onPressed: done && !_saving
                            ? () => _start(program, suggested)
                            : null,
                      ),
                      if (done) ...[
                        const SizedBox(height: JSpace.sm),
                        StarkButton.secondary(
                          label: 'Start at Phase ${other + 1} instead',
                          onPressed: _saving
                              ? null
                              : () => _start(program, other),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
