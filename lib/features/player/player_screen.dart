import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/router.dart';
import '../../content/content_providers.dart';
import '../../engine/engine_providers.dart';
import '../../content/models.dart';
import '../../data/data_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/async_content.dart';
import '../../widgets/exercise_illustration.dart';
import '../../widgets/pain_scale.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_dialog.dart';
import '../../widgets/stark_primitives.dart';
import '../../widgets/timer_ring.dart';
import 'session_flow.dart';

/// Guided session: one exercise at a time, full screen. Pain check before,
/// sets with hold and rest timers, pain check after, then a summary.
/// Pops with a [SessionResult] when finished.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.kind});

  final SessionKind kind;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  SessionFlow? _flow;
  late PainRules _painRules;
  late String _programId;
  late String _phaseId;

  /// Set once the finished session has been written (or failed to be).
  bool _saveStarted = false;
  bool _saveFailed = false;

  /// Seconds on the current step's clock (hold, timed activity or rest).
  int _elapsed = 0;
  Timer? _timer;

  /// Runs briefly after each step change. The main button sits in the same
  /// place on every step, so a double tap would otherwise skip a set.
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // Holds can outlast the auto-lock. Plugins aren't present in widget tests.
    WakelockPlus.enable().catchError((Object _) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settle?.cancel();
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  SessionFlow get flow => _flow!;
  bool get _running => _timer != null;

  /// Ignores taps that land while a new step is settling in.
  VoidCallback? _guard(VoidCallback? action) => action == null
      ? null
      : () {
          if (!(_settle?.isActive ?? false)) action();
        };

  // ------------------------------------------------------------------ clock

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {});
  }

  void _tick() {
    setState(() => _elapsed++);
    switch (flow.step) {
      case RestStep(:final seconds) when _elapsed >= seconds:
        HapticFeedback.heavyImpact();
        _go(flow.next);
      case WorkStep(:final dose) when dose.isTimed:
        if (_elapsed == dose.seconds) HapticFeedback.mediumImpact();
        if (_elapsed >= (dose.secondsMax ?? dose.seconds!)) {
          HapticFeedback.heavyImpact();
          _go(flow.next);
        }
      default:
        break;
    }
  }

  /// Applies a change to the flow and resets the clock for the new step.
  void _go(VoidCallback change) {
    _timer?.cancel();
    _timer = null;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 400), () {});
    setState(() {
      change();
      _elapsed = 0;
    });
    if (flow.step is RestStep) _start();
    if (flow.finished && !_saveStarted) _save();
  }

  /// Logs the session as soon as the summary shows, so closing the app on
  /// the summary screen doesn't lose it.
  Future<void> _save() async {
    _saveStarted = true;
    try {
      await ref
          .read(databaseProvider)
          .saveSession(
            programId: _programId,
            phaseId: _phaseId,
            result: flow.result(),
          );
    } catch (e, st) {
      debugPrint('Saving session failed: $e\n$st');
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  // ------------------------------------------------------------------- exit

  Future<void> _close() async {
    if (!flow.started || flow.finished) {
      _leave();
      return;
    }
    final end = await showStarkConfirm(
      context,
      title: 'End session?',
      body:
          "This session won't be counted. If pain made you stop, start "
          'the next one with the easier version of what hurt.',
      confirm: 'End session',
      cancel: 'Keep going',
      destructive: true,
    );
    if (end) _leave();
  }

  void _leave() {
    if (!mounted) return;
    context.pop(flow.finished ? flow.result() : null);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final phaseIndex = ref.watch(currentPhaseIndexProvider);
    return AsyncContent(
      value: ref.watch(activeProgramProvider),
      builder: (program) {
        final session = program.phases[phaseIndex].sessions[widget.kind];
        if (session == null) {
          return const Scaffold(
            body: ContentErrorView(error: 'No such session in this phase'),
          );
        }
        _painRules = program.painRules;
        _programId = program.id;
        _phaseId = program.phases[phaseIndex].id;
        _flow ??= SessionFlow(
          session: session,
          exercises: ref.read(contentProvider).requireValue.exercises,
          clock: ref.read(clockProvider),
        );
        return PopScope(
          canPop: !flow.started,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    counter: _counter(),
                    onClose: _close,
                    onSkip: flow.step is WorkStep
                        ? () => _go(flow.skipExercise)
                        : null,
                  ),
                  _ProgressLine(value: flow.progress),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _counter() => switch (flow.step) {
    ItemStep(:final item) =>
      item < flow.requiredCount
          ? '${item + 1} / ${flow.requiredCount}'
          : 'EXTRA',
    _ => null,
  };

  Widget _body() => switch (flow.step) {
    PainStep(before: true) => _PainView(
      label: 'Before you start',
      question: 'How does the knee feel right now?',
      value: flow.painBefore,
      onChanged: (v) => setState(() => flow.painBefore = v),
      action: 'Start',
      onAction: _guard(flow.painBefore == null ? null : () => _go(flow.next)),
    ),
    PainStep(before: false) => _PainView(
      label: 'Session done',
      question: 'What was the worst pain during the session?',
      value: flow.painAfter,
      onChanged: (v) => setState(() => flow.painAfter = v),
      warning: _overLimit(flow.painAfter) ? _overLimitAdvice : null,
      action: 'Finish',
      onAction: _guard(flow.painAfter == null ? null : () => _go(flow.next)),
    ),
    final WorkStep s => _WorkView(
      step: s,
      elapsed: _elapsed,
      running: _running,
      maxPain: _painRules.maxDuring,
      onStart: _guard(_start)!,
      onDone: _guard(() => _go(flow.next))!,
      onInfo: () => context.push(Routes.exercise(s.exercise.id)),
    ),
    final RestStep s => _RestView(
      seconds: s.seconds,
      elapsed: _elapsed,
      upNext: flow.upNext,
      onSkip: _guard(() => _go(flow.next))!,
    ),
    SummaryStep() => _SummaryView(
      saveFailed: _saveFailed,
      flow: flow,
      result: flow.result(),
      warning: _overLimit(flow.painAfter) ? _overLimitAdvice : null,
      onDone: _guard(_leave)!,
    ),
  };

  bool _overLimit(int? pain) => pain != null && pain > _painRules.maxDuring;

  String get _overLimitAdvice =>
      'Above ${_painRules.maxDuring}/10. Next session, repeat this dose and '
      'ease the range or load on whatever hurt. If it keeps happening, '
      'drop back a phase.';
}

// ------------------------------------------------------------------- chrome

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.counter,
    required this.onClose,
    required this.onSkip,
  });

  final String? counter;
  final VoidCallback onClose;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: JSpace.sm,
        vertical: JSpace.sm,
      ),
      child: SizedBox(
        height: JSize.tapTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StarkIconButton(
                icon: Icons.close,
                semanticLabel: 'End session',
                onPressed: onClose,
              ),
            ),
            if (counter != null)
              Text(counter!, style: JType.number.copyWith(fontSize: 14)),
            if (onSkip != null)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSkip,
                  child: const Padding(
                    padding: EdgeInsets.all(JSpace.md),
                    child: SectionLabel('Skip'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hairline track with the done part in green.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          const Align(alignment: Alignment.center, child: Hairline()),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: JColors.green),
          ),
        ],
      ),
    );
  }
}

