import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_shell.dart';
import '../chart_state.dart';
import '../chart_theme.dart';
import '../readings/spo2_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// SpO2 line chart with a shaded "healthy range" band (95-100%). The band
/// is the point of the chart — a value's absolute height matters less
/// than whether it sits inside or outside clinical normal.
class Spo2Chart extends StatelessWidget {
  const Spo2Chart({
    super.key,
    required this.state,
    required this.now,
    this.range = TimeRange.sevenDays,
    this.healthyMin = 95,
    this.healthyMax = 100,
  });

  final ChartState<Spo2Reading> state;
  final DateTime now;
  final TimeRange range;
  final double healthyMin;
  final double healthyMax;

  @override
  Widget build(BuildContext context) {
    return ChartShell<Spo2Reading>(
      state: state,
      accent: HlthChartTokens.spo2,
      emptyIcon: Icons.air,
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
            final values = windowed.map((r) => r.percent).toList();
            final minV = values.reduce((a, b) => a < b ? a : b);
            final maxV = values.reduce((a, b) => a > b ? a : b);
            final floor = (minV - 2).clamp(80, 100).toDouble();
            final ceil = (maxV + 1).clamp(floor + 1, 100).toDouble();
            final geometry = ChartGeometry(
              size: Size(c.maxWidth, c.maxHeight),
              minY: floor < healthyMin ? floor : (healthyMin - 2),
              maxY: ceil,
              insets: const EdgeInsets.fromLTRB(4, 8, 4, 22),
            );
            final points = <ScrubPoint>[
              for (var i = 0; i < windowed.length; i++)
                ScrubPoint(
                  x: geometry.xForIndex(i, windowed.length),
                  y: geometry.yForValue(windowed[i].percent),
                  label: '${windowed[i].percent.toStringAsFixed(0)}%',
                ),
            ];
            return ScrubOverlay(
              accent: HlthChartTokens.spo2,
              points: points,
              builder: (_, size) => CustomPaint(
                size: size,
                painter: _Spo2Painter(
                  readings: windowed,
                  geometry: geometry,
                  healthyMin: healthyMin,
                  healthyMax: healthyMax,
                  axisLabels: _axisLabels(windowed),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Spo2Reading> _windowed(List<Spo2Reading> all) {
    final cutoff = now.subtract(range.duration);
    final sorted = [...all]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return [
      for (final r in sorted)
        if (!r.timestamp.isBefore(cutoff) && !r.timestamp.isAfter(now)) r,
    ];
  }

  static List<String> _axisLabels(List<Spo2Reading> rs) {
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

class _Spo2Painter extends CustomPainter {
  _Spo2Painter({
    required this.readings,
    required this.geometry,
    required this.healthyMin,
    required this.healthyMax,
    required this.axisLabels,
  });

  final List<Spo2Reading> readings;
  final ChartGeometry geometry;
  final double healthyMin;
  final double healthyMax;
  final List<String> axisLabels;

  @override
  void paint(Canvas canvas, Size size) {
    _paintHealthyBand(canvas);
    _paintLine(canvas);
    _paintAxisLabels(canvas);
  }

  void _paintHealthyBand(Canvas canvas) {
    final top = geometry.yForValue(healthyMax);
    final bot = geometry.yForValue(healthyMin);
    final rect = Rect.fromLTRB(
      geometry.insets.left,
      top,
      geometry.size.width - geometry.insets.right,
      bot,
    );
    canvas.drawRect(
      rect,
      Paint()..color = HlthChartTokens.spo2.withOpacity(0.10),
    );
  }

  void _paintLine(Canvas canvas) {
    final count = readings.length;
    if (count == 0) return;
    final line = Path();
    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count);
      final y = geometry.yForValue(readings[i].percent);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = HlthChartTokens.spo2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = HlthChartTokens.spo2;
    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count);
      final y = geometry.yForValue(readings[i].percent);
      canvas.drawCircle(Offset(x, y), 2.5, dot);
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
  bool shouldRepaint(_Spo2Painter old) => old.readings != readings;
}
