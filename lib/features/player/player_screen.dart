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

  /// Seconds counted on the current step: time into a set, or into a break.
  int _elapsed = 0;

  /// "Get ready" seconds left before a set's clock starts.
  int _lead = 0;

  /// Seconds added to the current break with "+15 s".
  int _extra = 0;

  bool _paused = false;
  Timer? _timer;

  /// Runs briefly after each step change. The main button sits in the same
  /// place on every step, so a double tap would otherwise skip a set.
  Timer? _settle;

  static const _leadIn = 3;

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

  /// Ignores taps that land while a new step is settling in.
  VoidCallback? _guard(VoidCallback? action) => action == null
      ? null
      : () {
          if (!(_settle?.isActive ?? false)) action();
        };

  // ------------------------------------------------------------------ clock

  bool get _timed => flow.step is WorkStep || flow.step is BreakStep;

  void _run() {
    _timer?.cancel();
    _timer = _timed && !_paused
        ? Timer.periodic(const Duration(seconds: 1), (_) => _tick())
        : null;
  }

  void _togglePause() {
    if (!_timed) return;
    setState(() => _paused = !_paused);
    HapticFeedback.selectionClick();
    _run();
  }

  void _pause() {
    if (_paused || !_timed) return;
    setState(() => _paused = true);
    _run();
  }

  void _tick() {
    final step = flow.step;
    if (step is WorkStep && _lead > 0) {
      setState(() => _lead--);
      _lead > 0 ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _elapsed++);
    switch (step) {
      case BreakStep(:final seconds):
        final left = seconds + _extra - _elapsed;
        if (left <= 0) {
          HapticFeedback.heavyImpact();
          _go(flow.next);
        } else if (left <= 3) {
          HapticFeedback.lightImpact();
        }
      case WorkStep(:final dose) when dose.isTimed:
        if (_elapsed == dose.seconds) HapticFeedback.mediumImpact();
        if (_elapsed >= (dose.secondsMax ?? dose.seconds!)) {
          HapticFeedback.heavyImpact();
          _go(flow.next);
        }
      case WorkStep(:final dose, :final exercise):
        if (_elapsed % exercise.repSec != 0) return;
        final reps = _elapsed ~/ exercise.repSec;
        if (reps >= (dose.repsMax ?? dose.reps!)) {
          HapticFeedback.heavyImpact();
          _go(flow.next);
        } else if (reps == dose.reps) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      default:
        break;
    }
  }

  /// Applies a change to the flow and starts the new step's clock: sets get
  /// a short "get ready" count, breaks count down straight away.
  void _go(VoidCallback change) {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 400), () {});
    setState(() {
      change();
      _elapsed = 0;
      _extra = 0;
      _paused = false;
      _lead = flow.step is WorkStep ? _leadIn : 0;
    });
    _run();
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
    final wasPaused = _paused;
    _pause();
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
    if (end) {
      _leave();
    } else if (!wasPaused && mounted) {
      _togglePause();
    }
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
        // The session's sides depend on the knee setup: wait for it once.
        final knees = ref.watch(kneeSetupProvider);
        if (_flow == null && !knees.hasValue) {
          return const Scaffold(body: SizedBox.shrink());
        }
        _flow ??= SessionFlow(
          session: session,
          exercises: ref.read(contentProvider).requireValue.exercises,
          clock: ref.read(clockProvider),
          knees: knees.value,
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
                    onSkip: flow.step is WorkStep || flow.step is UpNextStep
                        ? _guard(() => _go(flow.skipExercise))
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
      lead: _lead,
      paused: _paused,
      maxPain: _painRules.maxDuring,
      onTogglePause: _togglePause,
      onDone: _guard(() => _go(flow.next))!,
      onInfo: () {
        _pause();
        context.push(Routes.exercise(s.exercise.id));
      },
    ),
    final BreakStep s => _BreakView(
      step: s,
      total: s.seconds + _extra,
      elapsed: _elapsed,
      paused: _paused,
      upNext: flow.upNext,
      counter: _counter(),
      onTogglePause: _togglePause,
      onMore: () => setState(() => _extra += 15),
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

/// The timer ring with a tap target to pause and resume.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.paused,
    required this.onTap,
    required this.child,
    this.size = 200,
  });

  final double progress;
  final bool paused;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: paused ? 'Resume timer' : 'Pause timer',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: paused ? 0.45 : 1,
          child: TimerRing(size: size, progress: progress, child: child),
        ),
      ),
    );
  }
}

class _WorkView extends StatelessWidget {
  const _WorkView({
    required this.step,
    required this.elapsed,
    required this.lead,
    required this.paused,
    required this.maxPain,
    required this.onTogglePause,
    required this.onDone,
    required this.onInfo,
  });

  final WorkStep step;
  final int elapsed;
  final int lead;
  final bool paused;
  final int maxPain;
  final VoidCallback onTogglePause;
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
      button: StarkButton(label: 'Done', onPressed: onDone),
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
        Center(
          child: lead > 0
              ? _ready()
              : d.isTimed
              ? _hold(d)
              : _reps(d),
        ),
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