/// Scrollable content with one action pinned to the bottom.
class _Frame extends StatelessWidget {
  const _Frame({required this.children, required this.button});

  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                JSpace.gutter,
                JSpace.lg,
                JSpace.gutter,
                JSpace.lg,
              ),
              child: ConstrainedBox(
                // Lets Spacers centre the main figure on tall screens.
                constraints: BoxConstraints(
                  minHeight: box.maxHeight - JSpace.lg * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.all(JSpace.gutter), child: button),
      ],
    );
  }
}

// -------------------------------------------------------------------- views

class _PainView extends StatelessWidget {
  const _PainView({
    required this.label,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.action,
    required this.onAction,
    this.warning,
  });

  final String label;
  final String question;
  final int? value;
  final ValueChanged<int> onChanged;
  final String action;
  final VoidCallback? onAction;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      button: StarkButton(label: action, onPressed: onAction),
      children: [
        SectionLabel(label),
        const SizedBox(height: JSpace.sm),
        Text(question, style: JType.title),
        const Spacer(),
        Center(
          child: Text(value == null ? '–' : '$value', style: JType.display),
        ),
        const SizedBox(height: JSpace.xs),
        const Center(child: SectionLabel('out of 10')),
        const SizedBox(height: JSpace.xl),
        PainScale(value: value, onChanged: onChanged),
        const Spacer(),
        if (warning != null) ...[
          const SizedBox(height: JSpace.lg),
          Text(warning!, style: JType.body),
        ],
      ],
    );
  }
}

