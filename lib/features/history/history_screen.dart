import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_providers.dart';
import '../../content/labels.dart';
import '../../content/models.dart';
import '../../data/data_providers.dart';
import '../../data/database.dart';
import '../../engine/engine_providers.dart';
import '../../theme/tokens.dart';
import '../../util/dates.dart';
import '../../widgets/async_content.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_primitives.dart';
import 'pain_trend.dart';

/// History: the 4-week session grid, morning pain trend, phase milestones,
/// and every logged session.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _weeks = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return SafeArea(
      bottom: false,
      child: AsyncContent(
        value: ref.watch(sessionLogsProvider),
        builder: (sessions) {
          final days = {for (final s in sessions) dayKey(s.log.startedAt)};
          return ListView(
            children: [
              PageHeader(
                label: 'History',
                title: switch (sessions.length) {
                  0 => 'No sessions yet',
                  1 => '1 session',
                  final n => '$n sessions',
                },
              ),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                  child: Text(
                    'Finished sessions fill the grid.',
                    style: JType.secondary,
                  ),
                ),
              const SizedBox(height: JSpace.lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                child: SectionLabel('Last 4 weeks'),
              ),
              const SizedBox(height: JSpace.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: JSpace.gutter),
                child: _SessionGrid(weeks: _weeks, now: now, sessionDays: days),
              ),
              const SizedBox(height: JSpace.xl),
              _Section(
                label: 'Pain trend',
                child: _PainTrend(now: now, sessions: sessions),
              ),
              const _Milestones(),
              if (sessions.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
                  child: SectionLabel('Sessions'),
                ),
                const SizedBox(height: JSpace.sm),
              ],
              const Hairline(),
              for (final s in sessions) _SessionRow(s),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

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
          SectionLabel(label),
          const SizedBox(height: JSpace.md),
          child,
        ],
      ),
    );
  }
}

class _PainTrend extends ConsumerWidget {
  const _PainTrend({required this.now, required this.sessions});

  final DateTime now;
  final List<SessionSummary> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final limit =
        ref.watch(activeProgramProvider).value?.painRules.maxDuring ?? 3;
    final days = buildPainTrend(
      checkIns: checkIns,
      sessions: [for (final s in sessions) s.log],
      now: now,
    );
    final points = days.where(
      (d) => d.morningPain != null || d.sessionPain != null,
    );
    if (points.length < 2) {
      return const Text(
        'Your pain trend appears after a few morning check-ins.',
        style: JType.secondary,
      );
    }
    return PainTrendChart(days: days, limit: limit);
  }
}

/// Phase changes, newest first.
class _Milestones extends ConsumerWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(phaseEventsProvider).value ?? const [];
    final program = ref.watch(activeProgramProvider).value;
    if (events.isEmpty || program == null) return const SizedBox.shrink();
    Phase? phase(String id) =>
        program.phases.where((p) => p.id == id).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: JSpace.gutter),
          child: SectionLabel('Milestones'),
        ),
        const SizedBox(height: JSpace.sm),
        const Hairline(),
        for (final e in events.reversed)
          StarkRow(
            leading: Icon(
              switch (e.kind) {
                PhaseEventKind.dropBack => Icons.south,
                PhaseEventKind.graduate => Icons.check,
                _ => Icons.north,
              },
              size: 18,
              color: e.kind == PhaseEventKind.dropBack
                  ? JColors.grey
                  : JColors.green,
            ),
            title: switch (e.kind) {
              PhaseEventKind.entry =>
                'Started at Phase ${phase(e.phaseId)?.number ?? '?'}',
              PhaseEventKind.advance =>
                'Moved up to Phase ${phase(e.phaseId)?.number ?? '?'}',
              PhaseEventKind.dropBack =>
                'Dropped back to Phase ${phase(e.phaseId)?.number ?? '?'}',
              PhaseEventKind.graduate => 'Graduated to maintenance',
            },
            subtitle: [?phase(e.phaseId)?.name, shortDate(e.at)].join('  ·  '),
          ),
        const SizedBox(height: JSpace.xl),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow(this.s);

  final SessionSummary s;

  @override
  Widget build(BuildContext context) {
    final log = s.log;
    final minutes = log.endedAt.difference(log.startedAt).inMinutes;
    return StarkRow(
      title: '${log.kind.label}  ·  ${shortDate(log.startedAt)}',
      subtitle:
          '${s.exercisesDone}/${s.exercisesPlanned} exercises  ·  '
          '${minutes < 1 ? '< 1' : minutes} min  ·  '
          'pain ${log.painBefore} → ${log.painAfter}',
    );
  }
}

/// 7-column grid of the last [weeks] weeks, Monday first, this week last.
/// Green = a session was logged that day. Today has a white outline.
class _SessionGrid extends StatelessWidget {
  const _SessionGrid({
    required this.weeks,
    required this.now,
    required this.sessionDays,
  });

  final int weeks;
  final DateTime now;
  final Set<String> sessionDays;

  @override
  Widget build(BuildContext context) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final first = startOfWeek(now).subtract(Duration(days: 7 * (weeks - 1)));
    final today = dayKey(now);
    return Column(
      children: [
        Row(
          children: [
            for (final d in names)
              Expanded(
                child: Center(child: Text(d, style: JType.label)),
              ),
          ],
        ),
        const SizedBox(height: JSpace.sm),
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: JSpace.sm),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _cell(
                          // Calendar arithmetic, so DST shifts don't skip days.
                          DateTime(
                            first.year,
                            first.month,
                            first.day + w * 7 + d,
                          ),
                          today,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(DateTime day, String today) {
    final key = dayKey(day);
    final done = sessionDays.contains(key);
    final isToday = key == today;
    final future = day.isAfter(now);
    return Semantics(
      container: true,
      label: '${shortDate(day)}${done ? ', session done' : ''}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: done ? JColors.green : Colors.transparent,
          border: Border.all(
            color: isToday
                ? JColors.white
                : future
                ? JColors.line.withValues(alpha: 0.08)
                : JColors.line,
          ),
        ),
      ),
    );
  }
}