  Widget _status(String text) =>
      SectionLabel(paused ? 'Paused · tap to resume' : text);

  Widget _ready() => _Ring(
    size: 176,
    progress: 0,
    paused: paused,
    onTap: onTogglePause,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$lead', style: JType.display.copyWith(color: JColors.green)),
        const SizedBox(height: JSpace.sm),
        _status('Get ready'),
      ],
    ),
  );

  Widget _reps(Dose d) {
    final pace = step.exercise.repSec;
    final target = d.reps!;
    final max = d.repsMax ?? target;
    final done = elapsed ~/ pace;
    final reached = done >= target;
    final range = max == target ? '$target' : '$target–$max';
    return _Ring(
      size: 176,
      progress: elapsed / (target * pace),
      paused: paused,
      onTap: onTogglePause,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$done',
            style: JType.display.copyWith(
              color: reached ? JColors.green : JColors.white,
            ),
          ),
          const SizedBox(height: JSpace.sm),
          _status(
            reached && max > target ? 'Up to $max reps' : 'of $range reps',
          ),
          const SizedBox(height: JSpace.xs),
          Text(
            '1 rep every $pace s',
            style: JType.secondary.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _hold(Dose d) {
    final target = d.seconds!;
    final max = d.secondsMax ?? target;
    final reached = elapsed >= target;
    final minutes = max >= 120;
    final hint = reached && max > target
        ? 'Target reached · up to ${_amount(max, null, minutes)}'
        : reached
        ? 'Target reached'
        : 'Target ${_amount(target, d.secondsMax, minutes)}';
    return _Ring(
      size: 176,
      progress: elapsed / target,
      paused: paused,
      onTap: onTogglePause,
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
          _status(hint),
        ],
      ),
    );
  }
}

/// Rest between sets, switching legs, or "up next" before an exercise. All
/// count down and move on by themselves.
class _BreakView extends StatelessWidget {
  const _BreakView({
    required this.step,
    required this.total,
    required this.elapsed,
    required this.paused,
    required this.upNext,
    required this.counter,
    required this.onTogglePause,
    required this.onMore,
    required this.onSkip,
  });

  final BreakStep step;
  final int total;
  final int elapsed;
  final bool paused;
  final PlayerStep? upNext;
  final String? counter;
  final VoidCallback onTogglePause;
  final VoidCallback onMore;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final left = (total - elapsed).clamp(0, total);
    final (label, title, action) = switch (step) {
      RestStep() => ('Rest', 'Breathe. Shake it out.', 'Skip rest'),
      SwitchStep() => ('Switch legs', 'Other leg next', 'Start now'),
      UpNextStep() => (
        counter == 'EXTRA' ? 'Up next · extra' : 'Up next · ${counter ?? ''}',
        (step as UpNextStep).exercise.name,
        'Start now',
      ),
    };
    final ring = _Ring(
      size: step is UpNextStep ? 150 : 220,
      progress: left / total,
      paused: paused,
      onTap: onTogglePause,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _clock(left, minutes: total >= 120),
            style: step is UpNextStep
                ? JType.display.copyWith(fontSize: 48)
                : JType.display,
          ),
          const SizedBox(height: JSpace.xs),
          SectionLabel(paused ? 'Paused' : 'seconds'),
        ],
      ),
    );
    final more = Center(
      child: Semantics(
        button: true,
        label: 'Add 15 seconds',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.all(JSpace.md),
            child: SectionLabel('+15 s', color: JColors.white),
          ),
        ),
      ),
    );

    return _Frame(
      button: StarkButton(label: action, onPressed: onSkip),
      children: [
        SectionLabel(label, color: JColors.green),
        const SizedBox(height: JSpace.sm),
        Text(title, style: JType.title),
        if (step case UpNextStep(:final exercise, :final dose)) ...[
          const SizedBox(height: JSpace.xs),
          Text(
            dose.describe(exercise),
            style: JType.heading.copyWith(color: JColors.green),
          ),
          const SizedBox(height: JSpace.md),
          Center(
            child: SizedBox(height: 168, child: ExerciseIllustration(exercise)),
          ),
          const Spacer(),
          Center(child: ring),
          more,
          const Spacer(),
          Text(exercise.cues.first, style: JType.body),
          if (dose.note != null) ...[
            const SizedBox(height: JSpace.sm),
            Text(dose.note!, style: JType.secondary),
          ],
        ] else ...[
          const Spacer(),
          Center(child: ring),
          more,
          const Spacer(),
          if (upNext case final WorkStep next) ...[
            const SectionLabel('Up next'),
            const SizedBox(height: JSpace.sm),
            Text(next.exercise.name, style: JType.heading),
            Text(
              [
                if (next.dose.sets > 1) 'Set ${next.set} of ${next.dose.sets}',
                ?next.side?.label,
              ].join('  ·  '),
              style: JType.secondary,
            ),
          ],
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
