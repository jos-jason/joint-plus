import 'package:flutter/material.dart';

import '../data/knees.dart';
import '../theme/tokens.dart';
import 'choice_cells.dart';
import 'stark_primitives.dart';

/// Left / right / both, and with both, which knee each exercise starts on.
class KneePicker extends StatelessWidget {
  const KneePicker({super.key, required this.value, required this.onChanged});

  final KneeSetup? value;
  final ValueChanged<KneeSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final which = v == null ? null : (v.both ? 2 : v.first.index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceCells(
          semanticPrefix: 'Recovering knee',
          labels: const ['Left', 'Right', 'Both'],
          value: which,
          onChanged: (i) => onChanged(
            i == 2
                ? KneeSetup.both(first: v?.first ?? Knee.left)
                : KneeSetup.one(Knee.values[i]),
          ),
        ),
        if (v != null && v.both) ...[
          const SizedBox(height: JSpace.lg),
          const SectionLabel('Start each exercise with'),
          const SizedBox(height: JSpace.sm),
          ChoiceCells(
            semanticPrefix: 'Start with',
            labels: const ['Left', 'Right'],
            value: v.first.index,
            onChanged: (i) => onChanged(KneeSetup.both(first: Knee.values[i])),
          ),
          const SizedBox(height: JSpace.sm),
          const Text(
            'Usually the more sensitive knee, so it gets your best effort.',
            style: JType.secondary,
          ),
        ],
      ],
    );
  }
}
