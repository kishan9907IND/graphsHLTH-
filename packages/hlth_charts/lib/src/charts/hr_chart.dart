import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/hr_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Plot-only heart-rate renderer: dense thin bars positioned by timestamp,
/// with zone-tagged bars (elevated/peak) in the accent green — the Heart
/// Rate card from the Figma.
class HrPlot extends StatelessWidget {
  const HrPlot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.day,
    this.onZoom,
  });

  final List<HrReading> readings;
  final DateTime now;
  final TimeRange range;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.hr;

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
        final values = data.map((r) => r.bpm).toList();
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: (values.reduce(math.min) - 8).clamp(0, double.infinity),
          maxY: values.reduce(math.max) + 8,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );
        final points = [
          for (final r in data)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(r.timestamp, now)),
              y: geometry.yForValue(r.bpm),
              label: '${r.bpm.toStringAsFixed(0)} bpm',
            ),
        ];
        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _HrBarsPainter(
              readings: data,
              now: now,
              range: range,
              geometry: geometry,
              ticks: range.axisTicks(now),
            ),
          ),
        );
      },
    );
  }
}

class _HrBarsPainter extends CustomPainter {
  _HrBarsPainter({
    required this.readings,
    required this.now,
    required this.range,
    required this.geometry,
    required this.ticks,
  });

  final List<HrReading> readings;
  final DateTime now;
  final TimeRange range;
  final ChartGeometry geometry;
  final List<AxisTick> ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final base = geometry.insets.top + geometry.plotHeight;
    // Bar width scales with density so a day (96 bars) and a week (672)
    // both stay legible.
    final barWidth = (geometry.plotWidth / readings.length * 0.6)
        .clamp(1.0, 4.0)
        .toDouble();
    for (final r in readings) {
      final x = geometry.xForFraction(range.fractionOf(r.timestamp, now));
      final y = geometry.yForValue(r.bpm);
      final color = r.zone == HrZone.normal
          ? HlthChartTokens.hr
          : HlthChartTokens.hrAccent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, y, barWidth, base - y),
          const Radius.circular(1.5),
        ),
        Paint()..color = color,
      );
    }
    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_HrBarsPainter old) => old.readings != readings;
}
