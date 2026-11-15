import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../content/content_providers.dart';
import '../../content/labels.dart';
import '../../content/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/exercise_illustration.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_primitives.dart';
import 'exercise_row.dart';

/// One exercise: what it's for, how to do it, what to avoid, and where it
/// sits in the easier/harder chain. Shows the dose when opened from a session.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId, this.dose});

  final String exerciseId;

  /// Present when opened from a session; null when browsing (e.g. a swap).
  final SessionDose? dose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: AsyncContent(
          value: ref.watch(contentProvider),
          builder: (lib) {
            final ex = lib.exercises[exerciseId];
            if (ex == null) {
              return ContentErrorView(error: 'Unknown exercise "$exerciseId"');
            }
            return _Body(
              exercise: ex,
              dose: dose,
              easier: ex.easier == null ? null : lib.exercise(ex.easier!),
              harder: ex.harder == null ? null : lib.exercise(ex.harder!),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.exercise,
    required this.dose,
    required this.easier,
    required this.harder,
  });

  final Exercise exercise;
  final SessionDose? dose;
  final Exercise? easier;
  final Exercise? harder;

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    return ListView(
      children: [
        PageHeader(title: ex.name, onBack: () => context.pop()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: JSpace.gutter),
          child: ExerciseIllustration(ex),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            JSpace.gutter,
            JSpace.lg,
            JSpace.gutter,
            JSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dose case (:final dose, :final restSec)?) ...[
                Text(
                  dose.describe(ex),
                  style: JType.heading.copyWith(color: JColors.green),
                ),
                if (dose.sets > 1) ...[
                  const SizedBox(height: JSpace.xs),
                  Text('Rest $restSec s between sets', style: JType.secondary),
                ],
                if (dose.note != null) ...[
                  const SizedBox(height: JSpace.sm),
                  Text(dose.note!, style: JType.body),
                ],
                const SizedBox(height: JSpace.lg),
              ],
              Text(ex.summary, style: JType.body),
              const SizedBox(height: JSpace.sm),
              Text(ex.facts, style: JType.secondary),
            ],
          ),
        ),
        const Hairline(),
        _Section(
          label: 'How to',
          child: Column(
            children: [
              for (final (i, cue) in ex.cues.indexed)
                _NumberedLine(n: i + 1, text: cue),
            ],
          ),
        ),
        if (ex.mistakes.isNotEmpty)
          _Section(
            label: 'Avoid',
            child: Column(
              children: [for (final m in ex.mistakes) _DashLine(text: m)],
            ),
          ),
        if (easier != null || harder != null) ...[
          const SizedBox(height: JSpace.sm),
          if (easier != null) _SwapRow(label: 'Easier', exercise: easier!),
          if (harder != null) _SwapRow(label: 'Harder', exercise: harder!),
        ],
        const SizedBox(height: JSpace.xxl),
      ],
    );
  }
}

/// Reserved space for the line illustration (milestone 9).

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JSpace.gutter,
        JSpace.lg,
        JSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: JSpace.md),
          child,
        ],
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$n',
              style: JType.number.copyWith(color: JColors.green),
            ),
          ),
          Expanded(child: Text(text, style: JType.body)),
        ],
      ),
    );
  }
}

class _DashLine extends StatelessWidget {
  const _DashLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 28, child: Text('—', style: JType.body)),
          Expanded(child: Text(text, style: JType.body)),
        ],
      ),
    );
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({required this.label, required this.exercise});

  final String label;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Hairline(),
        StarkRow(
          leading: SizedBox(width: 64, child: SectionLabel(label)),
          title: exercise.name,
          // No dose: the swap's sets/reps come from the session that uses it.
          onTap: () => context.push(Routes.exercise(exercise.id)),
        ),
      ],
    );
  }
}
