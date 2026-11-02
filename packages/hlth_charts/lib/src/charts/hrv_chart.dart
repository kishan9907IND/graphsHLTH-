import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_shell.dart';
import '../chart_state.dart';
import '../chart_theme.dart';
import '../readings/hrv_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Area chart of overnight RMSSD with an optional baseline band (mean ±1σ
/// over the window). The future portion of the x-axis is drawn as a thin
/// white line — same convention as the Figma's Daily Average card.
class HrvChart extends StatelessWidget {
  const HrvChart({
    super.key,
    required this.state,
    required this.now,
    this.range = TimeRange.sevenDays,
    this.showBaselineBand = true,
  });

  final ChartState<HrvReading> state;
  final DateTime now;
  final TimeRange range;
  final bool showBaselineBand;

  @override
  Widget build(BuildContext context) {
    return ChartShell<HrvReading>(
      state: state,
      accent: HlthChartTokens.hrv,
      emptyIcon: Icons.nightlight,
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
        final values = windowed.map((r) => r.milliseconds).toList();
        final mean = values.reduce((a, b) => a + b) / values.length;
        final sigma = _stdDev(values, mean);
        return LayoutBuilder(
          builder: (context, constraints) {
            final geometry = ChartGeometry(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              minY: (values.reduce((a, b) => a < b ? a : b) - 8)
                  .clamp(0, double.infinity)
                  .toDouble(),
              maxY: values.reduce((a, b) => a > b ? a : b) + 8,
              insets: const EdgeInsets.fromLTRB(4, 8, 4, 22),
            );
            final points = <ScrubPoint>[
              for (var i = 0; i < windowed.length; i++)
                ScrubPoint(
                  x: geometry.xForIndex(i, windowed.length),
                  y: geometry.yForValue(windowed[i].milliseconds),
                  label: '${windowed[i].milliseconds.toStringAsFixed(0)} ms',
                ),
            ];
            return ScrubOverlay(
              accent: HlthChartTokens.hrv,
              points: points,
              builder: (context, size) => CustomPaint(
                size: size,
                painter: _HrvAreaPainter(
                  readings: windowed,
                  geometry: geometry,
                  showBaselineBand:
                      showBaselineBand && windowed.length >= 3,
                  bandCentre: mean,
                  bandHalfWidth: sigma,
                  xAxisLabels: _axisLabels(windowed, range),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<HrvReading> _windowed(List<HrvReading> all) {
    final cutoff = now.subtract(range.duration);
    final sorted = [...all]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return [
      for (final r in sorted)
        if (!r.timestamp.isBefore(cutoff) && !r.timestamp.isAfter(now)) r,
    ];
  }

  static double _stdDev(List<double> xs, double mean) {
    if (xs.length < 2) return 0;
    final sumSq = xs.fold<double>(0, (s, x) => s + (x - mean) * (x - mean));
    return math.sqrt(sumSq / (xs.length - 1));
  }

  static List<String> _axisLabels(List<HrvReading> rs, TimeRange range) {
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

class _HrvAreaPainter extends CustomPainter {
  _HrvAreaPainter({
    required this.readings,
    required this.geometry,
    required this.showBaselineBand,
    required this.bandCentre,
    required this.bandHalfWidth,
    required this.xAxisLabels,
  });

  final List<HrvReading> readings;
  final ChartGeometry geometry;
  final bool showBaselineBand;
  final double bandCentre;
  final double bandHalfWidth;
  final List<String> xAxisLabels;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaselineBand(canvas);
    _paintAreaAndLine(canvas);
    _paintAxisTicks(canvas);
    _paintAxisLabels(canvas);
  }

  void _paintBaselineBand(Canvas canvas) {
    if (!showBaselineBand || bandHalfWidth <= 0) return;
    final top = geometry.yForValue(bandCentre + bandHalfWidth);
    final bot = geometry.yForValue(bandCentre - bandHalfWidth);
    final rect = Rect.fromLTRB(
      geometry.insets.left,
      top,
      geometry.size.width - geometry.insets.right,
      bot,
    );
    final fill = Paint()
      ..color = HlthChartTokens.hrv.withOpacity(0.08);
    canvas.drawRect(rect, fill);

    final line = Paint()
      ..color = HlthChartTokens.hrv.withOpacity(0.35)
      ..strokeWidth = 1;
    final centreY = geometry.yForValue(bandCentre);
    final startX = geometry.insets.left;
    final endX = geometry.size.width - geometry.insets.right;
    var x = startX;
    while (x < endX) {
      canvas.drawLine(Offset(x, centreY), Offset(x + 4, centreY), line);
      x += 8;
    }
  }

  void _paintAreaAndLine(Canvas canvas) {
    final count = readings.length;
    if (count == 0) return;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: HlthChartTokens.areaGradient(HlthChartTokens.hrv),
      stops: HlthChartTokens.areaStops,
    );
    final plotRect = Rect.fromLTWH(
      geometry.insets.left,
      geometry.insets.top,
      geometry.plotWidth,
      geometry.plotHeight,
    );

    final path = Path();
    final linePath = Path();
    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count);
      final y = geometry.yForValue(readings[i].milliseconds);
      if (i == 0) {
        path.moveTo(x, geometry.insets.top + geometry.plotHeight);
        path.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    path
      ..lineTo(
        geometry.xForIndex(count - 1, count),
        geometry.insets.top + geometry.plotHeight,
      )
      ..close();

    canvas.drawPath(path, Paint()..shader = gradient.createShader(plotRect));
    canvas.drawPath(
      linePath,
      Paint()
        ..color = HlthChartTokens.hrv
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Sparse — draw the datapoints as dots so a one- or two-point week
    // doesn't vanish into the gradient.
    if (count <= 3) {
      final dot = Paint()..color = HlthChartTokens.hrv;
      final outer = Paint()..color = HlthChartTokens.textPrimary;
      for (var i = 0; i < count; i++) {
        final x = geometry.xForIndex(i, count);
        final y = geometry.yForValue(readings[i].milliseconds);
        canvas.drawCircle(Offset(x, y), 4.5, outer);
        canvas.drawCircle(Offset(x, y), 3, dot);
      }
    }
  }

  void _paintAxisTicks(Canvas canvas) {
    final count = readings.length;
    final paint = Paint()
      ..color = HlthChartTokens.axis
      ..strokeWidth = 1;
    final y = geometry.size.height - geometry.insets.bottom + 4;
    for (var i = 0; i < count; i++) {
      final x = geometry.xForIndex(i, count);
      final tall = i % 2 == 0;
      canvas.drawLine(Offset(x, y), Offset(x, y + (tall ? 4 : 2)), paint);
    }
  }

  void _paintAxisLabels(Canvas canvas) {
    if (xAxisLabels.isEmpty) return;
    final count = readings.length;
    for (var i = 0; i < count && i < xAxisLabels.length; i++) {
      if (xAxisLabels[i].isEmpty) continue;
      final x = geometry.xForIndex(i, count);
      final tp = TextPainter(
        text: TextSpan(text: xAxisLabels[i], style: HlthChartText.axisLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, geometry.size.height - tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(_HrvAreaPainter old) =>
      old.readings != readings || old.showBaselineBand != showBaselineBand;
}
