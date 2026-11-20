import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_providers.dart';
import '../../content/models.dart';
import '../../data/data_providers.dart';
import '../../data/database.dart';
import '../../data/knees.dart';
import '../../theme/tokens.dart';
import '../../widgets/choice_cells.dart';
import '../../widgets/page_header.dart';
import '../../widgets/pain_scale.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_primitives.dart';

extension ChangeLabel on Change {
  String get label => switch (this) {
    Change.less => 'Less',
    Change.same => 'Same',
    Change.more => 'More',
  };
}

/// One knee's answers.
class _Answers {
  int? pain;
  Change? swelling;
  Change? stiffness;
  int? loadPain;

  bool get complete => pain != null && swelling != null && stiffness != null;
}

/// Morning check-in: pain, swelling and stiffness, plus the program's load
/// test if it has one. With both knees in rehab, each knee is asked on its
/// own. How the knees are the morning after a session decides whether to
/// progress.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _answers = <String, _Answers>{};
  bool _prefilled = false;
  bool _saving = false;

  _Answers _for(String key) => _answers.putIfAbsent(key, _Answers.new);

  Future<void> _save(List<String> keys) async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final now = ref.read(clockProvider)();
    try {
      for (final k in keys) {
        final a = _for(k);
        await db.saveCheckIn(
          at: now,
          knee: k,
          pain: a.pain!,
          swelling: a.swelling!,
          stiffness: a.stiffness!,
          loadPain: a.loadPain,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('Saving check-in failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the check-in. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(kneeSetupProvider).value;
    final keys = setup?.checkInKeys ?? const [singleKneeKey];
    final loadTest = ref.watch(activeProgramProvider).value?.painRules.loadTest;

    // Editing today's check-in: start from what was saved.
    final existing = ref.watch(todayCheckInProvider).value ?? const [];
    if (!_prefilled && existing.isNotEmpty) {
      _prefilled = true;
      for (final c in existing) {
        _for(c.knee)
          ..pain = c.pain
          ..swelling = c.swelling
          ..stiffness = c.stiffness
          ..loadPain = c.loadPain;
      }
    }

    final complete = keys.every((k) => _for(k).complete);
    final worse = keys.any(
      (k) =>
          _for(k).swelling == Change.more || _for(k).stiffness == Change.more,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  PageHeader(
                    title: 'Morning check-in',
                    onBack: () => context.pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: JSpace.gutter,
                    ),
                    child: Text(
                      keys.length > 1
                          ? 'Before you get going. Each knee compared with '
                                'its own yesterday morning.'
                          : 'Before you get going. Compare with yesterday '
                                'morning.',
                      style: JType.secondary,
                    ),
                  ),
                  const SizedBox(height: JSpace.xl),
                  for (final k in keys)
                    _KneeQuestions(
                      title: keys.length > 1 ? checkInKeyLabel(k) : null,
                      answers: _for(k),
                      loadTest: loadTest,
                      onChanged: () => setState(() {}),
                    ),
                  if (worse)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                      child: Text(
                        'Worse than yesterday: repeat your last dose today '
                        'instead of progressing. Sudden large swelling, or a '
                        'knee that locks or gives way, is a reason to call '
                        'your clinician.',
                        style: JType.body,
                      ),
                    ),
                  const SizedBox(height: JSpace.lg),
                ],
              ),
            ),
            const Hairline(),
            Padding(
              padding: const EdgeInsets.all(JSpace.gutter),
              child: StarkButton(
                label: 'Save',
                onPressed: complete && !_saving ? () => _save(keys) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The questions for one knee. [title] is shown when there are two knees.
class _KneeQuestions extends StatelessWidget {
  const _KneeQuestions({
    required this.title,
    required this.answers,
    required this.loadTest,
    required this.onChanged,
  });

  final String? title;
  final _Answers answers;
  final LoadTest? loadTest;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final a = answers;
    // Screen readers hear which knee each choice is for.
    final who = title == null ? '' : '$title ';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          const Hairline(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              JSpace.gutter,
              JSpace.lg,
              JSpace.gutter,
              JSpace.lg,
            ),
            child: Text(title!, style: JType.heading),
          ),
        ],
        _Question(
          label: 'Knee pain right now',
          child: PainScale(
            semanticPrefix: title ?? '',
            value: a.pain,
            onChanged: (v) {
              a.pain = v;
              onChanged();
            },
          ),
        ),
        _Question(
          label: 'Swelling',
          child: ChoiceCells(
            semanticPrefix: '${who}Swelling',
            labels: [for (final c in Change.values) c.label],
            value: a.swelling?.index,
            onChanged: (i) {
              a.swelling = Change.values[i];
              onChanged();
            },
          ),
        ),
        _Question(
          label: 'Stiffness',
          child: ChoiceCells(
            semanticPrefix: '${who}Stiffness',
            labels: [for (final c in Change.values) c.label],
            value: a.stiffness?.index,
            onChanged: (i) {
              a.stiffness = Change.values[i];
              onChanged();
            },
          ),
        ),
        if (loadTest case final t?)
          _Question(
            label: '${t.name} · optional',
            help: t.instructions,
            child: PainScale(
              semanticPrefix: '$who${t.name}'.trim(),
              value: a.loadPain,
              onChanged: (v) {
                a.loadPain = a.loadPain == v ? null : v;
                onChanged();
              },
            ),
          ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.label, required this.child, this.help});

  final String label;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JSpace.gutter,
        0,
        JSpace.gutter,
        JSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(label, color: JColors.white),
          if (help != null) ...[
            const SizedBox(height: JSpace.sm),
            Text(help!, style: JType.secondary),
          ],
          const SizedBox(height: JSpace.md),
          child,
        ],
      ),
    );
  }
}
