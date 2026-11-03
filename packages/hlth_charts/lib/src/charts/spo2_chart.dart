import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/spo2_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Plot-only SpO₂ renderer: line with a shaded healthy-range band (95-100%).
/// Whether a reading sits inside or outside the band matters more than its
/// absolute height, so the band is drawn first and emphasised.
class Spo2Plot extends StatelessWidget {
  const Spo2Plot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.week,
    this.healthyMin = 95,
    this.healthyMax = 100,
    this.onZoom,
  });

  final List<Spo2Reading> readings;
  final DateTime now;
  final TimeRange range;
  final double healthyMin;
  final double healthyMax;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.spo2;

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
        final values = data.map((r) => r.percent).toList();
        final floor = (values.reduce(math.min) - 2).clamp(80, 100).toDouble();
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: math.min(floor, healthyMin - 2),
          maxY: 100,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );
        final runs = splitOnGaps(data, range, (r) => r.timestamp)
            .map((run) => run
                .map((r) => Offset(
                      geometry.xForFraction(
                          range.fractionOf(r.timestamp, now)),
                      geometry.yForValue(r.percent),
                    ))
                .toList())
            .toList();
        final points = [
          for (final r in data)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(r.timestamp, now)),
              y: geometry.yForValue(r.percent),
              label: '${r.percent.toStringAsFixed(0)}%',
            ),
        ];
        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _Spo2Painter(
              runs: runs,
              geometry: geometry,
              ticks: range.axisTicks(now),
              healthyMin: healthyMin,
              healthyMax: healthyMax,
            ),
          ),
        );
      },
    );
  }
}

class _Spo2Painter extends CustomPainter {
  _Spo2Painter({
    required this.runs,
    required this.geometry,
    required this.ticks,
    required this.healthyMin,
    required this.healthyMax,
  });

  final List<List<Offset>> runs;
  final ChartGeometry geometry;
  final List<AxisTick> ticks;
  final double healthyMin;
  final double healthyMax;

  @override
  void paint(Canvas canvas, Size size) {
    paintYGrid(
      canvas,
      geometry,
      values: [geometry.minY, (geometry.minY + geometry.maxY) / 2, 100],
      format: (v) => v.toStringAsFixed(0),
    );
    paintBand(
        canvas, geometry, healthyMin, healthyMax, HlthChartTokens.spo2);
    paintSeries(canvas, geometry, runs, HlthChartTokens.spo2,
        smooth: true, fill: true);
    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_Spo2Painter old) => old.runs != runs;
}