class _WorkView extends StatelessWidget {
  const _WorkView({
    required this.step,
    required this.elapsed,
    required this.running,
    required this.maxPain,
    required this.onStart,
    required this.onDone,
    required this.onInfo,
  });

  final WorkStep step;
  final int elapsed;
  final bool running;
  final int maxPain;
  final VoidCallback onStart;
  final VoidCallback onDone;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final d = step.dose;
    final where = [
      if (d.optional) 'Optional',
      d.sets > 1 ? 'Set ${step.set} of ${d.sets}' : null,
      step.side?.label,
    ].nonNulls.join('  ·  ');

    return _Frame(
      button: d.isTimed && !running
          ? StarkButton(label: 'Start', onPressed: onStart)
          : StarkButton(label: 'Done', onPressed: onDone),
      children: [
        if (where.isNotEmpty) SectionLabel(where, color: JColors.green),
        const SizedBox(height: JSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(step.exercise.name, style: JType.title)),
            Transform.translate(
              offset: const Offset(12, -10),
              child: StarkIconButton(
                icon: Icons.info_outline,
                semanticLabel: 'How to do ${step.exercise.name}',
                onPressed: onInfo,
              ),
            ),
          ],
        ),
        const SizedBox(height: JSpace.sm),
        Center(
          child: SizedBox(
            height: 132,
            child: ExerciseIllustration(step.exercise),
          ),
        ),
        const Spacer(),
        const SizedBox(height: JSpace.md),
        Center(child: d.isTimed ? _hold(d) : _reps(d)),
        const SizedBox(height: JSpace.lg),
        const Spacer(),
        for (final (i, cue) in step.exercise.cues.take(3).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: JSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: JType.number.copyWith(color: JColors.green),
                  ),
                ),
                Expanded(child: Text(cue, style: JType.body)),
              ],
            ),
          ),
        const SizedBox(height: JSpace.sm),
        Text(
          [
            ?d.note,
            d.isTimed
                ? 'Breathe steadily. Pain up to $maxPain/10 is fine.'
                : 'The last 2–3 reps should feel hard. '
                      'Pain up to $maxPain/10 is fine.',
          ].join('\n'),
          style: JType.secondary,
        ),
      ],
    );
  }

  Widget _reps(Dose d) {
    final range = d.repsMax == null || d.repsMax == d.reps
        ? '${d.reps}'
        : '${d.reps}–${d.repsMax}';
    return Column(
      children: [
        Text(range, style: JType.display.copyWith(fontSize: 84)),
        const SizedBox(height: JSpace.sm),
        const SectionLabel('reps'),
      ],
    );
  }

  Widget _hold(Dose d) {
    final target = d.seconds!;
    final max = d.secondsMax ?? target;
    final reached = elapsed >= target;
    final minutes = max >= 120;
    final String hint;
    if (!running && elapsed == 0) {
      hint = 'Target ${_amount(target, d.secondsMax, minutes)}';
    } else if (reached && max > target) {
      hint = 'Target reached · up to ${_amount(max, null, minutes)}';
    } else {
      hint = reached
          ? 'Target reached'
          : 'Target ${_amount(target, d.secondsMax, minutes)}';
    }
    return TimerRing(
      size: 200,
      progress: elapsed / target,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _clock(elapsed, minutes: minutes),
            style: JType.display.copyWith(
              color: reached ? JColors.green : JColors.white,
            ),
          ),
          const SizedBox(height: JSpace.sm),
          SectionLabel(hint),
        ],
      ),
    );
  }
}

