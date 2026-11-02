import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chart_theme.dart';
import '../readings/sleep_segment.dart';

/// Plot-only hypnogram. Each [SleepSegment] paints as a bar whose height
/// encodes its stage (deep lowest, awake highest). Sleep is categorical, so
/// it owns its own touch handling — tap/drag highlights a segment and shows
/// its stage label rather than a scalar value.
class SleepPlot extends StatefulWidget {
  const SleepPlot({super.key, required this.segments});

  final List<SleepSegment> segments;

  @override
  State<SleepPlot> createState() => _SleepPlotState();
}

class _SleepPlotState extends State<SleepPlot> {
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
          onTapDown: (d) => _update(d.localPosition.dx, size.width, segments),
          onPanStart: (d) => _update(d.localPosition.dx, size.width, segments),
          onPanUpdate: (d) => _update(d.localPosition.dx, size.width, segments),
          onPanEnd: (_) => _clear(),
          onTapUp: (_) => _clear(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: size,
                painter: _HypnogramPainter(
                    segments: segments, selected: _selected),
              ),
              if (_selected != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Center(
                    child: _StageBadge(stage: segments[_selected!].stage),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _update(double dx, double width, List<SleepSegment> segments) {
    final anchor = segments.first.start;
    final total =
        segments.last.end.difference(anchor).inMicroseconds.toDouble();
    if (total <= 0) return;
    final target = (dx / width) * total;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i].start.difference(anchor).inMicroseconds;
      final e = segments[i].end.difference(anchor).inMicroseconds;
      if (target >= s && target <= e) {
        if (_selected != i) {
          HapticFeedback.selectionClick();
          setState(() => _selected = i);
        }
        return;
      }
    }
  }

  void _clear() {
    final at = _selected;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_selected == at) setState(() => _selected = null);
    });
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({required this.segments, required this.selected});
  final List<SleepSegment> segments;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const insetTop = 10.0;
    const insetBottom = 24.0;
    final plotHeight = size.height - insetTop - insetBottom;
    final baseline = insetTop + plotHeight;
    final start = segments.first.start;
    final end = segments.last.end;
    final total = end.difference(start).inMicroseconds.toDouble();
    if (total <= 0) return;

    double xFor(DateTime t) =>
        (t.difference(start).inMicroseconds / total) * size.width;

    // Each stage fills from the baseline up to its band: deep lowest, awake
    // highest — so the ribbon's silhouette reads as sleep depth over time.
    double heightFor(SleepStage s) => switch (s) {
          SleepStage.deep => plotHeight * 0.30,
          SleepStage.light => plotHeight * 0.52,
          SleepStage.rem => plotHeight * 0.74,
          SleepStage.awake => plotHeight * 0.96,
        };

    Color colorFor(SleepStage s) => switch (s) {
          SleepStage.deep => HlthChartTokens.sleepDeep,
          SleepStage.light => HlthChartTokens.sleepLight,
          SleepStage.rem => HlthChartTokens.sleepRem,
          SleepStage.awake => HlthChartTokens.sleepAwake,
        };

    // Dashed vertical time gridlines + 24h labels at ~4 evenly spaced ticks.
    final grid = Paint()
      ..color = HlthChartTokens.axis.withOpacity(0.6)
      ..strokeWidth = 1;
    const ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final t =
          start.add(Duration(microseconds: (total * i / ticks).round()));
      final x = xFor(t).clamp(0.0, size.width);
      for (var y = insetTop; y < baseline; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 3), grid);
      }
      final tp = TextPainter(
        text: TextSpan(text: _fmt(t), style: HlthChartText.axisLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(lx, size.height - tp.height));
    }

    // Ribbon columns. Positioned by timestamp, so a missing stretch (a gap
    // in the data) stays blank rather than being stretched over — that's the
    // "show the gaps" behaviour. A 0.75px inset on each side segments the
    // ribbon into distinct bars.
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final left = xFor(seg.start) + 0.75;
      final right = xFor(seg.end) - 0.75;
      if (right <= left) continue;
      final h = heightFor(seg.stage);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, baseline - h, right, baseline),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = selected == i
              ? colorFor(seg.stage)
              : colorFor(seg.stage).withOpacity(0.92),
      );
    }
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(_HypnogramPainter old) =>
      old.segments != segments || old.selected != selected;
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});
  final SleepStage stage;

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      SleepStage.deep => HlthChartTokens.sleepDeep,
      SleepStage.light => HlthChartTokens.sleepLight,
      SleepStage.rem => HlthChartTokens.sleepRem,
      SleepStage.awake => HlthChartTokens.sleepAwake,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        stage.label,
        style: HlthChartText.axisLabel.copyWith(
          color: HlthChartTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
