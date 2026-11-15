import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/tokens.dart';

/// One calendar day of the trend.
class TrendDay {
  const TrendDay({required this.date, this.morningPain, this.sessionPain});

  final DateTime date;

  /// From that morning's check-in.
  final int? morningPain;

  /// Worst pain in that day's sessions.
  final int? sessionPain;
}

/// The last [days] calendar days ending today, oldest first.
List<TrendDay> buildPainTrend({
  required List<CheckIn> checkIns,
  required List<SessionLog> sessions,
  required DateTime now,
  int days = 28,
}) {
  final morning = {for (final c in checkIns) c.day: c.pain};
  final worst = <String, int>{};
  for (final s in sessions) {
    final k = dayKey(s.startedAt);
    final prev = worst[k];
    if (prev == null || s.painAfter > prev) worst[k] = s.painAfter;
  }
  return [
    for (var i = days - 1; i >= 0; i--)
      () {
        // Calendar arithmetic, so DST changes don't skip or repeat a day.
        final d = DateTime(now.year, now.month, now.day - i);
        final k = dayKey(d);
        return TrendDay(
          date: d,
          morningPain: morning[k],
          sessionPain: worst[k],
        );
      }(),
  ];
}

/// Morning pain as a white line, session days as green dots at their worst
/// pain, and the pain limit as a dashed grey line. 0 at the bottom, 10 on top.
class PainTrendChart extends StatelessWidget {
  const PainTrendChart({super.key, required this.days, required this.limit});

  final List<TrendDay> days;

  /// Highest acceptable pain during exercise.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final mornings = [
      for (final d in days)
        if (d.morningPain != null) d.morningPain!,
    ];
    final sessions = days.where((d) => d.sessionPain != null).length;
    final summary = mornings.isEmpty
        ? 'No morning check-ins yet'
        : 'Morning pain, last ${days.length} days: latest ${mornings.last}, '
              'highest ${mornings.reduce((a, b) => a > b ? a : b)} out of 10';
    return Semantics(
      label: '$summary. $sessions session days.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _TrendPainter(days: days, limit: limit),
            ),
          ),
          const SizedBox(height: JSpace.md),
          Wrap(
            spacing: JSpace.lg,
            runSpacing: JSpace.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 2, color: JColors.white),
                  const SizedBox(width: JSpace.sm),
                  const Text('Morning pain', style: JType.secondary),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: JColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: JSpace.sm),
                  const Text('Session, worst pain', style: JType.secondary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.days, required this.limit});

  final List<TrendDay> days;
  final int limit;

  static const _axisWidth = 24.0;
  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: JColors.grey,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_axisWidth, 6, size.width, size.height - 6);
    double x(int i) =>
        plot.left + (days.length == 1 ? 0 : i * plot.width / (days.length - 1));
    double y(num pain) => plot.bottom - pain / 10 * plot.height;

    // Axis labels and baseline.
    for (final v in [0, limit, 10]) {
      final tp = TextPainter(
        text: TextSpan(text: '$v', style: _labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y(v) - tp.height / 2));
    }
    final line = Paint()
      ..color = JColors.line
      ..strokeWidth = JSize.hairline;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, line);

    // Pain limit, dashed.
    final ly = y(limit);
    for (var dx = plot.left; dx < plot.right; dx += 8) {
      canvas.drawLine(
        Offset(dx, ly),
        Offset((dx + 4).clamp(plot.left, plot.right), ly),
        line..color = JColors.grey,
      );
    }

    // Morning pain line, joined across days without a check-in.
    final path = Path();
    var started = false;
    for (final (i, d) in days.indexed) {
      final p = d.morningPain;
      if (p == null) continue;
      if (started) {
        path.lineTo(x(i), y(p));
      } else {
        path.moveTo(x(i), y(p));
        started = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = JColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    // A single check-in has no line to draw: mark it.
    final singles = days.where((d) => d.morningPain != null).length == 1;
    for (final (i, d) in days.indexed) {
      if (singles && d.morningPain != null) {
        canvas.drawCircle(
          Offset(x(i), y(d.morningPain!)),
          3,
          Paint()..color = JColors.white,
        );
      }
      if (d.sessionPain != null) {
        canvas.drawCircle(
          Offset(x(i), y(d.sessionPain!)),
          4,
          Paint()..color = JColors.green,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.days != days || old.limit != limit;
}
