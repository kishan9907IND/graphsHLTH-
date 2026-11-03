import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chart_theme.dart';
import '../readings/sleep_segment.dart';

/// Apple / Google Health–style sleep-stage timeline.
///
/// Design ported from two open-source references the product team pointed to:
///   - sleep_stage_chart (Flutter): one lane per stage, rounded blocks,
///     connector lines between adjacent blocks, a draggable tooltip with a
///     vertical indicator, and an "unknown" type for gaps.
///   - SleepChartKit (SwiftUI): a Canvas timeline over Awake/REM/Core/Deep.
///
/// Each stage gets a horizontal lane (Awake top → Deep bottom). A segment is a
/// rounded capsule in its lane spanning its time range; transitions are thin
/// vertical connectors. A real break in the data (a time gap) is left blank.
/// Drag across it to move an indicator and read the stage + time in a tooltip.
class SleepPlot extends StatefulWidget {
  const SleepPlot({super.key, required this.segments});

  final List<SleepSegment> segments;

  @override
  State<SleepPlot> createState() => _SleepPlotState();
}

const double _labelWidth = 42;
const double _topInset = 8;
const double _bottomInset = 8;
const Duration _gapThreshold = Duration(minutes: 5);

// Lanes top → bottom. Apple orders Awake, REM, Core, Deep.
const List<SleepStage> _lanes = [
  SleepStage.awake,
  SleepStage.rem,
  SleepStage.light,
  SleepStage.deep,
];

String _laneLabel(SleepStage s) => switch (s) {
      SleepStage.awake => 'Awake',
      SleepStage.rem => 'REM',
      SleepStage.light => 'Core',
      SleepStage.deep => 'Deep',
    };

Color _stageColor(SleepStage s) => switch (s) {
      SleepStage.awake => HlthChartTokens.sleepAwake,
      SleepStage.rem => HlthChartTokens.sleepRem,
      SleepStage.light => HlthChartTokens.sleepLight,
      SleepStage.deep => HlthChartTokens.sleepDeep,
    };

class _SleepPlotState extends State<SleepPlot> {
  double? _indicatorX;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final segments = [...widget.segments]
      ..sort((a, b) => a.start.compareTo(b.start));
    if (segments.isEmpty) {
      return const Center(
        child: Text('No data in this range.',
            style: HlthChartText.cardSubtitle),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _update(d.localPosition.dx, size, segments),
                onPanStart: (d) => _update(d.localPosition.dx, size, segments),
                onPanUpdate: (d) =>
                    _update(d.localPosition.dx, size, segments),
                onPanEnd: (_) => _clear(),
                onTapUp: (_) => _clear(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _SleepTimelinePainter(
                        segments: segments,
                        selected: _selected,
                        indicatorX: _indicatorX,
                      ),
                    ),
                    if (_selected != null)
                      _Tooltip(
                        segment: segments[_selected!],
                        x: _indicatorX!,
                        width: size.width,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // Sleep-schedule strip: bedtime → wake with moon/sun + tick marks.
        _ScheduleStrip(start: segments.first.start, end: segments.last.end),
      ],
    );
  }

  void _update(double dx, Size size, List<SleepSegment> segments) {
    final start = segments.first.start;
    final end = segments.last.end;
    final total = end.difference(start).inMicroseconds.toDouble();
    if (total <= 0) return;
    final plotLeft = _labelWidth;
    final plotRight = size.width;
    final clampedX = dx.clamp(plotLeft, plotRight);
    final frac = ((clampedX - plotLeft) / (plotRight - plotLeft)).clamp(0.0, 1.0);
    final targetMicros = total * frac;
    int? found;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i].start.difference(start).inMicroseconds;
      final e = segments[i].end.difference(start).inMicroseconds;
      if (targetMicros >= s && targetMicros <= e) {
        found = i;
        break;
      }
    }
    if (found != _selected) HapticFeedback.selectionClick();
    setState(() {
      _indicatorX = clampedX;
      _selected = found;
    });
  }

  void _clear() {
    final at = _selected;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_selected == at) {
        setState(() {
          _selected = null;
          _indicatorX = null;
        });
      }
    });
  }
}

class _SleepTimelinePainter extends CustomPainter {
  _SleepTimelinePainter({
    required this.segments,
    required this.selected,
    required this.indicatorX,
  });

  final List<SleepSegment> segments;
  final int? selected;
  final double? indicatorX;

