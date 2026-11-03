import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/stress_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Plot-only stress renderer: area on a fixed 0-100 scale with rest/low/
/// moderate/high threshold rules so a spike's zone reads without the legend.
class StressPlot extends StatelessWidget {
  const StressPlot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.week,
    this.onZoom,
  });

  final List<StressReading> readings;
  final DateTime now;
  final TimeRange range;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.stress;

  @override
  Widget build(BuildContext context) {
    final data = windowed(readings, now, range, (r) => r.timestamp);
    if (data.isEmpty) {
      return const Center(
        child: Text('No data in this range.',
            style: HlthChartText.cardSubtitle),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: 0,
          maxY: 100,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );
        final runs = splitOnGaps(data, range, (r) => r.timestamp)
            .map((run) => run
                .map((r) => Offset(
                      geometry.xForFraction(
                          range.fractionOf(r.timestamp, now)),
                      geometry.yForValue(r.index),
                    ))
                .toList())
            .toList();
        final points = [
          for (final r in data)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(r.timestamp, now)),
              y: geometry.yForValue(r.index),
              label: r.index.toStringAsFixed(0),
            ),
        ];
        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _StressPainter(
              runs: runs,
              geometry: geometry,
              ticks: range.axisTicks(now),
            ),
          ),
        );
      },
    );
  }
}

class _StressPainter extends CustomPainter {
  _StressPainter({
    required this.runs,
    required this.geometry,
    required this.ticks,
  });

  final List<List<Offset>> runs;
  final ChartGeometry geometry;
  final List<AxisTick> ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = HlthChartTokens.axis
      ..strokeWidth = 1;
    for (final v in const [25.0, 50.0, 75.0]) {
      final y = geometry.yForValue(v);
      var x = geometry.insets.left;
      final end = geometry.size.width - geometry.insets.right;
      while (x < end) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), dash);
        x += 7;
      }
    }
    paintSeries(canvas, geometry, runs, HlthChartTokens.stress, smooth: true);
    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_StressPainter old) => old.runs != runs;
}