class _RestView extends StatelessWidget {
  const _RestView({
    required this.seconds,
    required this.elapsed,
    required this.upNext,
    required this.onSkip,
  });

  final int seconds;
  final int elapsed;
  final PlayerStep? upNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final left = (seconds - elapsed).clamp(0, seconds);
    final next = upNext;
    return _Frame(
      button: StarkButton(label: 'Skip rest', onPressed: onSkip),
      children: [
        const SectionLabel('Rest'),
        const SizedBox(height: JSpace.sm),
        const Text('Breathe. Shake it out.', style: JType.title),
        const Spacer(),
        const SizedBox(height: JSpace.lg),
        Center(
          child: TimerRing(
            size: 240,
            progress: left / seconds,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _clock(left, minutes: seconds >= 120),
                  style: JType.display,
                ),
                const SizedBox(height: JSpace.sm),
                const SectionLabel('seconds left'),
              ],
            ),
          ),
        ),
        const SizedBox(height: JSpace.lg),
        const Spacer(),
        if (next is WorkStep) ...[
          const SectionLabel('Up next'),
          const SizedBox(height: JSpace.sm),
          Text(next.exercise.name, style: JType.heading),
          Text(
            [
              'Set ${next.set} of ${next.dose.sets}',
              ?next.side?.label,
            ].join('  ·  '),
            style: JType.secondary,
          ),
        ],
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.saveFailed,
    required this.flow,
    required this.result,
    required this.warning,
    required this.onDone,
  });

  final SessionFlow flow;
  final SessionResult result;
  final String? warning;
  final VoidCallback onDone;
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final required = result.items.where((i) => !i.optional);
    final done = required.where((i) => i.complete).length;
    final sets = required.fold(0, (n, i) => n + i.setsDone);
    final planned = required.fold(0, (n, i) => n + i.setsPlanned);
    final minutes = result.endedAt.difference(result.startedAt).inMinutes;
    final extras = result.items.where((i) => i.optional && i.setsDone > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
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
                    SectionLabel(flow.session.name),
                    const SizedBox(height: JSpace.sm),
                    const Text('Done.', style: JType.title),
                  ],
                ),
              ),
              const Hairline(),
              _Stat('Exercises', '$done / ${required.length}'),
              _Stat('Sets', '$sets / $planned'),
              if (extras.isNotEmpty) _Stat('Extras', '${extras.length}'),
              _Stat('Time', minutes < 1 ? '< 1 min' : '$minutes min'),
              _Stat('Pain', '${result.painBefore} → ${result.painAfter}'),
              Padding(
                padding: const EdgeInsets.all(JSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (saveFailed) ...[
                      Text(
                        "Couldn't save this session to your history.",
                        style: JType.body.copyWith(color: JColors.white),
                      ),
                      const SizedBox(height: JSpace.md),
                    ],
                    if (warning != null) ...[
                      Text(warning!, style: JType.body),
                      const SizedBox(height: JSpace.md),
                    ],
                    const Text(
                      'Tomorrow morning, check the knee: pain and stiffness '
                      'should be no worse than today. If they are, repeat '
                      'this dose next time instead of progressing.',
                      style: JType.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(JSpace.gutter),
          child: StarkButton(label: 'Done', onPressed: onDone),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => StarkRow(
    title: label,
    trailing: Text(value, style: JType.number),
  );
}

// ------------------------------------------------------------------ helpers

/// "45" for short clocks, "12:05" when [minutes].
String _clock(int s, {required bool minutes}) =>
    minutes ? '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}' : '$s';

/// "30–45 s" or "10–20 min".
String _amount(int lo, int? hi, bool minutes) {
  String r(int a, int? b) => b == null || b == a ? '$a' : '$a–$b';
  return minutes
      ? '${r(lo ~/ 60, hi == null ? null : hi ~/ 60)} min'
      : '${r(lo, hi)} s';
}