  @override
  void paint(Canvas canvas, Size size) {
    final start = segments.first.start;
    final end = segments.last.end;
    final total = end.difference(start).inMicroseconds.toDouble();
    if (total <= 0) return;

    final plotLeft = _labelWidth;
    final plotRight = size.width;
    final plotW = plotRight - plotLeft;
    final laneArea = size.height - _topInset - _bottomInset;
    final laneH = laneArea / _lanes.length;
    final blockH = (laneH * 0.52).clamp(8.0, 26.0);

    double xFor(DateTime t) =>
        plotLeft + (t.difference(start).inMicroseconds / total) * plotW;
    double laneCenter(SleepStage s) {
      final idx = _lanes.indexOf(s);
      return _topInset + laneH * idx + laneH / 2;
    }

    // Dotted vertical hour gridlines behind the ribbon.
    final grid = Paint()
      ..color = HlthChartTokens.axis.withOpacity(0.5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final t = start.add(Duration(microseconds: (total * i / 4).round()));
      final x = xFor(t).clamp(plotLeft, plotRight);
      for (var y = _topInset; y < size.height - _bottomInset; y += 5) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 2), grid);
      }
    }

    // Lane labels + faint baselines.
    final baseline = Paint()
      ..color = HlthChartTokens.axis.withOpacity(0.4)
      ..strokeWidth = 1;
    for (final stage in _lanes) {
      final yc = laneCenter(stage);
      canvas.drawLine(Offset(plotLeft, yc), Offset(plotRight, yc), baseline);
      final tp = TextPainter(
        text: TextSpan(text: _laneLabel(stage), style: HlthChartText.axisLabel),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _labelWidth - 6);
      tp.paint(canvas, Offset(0, yc - tp.height / 2));
    }

    // Thin vertical connectors at each contiguous transition (Apple Health
    // style), tinted to the later stage. Drawn under the capsules.
    for (var i = 0; i < segments.length - 1; i++) {
      final gap = segments[i + 1].start.difference(segments[i].end);
      if (gap > _gapThreshold) continue; // real gap → no connector
      final x = xFor(segments[i].end);
      final y1 = laneCenter(segments[i].stage);
      final y2 = laneCenter(segments[i + 1].stage);
      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        Paint()
          ..color = _stageColor(segments[i + 1].stage).withOpacity(0.55)
          ..strokeWidth = 2,
      );
    }

    // Stage capsules, each with a subtle vertical gradient (lighter top).
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final left = xFor(seg.start);
      final right = xFor(seg.end);
      final yc = laneCenter(seg.stage);
      final rect = Rect.fromLTRB(
        left,
        yc - blockH / 2,
        (right).clamp(left + 2, plotRight),
        yc + blockH / 2,
      );
      final dim = selected != null && selected != i;
      final base = _stageColor(seg.stage).withOpacity(dim ? 0.4 : 1.0);
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(base, Colors.white, 0.22)!, base],
      ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(blockH / 2)),
        Paint()..shader = shader,
      );
    }

    // Indicator line.
    if (indicatorX != null) {
      final x = indicatorX!.clamp(plotLeft, plotRight);
      canvas.drawLine(
        Offset(x, _topInset),
        Offset(x, size.height - _bottomInset),
        Paint()
          ..color = HlthChartTokens.textPrimary.withOpacity(0.35)
          ..strokeWidth = 1,
      );
    }

  }

  @override
  bool shouldRepaint(_SleepTimelinePainter old) =>
      old.segments != segments ||
      old.selected != selected ||
      old.indicatorX != indicatorX;
}

/// The scrub pill: stage name + duration + clock range, like the reference
/// ("Deep / 44 min / 11:30 pm – 12:15 am"). Floats near the top, following
/// the indicator.
class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.segment, required this.x, required this.width});
  final SleepSegment segment;
  final double x;
  final double width;

  @override
  Widget build(BuildContext context) {
    const w = 150.0;
    final left = (x - w / 2).clamp(0.0, width - w);
    final mins = segment.duration.inMinutes;
    final durText = mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '$mins min';
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: HlthChartTokens.cardSurfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _stageColor(segment.stage).withOpacity(0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _stageColor(segment.stage),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _laneLabel(segment.stage),
                  style: HlthChartText.cardSubtitle.copyWith(
                    color: HlthChartTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              durText,
              style: HlthChartText.cardTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              '${_clock(segment.start)} – ${_clock(segment.end)}',
              style: HlthChartText.axisLabel,
            ),
          ],
        ),
      ),
    );
  }
}

/// 12-hour clock like "11:30 pm".
String _clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
}

/// Bottom sleep-schedule strip: moon + bedtime on the left, sun + wake on the
/// right, with evenly spaced hour ticks between — the compact schedule bar
/// from the reference.
class _ScheduleStrip extends StatelessWidget {
  const _ScheduleStrip({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round,
              size: 14, color: HlthChartTokens.textSecondary),
          const SizedBox(width: 6),
          Text(_clock(start), style: HlthChartText.axisLabel),
          const SizedBox(width: 8),
          const Expanded(child: _TickRail()),
          const SizedBox(width: 8),
          Text(_clock(end), style: HlthChartText.axisLabel),
          const SizedBox(width: 6),
          const Icon(Icons.wb_sunny_outlined,
              size: 14, color: HlthChartTokens.textSecondary),
        ],
      ),
    );
  }
}

class _TickRail extends StatelessWidget {
  const _TickRail();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: CustomPaint(painter: _TickPainter()),
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HlthChartTokens.axis
      ..strokeWidth = 1;
    const count = 28;
    for (var i = 0; i <= count; i++) {
      final x = size.width * i / count;
      final tall = i % 4 == 0;
      canvas.drawLine(
        Offset(x, size.height / 2 - (tall ? 4 : 2)),
        Offset(x, size.height / 2 + (tall ? 4 : 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => false;
}
