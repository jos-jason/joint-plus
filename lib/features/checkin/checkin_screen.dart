import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/data_providers.dart';
import '../../data/database.dart';
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

/// Morning check-in: pain, swelling and stiffness in three taps. How the knee
/// is the morning after a session is what decides whether to progress.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  int? _pain;
  Change? _swelling;
  Change? _stiffness;
  bool _prefilled = false;
  bool _saving = false;

  bool get _complete =>
      _pain != null && _swelling != null && _stiffness != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(databaseProvider)
          .saveCheckIn(
            at: ref.read(clockProvider)(),
            pain: _pain!,
            swelling: _swelling!,
            stiffness: _stiffness!,
          );
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
    // Editing today's check-in: start from what was saved.
    final existing = ref.watch(todayCheckInProvider).value;
    if (!_prefilled && existing != null) {
      _prefilled = true;
      _pain = existing.pain;
      _swelling = existing.swelling;
      _stiffness = existing.stiffness;
    }

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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                    child: Text(
                      'Before you get going. Compare with yesterday morning.',
                      style: JType.secondary,
                    ),
                  ),
                  const SizedBox(height: JSpace.xl),
                  _Question(
                    label: 'Knee pain right now',
                    child: PainScale(
                      value: _pain,
                      onChanged: (v) => setState(() => _pain = v),
                    ),
                  ),
                  _Question(
                    label: 'Swelling',
                    child: ChoiceCells(
                      semanticPrefix: 'Swelling',
                      labels: [for (final c in Change.values) c.label],
                      value: _swelling?.index,
                      onChanged: (i) =>
                          setState(() => _swelling = Change.values[i]),
                    ),
                  ),
                  _Question(
                    label: 'Stiffness',
                    child: ChoiceCells(
                      semanticPrefix: 'Stiffness',
                      labels: [for (final c in Change.values) c.label],
                      value: _stiffness?.index,
                      onChanged: (i) =>
                          setState(() => _stiffness = Change.values[i]),
                    ),
                  ),
                  if (_swelling == Change.more || _stiffness == Change.more)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                      child: Text(
                        'Worse than yesterday: repeat your last dose today '
                        "instead of progressing. Sudden large swelling, or a "
                        "knee that locks or gives way, is a reason to call "
                        'your clinician.',
                        style: JType.body,
                      ),
                    ),
                ],
              ),
            ),
            const Hairline(),
            Padding(
              padding: const EdgeInsets.all(JSpace.gutter),
              child: StarkButton(
                label: 'Save',
                onPressed: _complete && !_saving ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.label, required this.child});

  final String label;
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
          const SizedBox(height: JSpace.md),
          child,
        ],
      ),
    );
  }
}
