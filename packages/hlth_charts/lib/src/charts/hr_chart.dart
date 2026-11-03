import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/hr_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Apple-Health–style heart-rate range chart. Design ported from the
/// heart_rate_chart package (pub.dev, MIT): readings are grouped into time
/// buckets and each bucket draws a floating min–max range bar. Buckets that
/// touched an active zone get a green cap. A shaded band shows the multi-day
/// baseline range.
class HrPlot extends StatelessWidget {
  const HrPlot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.day,
    this.baselineLow = 80,
    this.baselineHigh = 124,
    this.onZoom,
  });

  final List<HrReading> readings;
  final DateTime now;
  final TimeRange range;
  final double baselineLow;
  final double baselineHigh;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.hr;

  Duration _bucket(TimeRange r) => switch (r) {
        TimeRange.day => const Duration(hours: 1),
        TimeRange.week => const Duration(days: 1),
        TimeRange.month => const Duration(days: 1),
        TimeRange.threeMonths => const Duration(days: 7),
      };

  @override
  Widget build(BuildContext context) {
    final data = windowed(readings, now, range, (r) => r.timestamp);
    if (data.isEmpty) {
      return const Center(
        child: Text('No data in this range.',
            style: HlthChartText.cardSubtitle),
      );
    }

    final windowStart = range.windowStart(now);
    final interval = _bucket(range).inMicroseconds;
    final byBucket = <int, List<HrReading>>{};
    for (final r in data) {
      final idx = r.timestamp.difference(windowStart).inMicroseconds ~/ interval;
      (byBucket[idx] ??= []).add(r);
    }
    final buckets = <_Bucket>[];
    byBucket.forEach((idx, rs) {
      final bpms = rs.map((r) => r.bpm).toList();
      buckets.add(_Bucket(
        center: windowStart.add(
            Duration(microseconds: (idx * interval + interval ~/ 2))),
        low: bpms.reduce(math.min),
        high: bpms.reduce(math.max),
        hasPeak: rs.any((r) => r.zone != HrZone.normal),
      ));
    });
    buckets.sort((a, b) => a.center.compareTo(b.center));

    return LayoutBuilder(
      builder: (context, c) {
        final lows = buckets.map((b) => b.low).toList();
        final highs = buckets.map((b) => b.high).toList();
        final dataMin = math.min(lows.reduce(math.min), baselineLow);
        final dataMax = math.max(highs.reduce(math.max), baselineHigh);
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: (dataMin - 8).clamp(0, double.infinity).toDouble(),
          maxY: dataMax + 8,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );
        final points = [
          for (final b in buckets)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(b.center, now)),
              y: geometry.yForValue(b.high),
              label: '${b.low.round()}–${b.high.round()} bpm',
            ),
        ];
        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _HrRangePainter(
              buckets: buckets,
              geometry: geometry,
              now: now,
              range: range,
              ticks: range.axisTicks(now),
              baselineLow: baselineLow,
              baselineHigh: baselineHigh,
            ),
          ),
        );
      },
    );
  }
}

class _Bucket {
  _Bucket({
    required this.center,
    required this.low,
    required this.high,
    required this.hasPeak,
  });
  final DateTime center;
  final double low;
  final double high;
  final bool hasPeak;
}

class _HrRangePainter extends CustomPainter {
  _HrRangePainter({
    required this.buckets,
    required this.geometry,
    required this.now,
    required this.range,
    required this.ticks,
    required this.baselineLow,
    required this.baselineHigh,
  });

  final List<_Bucket> buckets;
  final ChartGeometry geometry;
  final DateTime now;
  final TimeRange range;
  final List<AxisTick> ticks;
  final double baselineLow;
  final double baselineHigh;

  @override
  void paint(Canvas canvas, Size size) {
    paintYGrid(
      canvas,
      geometry,
      values: [geometry.minY, (geometry.minY + geometry.maxY) / 2, geometry.maxY],
      format: (v) => v.round().toString(),
    );
    // 7-day baseline band behind the bars.
    paintBand(canvas, geometry, baselineLow, baselineHigh, HlthChartTokens.hr);

    final barWidth = (geometry.plotWidth / buckets.length * 0.55)
        .clamp(2.0, 10.0)
        .toDouble();
    for (final b in buckets) {
      final x = geometry.xForFraction(range.fractionOf(b.center, now));
      final top = geometry.yForValue(b.high);
      final bot = geometry.yForValue(b.low);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, bot),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, Paint()..color = HlthChartTokens.hr);
      // Active-zone cap in green.
      if (b.hasPeak) {
        final capH = math.min(barWidth * 1.4, (bot - top));
        final cap = RRect.fromRectAndRadius(
          Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, top + capH),
          Radius.circular(barWidth / 2),
        );
        canvas.drawRRect(cap, Paint()..color = HlthChartTokens.hrAccent);
      }
    }

    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_HrRangePainter old) => old.buckets != buckets;
}
