import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_shell.dart';
import '../chart_state.dart';
import '../chart_theme.dart';
import '../readings/stress_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Line + area for the 0-100 stress index. Threshold bands (rest / low /
/// moderate / high) paint as thin horizontal rules so a reader doesn't
/// need the legend to see whether a spike crossed into "high".
class StressChart extends StatelessWidget {
  const StressChart({
    super.key,
    required this.state,
    required this.now,
    this.range = TimeRange.sevenDays,
  });

  final ChartState<StressReading> state;
  final DateTime now;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    return ChartShell<StressReading>(
      state: state,
      accent: HlthChartTokens.stress,
      emptyIcon: Icons.self_improvement,
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
            final geometry = ChartGeometry(
              size: Size(c.maxWidth, c.maxHeight),
              minY: 0,
              maxY: 100,
              insets: const EdgeInsets.fromLTRB(4, 8, 4, 22),
            );
            final points = <ScrubPoint>[
              for (var i = 0; i < windowed.length; i++)
                ScrubPoint(
                  x: geometry.xForIndex(i, windowed.length),
                  y: geometry.yForValue(windowed[i].index),
                  label: '${windowed[i].index.toStringAsFixed(0)}',
                ),
            ];
            return ScrubOverlay(
              accent: HlthChartTokens.stress,
              points: points,
              builder: (_, size) => CustomPaint(
                size: size,
                painter: _StressPainter(
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

  List<StressReading> _windowed(List<StressReading> all) {
    final cutoff = now.subtract(range.duration);
    final sorted = [...all]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return [
      for (final r in sorted)
        if (!r.timestamp.isBefore(cutoff) && !r.timestamp.isAfter(now)) r,
    ];
  }

  static List<String> _axisLabels(List<StressReading> rs) {
    if (rs.isEmpty) return const [];
    const weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final step = (rs.length / 4).ceil().clamp(1, rs.length);
    return [
      for (var i = 0; i < rs.length; i++)
        if (i % step == 0 || i == rs.length - 1)
          weekday[(rs[i].timestamp.weekday - 1) % 7]
        else
          '',
    ];
  }
}

class _StressPainter extends CustomPainter {
  _StressPainter({
    required this.readings,
    required this.geometry,
    required this.axisLabels,
  });

  final List<StressReading> readings;
  final ChartGeometry geometry;
  final List<String> axisLabels;

  @override
  void paint(Canvas canvas, Size size) {
    _paintThresholds(canvas);
    _paintArea(canvas);
    _paintAxisLabels(canvas);
  }

  void _paintThresholds(Canvas canvas) {
    final paint = Paint()
      ..color = HlthChartTokens.axis
      ..strokeWidth = 1;
    for (final v in const [25.0, 50.0, 75.0]) {
      final y = geometry.yForValue(v);
      var x = geometry.insets.left;
      final end = geometry.size.width - geometry.insets.right;
      while (x < end) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), paint);
        x += 7;
      }
    }
  }

  void _paintArea(Canvas canvas) {
    final count = readings.length;
    if (count == 0) return;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: HlthChartTokens.areaGradient(HlthChartTokens.stress),
      stops: HlthChartTokens.areaStops,
    );
    final plotRect = Rect.fromLTWH(
      geometry.insets.left,
      geometry.insets.top,
      geometry.plotWidth,
      geometry.plotHeight,
    );

    final path = Path();
    final line = Path();
    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count);
      final y = geometry.yForValue(readings[i].index);
      if (i == 0) {
        path.moveTo(x, geometry.insets.top + geometry.plotHeight);
        path.lineTo(x, y);
        line.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        line.lineTo(x, y);
      }
    }
    path
      ..lineTo(
        geometry.xForIndex(count - 1, count),
        geometry.insets.top + geometry.plotHeight,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..shader = gradient.createShader(plotRect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = HlthChartTokens.stress
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (count <= 3) {
      final dot = Paint()..color = HlthChartTokens.stress;
      final outer = Paint()..color = HlthChartTokens.textPrimary;
      for (var i = 0; i < count; i++) {
        final x = geometry.xForIndex(i, count);
        final y = geometry.yForValue(readings[i].index);
        canvas.drawCircle(Offset(x, y), 4.5, outer);
        canvas.drawCircle(Offset(x, y), 3, dot);
      }
    }
  }

  void _paintAxisLabels(Canvas canvas) {
    if (axisLabels.isEmpty) return;
    for (var i = 0; i < readings.length && i < axisLabels.length; i++) {
      if (axisLabels[i].isEmpty) continue;
      final x = geometry.xForIndex(i, readings.length);
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
  bool shouldRepaint(_StressPainter old) => old.readings != readings;
}
