import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_shell.dart';
import '../chart_state.dart';
import '../chart_theme.dart';
import '../readings/hr_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Dense thin-bar chart matching the Figma's Heart Rate card. Bars tagged
/// as elevated/peak paint in the accent green so a zone excursion reads
/// at a glance without a legend.
class HrChart extends StatelessWidget {
  const HrChart({
    super.key,
    required this.state,
    required this.now,
    this.range = TimeRange.sevenDays,
  });

  final ChartState<HrReading> state;
  final DateTime now;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    return ChartShell<HrReading>(
      state: state,
      accent: HlthChartTokens.hr,
      emptyIcon: Icons.favorite_outline,
      dataBuilder: (context, data) {
        final windowed = _windowed(data.readings);
        if (windowed.isEmpty) {
          return const Center(
            child: Text(
              'No readings in this range.',
              style: HlthChartText.cardSubtitle,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final values = windowed.map((r) => r.bpm).toList();
            final minV = values.reduce((a, b) => a < b ? a : b);
            final maxV = values.reduce((a, b) => a > b ? a : b);
            final geometry = ChartGeometry(
              size: Size(c.maxWidth, c.maxHeight),
              minY: (minV - 8).clamp(0, double.infinity).toDouble(),
              maxY: maxV + 8,
              insets: const EdgeInsets.fromLTRB(4, 8, 4, 22),
            );
            final points = <ScrubPoint>[
              for (var i = 0; i < windowed.length; i++)
                ScrubPoint(
                  x: geometry.xForIndex(i, windowed.length, fencePost: false),
                  y: geometry.yForValue(windowed[i].bpm),
                  label: '${windowed[i].bpm.toStringAsFixed(0)} bpm',
                ),
            ];
            return ScrubOverlay(
              accent: HlthChartTokens.hr,
              points: points,
              builder: (_, size) => CustomPaint(
                size: size,
                painter: _HrBarsPainter(
                  readings: windowed,
                  geometry: geometry,
                  axisLabels: _axisLabels(windowed),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<HrReading> _windowed(List<HrReading> all) {
    final cutoff = now.subtract(range.duration);
    final sorted = [...all]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return [
      for (final r in sorted)
        if (!r.timestamp.isBefore(cutoff) && !r.timestamp.isAfter(now)) r,
    ];
  }

  static List<String> _axisLabels(List<HrReading> rs) {
    if (rs.isEmpty) return const [];
    final step = (rs.length / 4).ceil().clamp(1, rs.length);
    String fmt(DateTime d) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final p = d.hour < 12 ? 'am' : 'pm';
      return '$h$p';
    }

    return [
      for (var i = 0; i < rs.length; i++)
        if (i % step == 0 || i == rs.length - 1) fmt(rs[i].timestamp) else '',
    ];
  }
}

class _HrBarsPainter extends CustomPainter {
  _HrBarsPainter({
    required this.readings,
    required this.geometry,
    required this.axisLabels,
  });

  final List<HrReading> readings;
  final ChartGeometry geometry;
  final List<String> axisLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final count = readings.length;
    if (count == 0) return;
    final slot = geometry.plotWidth / count;
    final barWidth = (slot * 0.5).clamp(1.0, 4.0);
    final base = geometry.insets.top + geometry.plotHeight;

    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count, fencePost: false);
      final y = geometry.yForValue(readings[i].bpm);
      final color = switch (readings[i].zone) {
        HrZone.normal => HlthChartTokens.hr,
        HrZone.elevated => HlthChartTokens.hrAccent,
        HrZone.peak => HlthChartTokens.hrAccent,
      };
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, y, barWidth, base - y),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }

    _paintAxisLabels(canvas);
  }

  void _paintAxisLabels(Canvas canvas) {
    if (axisLabels.isEmpty) return;
    for (var i = 0; i < readings.length && i < axisLabels.length; i++) {
      if (axisLabels[i].isEmpty) continue;
      final x = geometry.xForIndex(i, readings.length, fencePost: false);
      final tp = TextPainter(
        text: TextSpan(text: axisLabels[i], style: HlthChartText.axisLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, geometry.size.height - tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(_HrBarsPainter old) => old.readings != readings;
}
