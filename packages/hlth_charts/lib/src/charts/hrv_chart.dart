import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/hrv_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Plot-only HRV renderer: area + baseline band (mean ±1σ over the window),
/// positioned by timestamp so gaps in the week show as breaks. Card chrome
/// (header, tabs, legend, state overlay) is the MetricChartCard's job.
class HrvPlot extends StatelessWidget {
  const HrvPlot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.week,
    this.showBaselineBand = true,
    this.onZoom,
  });

  final List<HrvReading> readings;
  final DateTime now;
  final TimeRange range;
  final bool showBaselineBand;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.hrv;

  @override
  Widget build(BuildContext context) {
    final data = windowed(readings, now, range, (r) => r.timestamp);
    if (data.isEmpty) return const _NoDataInRange();

    return LayoutBuilder(
      builder: (context, c) {
        final values = data.map((r) => r.milliseconds).toList();
        final mean = values.reduce((a, b) => a + b) / values.length;
        final sigma = _stdDev(values, mean);
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: (values.reduce(math.min) - 8).clamp(0, double.infinity),
          maxY: values.reduce(math.max) + 8,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );

        final runs = splitOnGaps(data, range, (r) => r.timestamp)
            .map((run) => run
                .map((r) => Offset(
                      geometry.xForFraction(
                          range.fractionOf(r.timestamp, now)),
                      geometry.yForValue(r.milliseconds),
                    ))
                .toList())
            .toList();

        final points = [
          for (final r in data)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(r.timestamp, now)),
              y: geometry.yForValue(r.milliseconds),
              label: '${r.milliseconds.toStringAsFixed(0)} ms',
            ),
        ];

        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _HrvPainter(
              runs: runs,
              geometry: geometry,
              ticks: range.axisTicks(now),
              showBand: showBaselineBand && data.length >= 3 && sigma > 0,
              bandLow: mean - sigma,
              bandHigh: mean + sigma,
              baseline: mean,
              endValue: values.last,
            ),
          ),
        );
      },
    );
  }

  static double _stdDev(List<double> xs, double mean) {
    if (xs.length < 2) return 0;
    final sumSq = xs.fold<double>(0, (s, x) => s + (x - mean) * (x - mean));
    return math.sqrt(sumSq / (xs.length - 1));
  }
}

class _HrvPainter extends CustomPainter {
  _HrvPainter({
    required this.runs,
    required this.geometry,
    required this.ticks,
    required this.showBand,
    required this.bandLow,
    required this.bandHigh,
    required this.baseline,
    required this.endValue,
  });

  final List<List<Offset>> runs;
  final ChartGeometry geometry;
  final List<AxisTick> ticks;
  final bool showBand;
  final double bandLow;
  final double bandHigh;
  final double baseline;
  final double endValue;

  static const Color _accent = HlthChartTokens.hrv;

  @override
  void paint(Canvas canvas, Size size) {
    // Y gridlines + value labels on the LEFT (Figma 1119:25338).
    paintYGrid(
      canvas,
      geometry,
      values: [geometry.maxY, baseline, geometry.minY],
      format: (v) => v.round().toString(),
      rightLabels: false,
    );

    // Baseline band + centre line + "Baseline NN" caption.
    if (showBand) {
      paintBand(canvas, geometry, bandLow, bandHigh, _accent);
      final by = geometry.yForValue(baseline);
      canvas.drawLine(
        Offset(geometry.insets.left, by),
        Offset(geometry.size.width - geometry.insets.right, by),
        Paint()
          ..color = _accent.withOpacity(0.85)
          ..strokeWidth = 1.5,
      );
      final cap = TextPainter(
        text: TextSpan(
          text: 'Baseline ${baseline.round()}',
          style: HlthChartText.axisLabel
              .copyWith(color: _accent.withOpacity(0.9)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      cap.paint(canvas, Offset(geometry.insets.left + 20, by - cap.height - 2));
    }

    // Angular polyline (no area fill) to match the Figma reference.
    paintSeries(canvas, geometry, runs, _accent, smooth: false, fill: false);

    // Node dots at every vertex.
    final dotFill = Paint()..color = _accent;
    final dotRing = Paint()
      ..color = HlthChartTokens.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final run in runs) {
      for (final p in run) {
        canvas.drawCircle(p, 3.2, dotFill);
        canvas.drawCircle(p, 3.2, dotRing);
      }
    }

    // End-point value label ("79 ms").
    if (runs.isNotEmpty && runs.last.isNotEmpty) {
      final end = runs.last.last;
      final tp = TextPainter(
        text: TextSpan(
          text: '${endValue.round()} ms',
          style: HlthChartText.axisLabel.copyWith(
            color: HlthChartTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (end.dx - tp.width)
          .clamp(0.0, geometry.size.width - tp.width)
          .toDouble();
      tp.paint(canvas, Offset(lx, end.dy - tp.height - 6));
    }

    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_HrvPainter old) =>
      old.runs != runs || old.showBand != showBand;
}

class _NoDataInRange extends StatelessWidget {
  const _NoDataInRange();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('No data in this range.',
            style: HlthChartText.cardSubtitle),
      );
}
