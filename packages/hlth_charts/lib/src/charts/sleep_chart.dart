import 'dart:math' as math;

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
const double _bottomInset = 22;
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

    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _update(d.localPosition.dx, size, segments),
          onPanStart: (d) => _update(d.localPosition.dx, size, segments),
          onPanUpdate: (d) => _update(d.localPosition.dx, size, segments),
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

    // Gradient transition ramps (sleep_chart style): each contiguous
    // transition is a vertical bar the same thickness as the capsules,
    // filled with a gradient between the two stage colours, so the lanes
    // read as one continuous ribbon weaving between stages. Drawn under the
    // capsules so the rounded caps sit on top.
    for (var i = 0; i < segments.length - 1; i++) {
      final gap = segments[i + 1].start.difference(segments[i].end);
      if (gap > _gapThreshold) continue; // real gap → no ramp
      final x = xFor(segments[i].end);
      final y1 = laneCenter(segments[i].stage);
      final y2 = laneCenter(segments[i + 1].stage);
      final top = math.min(y1, y2);
      final bot = math.max(y1, y2);
      final topColor =
          _stageColor(y1 <= y2 ? segments[i].stage : segments[i + 1].stage);
      final botColor =
          _stageColor(y1 <= y2 ? segments[i + 1].stage : segments[i].stage);
      final rect = Rect.fromLTRB(
        x - blockH / 2,
        top - blockH / 2,
        x + blockH / 2,
        bot + blockH / 2,
      );
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, botColor],
      ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(blockH / 2)),
        Paint()..shader = shader,
      );
    }

    // Stage capsules.
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(blockH / 2)),
        Paint()
          ..color = _stageColor(seg.stage).withOpacity(dim ? 0.45 : 1.0),
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

    // Time axis — 24h HH:MM at ~4 ticks.
    const ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final t =
          start.add(Duration(microseconds: (total * i / ticks).round()));
      final x = xFor(t).clamp(plotLeft, plotRight);
      final tp = TextPainter(
        text: TextSpan(text: _fmt(t), style: HlthChartText.axisLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (x - tp.width / 2).clamp(plotLeft, size.width - tp.width);
      tp.paint(canvas, Offset(lx, size.height - tp.height));
    }
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(_SleepTimelinePainter old) =>
      old.segments != segments ||
      old.selected != selected ||
      old.indicatorX != indicatorX;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.segment, required this.x, required this.width});
  final SleepSegment segment;
  final double x;
  final double width;

  @override
  Widget build(BuildContext context) {
    const w = 128.0;
    final left = (x - w / 2).clamp(0.0, width - w);
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: HlthChartTokens.cardSurfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _stageColor(segment.stage).withOpacity(0.6),
          ),
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
            const SizedBox(height: 2),
            Text(
              '${fmt(segment.start)}–${fmt(segment.end)}',
              style: HlthChartText.axisLabel,
            ),
          ],
        ),
      ),
    );
  }
}
