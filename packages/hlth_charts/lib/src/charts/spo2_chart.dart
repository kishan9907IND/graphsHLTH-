import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_geometry.dart';
import '../chart_theme.dart';
import '../plot_painters.dart';
import '../readings/spo2_reading.dart';
import '../scrub_overlay.dart';
import '../time_range.dart';

/// Plot-only SpO₂ renderer. Matches the Figma "SpO₂ overnight" card
/// (1119:26077): cyan min–max range capsules per bucket over a healthy band,
/// with an amber "min" threshold line along the bottom. Readings are grouped
/// into buckets; a bucket with a single reading gets a small overnight spread
/// so the capsule still reads as a range.
class Spo2Plot extends StatelessWidget {
  const Spo2Plot({
    super.key,
    required this.readings,
    required this.now,
    this.range = TimeRange.week,
    this.healthyMin = 95,
    this.minThreshold = 90,
    this.onZoom,
  });

  final List<Spo2Reading> readings;
  final DateTime now;
  final TimeRange range;
  final double healthyMin;
  final double minThreshold;
  final ValueChanged<ZoomDirection>? onZoom;

  static const Color accent = HlthChartTokens.spo2;

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
    final byBucket = <int, List<Spo2Reading>>{};
    for (final r in data) {
      final idx = r.timestamp.difference(windowStart).inMicroseconds ~/ interval;
      (byBucket[idx] ??= []).add(r);
    }
    final buckets = <_Bucket>[];
    byBucket.forEach((idx, rs) {
      final pct = rs.map((r) => r.percent).toList();
      var low = pct.reduce(math.min);
      var high = pct.reduce(math.max);
      if (high - low < 1.6) {
        // Single / tight bucket: show a small overnight spread.
        final mid = (low + high) / 2;
        low = mid - 1.0;
        high = math.min(mid + 1.0, 100);
      }
      buckets.add(_Bucket(
        center: windowStart
            .add(Duration(microseconds: idx * interval + interval ~/ 2)),
        low: low,
        high: math.min(high, 100),
      ));
    });
    buckets.sort((a, b) => a.center.compareTo(b.center));

    return LayoutBuilder(
      builder: (context, c) {
        final floor = (buckets.map((b) => b.low).reduce(math.min) - 1)
            .clamp(80.0, 100.0)
            .toDouble();
        final geometry = ChartGeometry(
          size: Size(c.maxWidth, c.maxHeight),
          minY: math.min(floor, minThreshold - 1),
          maxY: 100,
          insets: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        );
        final points = [
          for (final b in buckets)
            ScrubPoint(
              x: geometry.xForFraction(range.fractionOf(b.center, now)),
              y: geometry.yForValue(b.high),
              label: '${b.low.round()}–${b.high.round()}%',
            ),
        ];
        return ScrubOverlay(
          accent: accent,
          points: points,
          onZoom: onZoom,
          builder: (_, size) => CustomPaint(
            size: size,
            painter: _Spo2Painter(
              buckets: buckets,
              geometry: geometry,
              now: now,
              range: range,
              ticks: range.axisTicks(now),
              healthyMin: healthyMin,
              minThreshold: minThreshold,
            ),
          ),
        );
      },
    );
  }
}

class _Bucket {
  _Bucket({required this.center, required this.low, required this.high});
  final DateTime center;
  final double low;
  final double high;
}

class _Spo2Painter extends CustomPainter {
  _Spo2Painter({
    required this.buckets,
    required this.geometry,
    required this.now,
    required this.range,
    required this.ticks,
    required this.healthyMin,
    required this.minThreshold,
  });

  final List<_Bucket> buckets;
  final ChartGeometry geometry;
  final DateTime now;
  final TimeRange range;
  final List<AxisTick> ticks;
  final double healthyMin;
  final double minThreshold;

  @override
  void paint(Canvas canvas, Size size) {
    paintYGrid(
      canvas,
      geometry,
      values: [100, (100 + geometry.minY) / 2, geometry.minY],
      format: (v) => v.round().toString(),
      rightLabels: false,
    );

    // Cyan min–max capsules.
    final barWidth = (geometry.plotWidth / buckets.length * 0.5)
        .clamp(4.0, 14.0)
        .toDouble();
    for (final b in buckets) {
      final x = geometry.xForFraction(range.fractionOf(b.center, now));
      final top = geometry.yForValue(b.high);
      final bot = geometry.yForValue(b.low);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, bot),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, Paint()..color = HlthChartTokens.spo2);
    }

    // Amber "min NN" threshold line along the bottom.
    final ty = geometry.yForValue(minThreshold);
    canvas.drawLine(
      Offset(geometry.insets.left, ty),
      Offset(geometry.size.width - geometry.insets.right, ty),
      Paint()
        ..color = HlthChartTokens.stressMid.withOpacity(0.9)
        ..strokeWidth = 1.5,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'min ${minThreshold.round()}',
        style: HlthChartText.axisLabel
            .copyWith(color: HlthChartTokens.stressMid),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(geometry.size.width - geometry.insets.right - tp.width,
          ty - tp.height - 1),
    );

    paintAxisTicks(canvas, geometry, ticks);
  }

  @override
  bool shouldRepaint(_Spo2Painter old) => old.buckets != buckets;
}
