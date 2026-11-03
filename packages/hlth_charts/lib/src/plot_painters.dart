import 'package:flutter/material.dart';

import 'chart_geometry.dart';
import 'chart_theme.dart';
import 'time_range.dart';

/// Shared painting helpers so every plot draws its axis, band and series the
/// same way. A chart that hand-rolls its own axis ticks drifts from the rest
/// of the system — route through here.

void paintAxisTicks(
  Canvas canvas,
  ChartGeometry g,
  List<AxisTick> ticks,
) {
  final tickPaint = Paint()
    ..color = HlthChartTokens.axis
    ..strokeWidth = 1;
  final y = g.size.height - g.insets.bottom + 4;
  for (final tick in ticks) {
    final x = g.xForFraction(tick.fraction);
    canvas.drawLine(Offset(x, y), Offset(x, y + 3), tickPaint);
    if (tick.label.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: tick.label, style: HlthChartText.axisLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (x - tp.width / 2)
        .clamp(0.0, g.size.width - tp.width)
        .toDouble();
    tp.paint(canvas, Offset(lx, g.size.height - tp.height));
  }
}

/// Faint horizontal gridlines with value labels on the right — the Y axis
/// "numbers as required", as on the SpO₂ screen. Drawn at the given values
/// (defaults to min / mid / max of the plotted range).
void paintYGrid(
  Canvas canvas,
  ChartGeometry g, {
  List<double>? values,
  String Function(double)? format,
}) {
  final fmt = format ?? (v) => v.toStringAsFixed(0);
  final line = Paint()
    ..color = HlthChartTokens.axis.withOpacity(0.5)
    ..strokeWidth = 1;
  for (final v in values ?? [g.minY, (g.minY + g.maxY) / 2, g.maxY]) {
    final y = g.yForValue(v);
    canvas.drawLine(
      Offset(g.insets.left, y),
      Offset(g.size.width - g.insets.right, y),
      line,
    );
    final tp = TextPainter(
      text: TextSpan(text: fmt(v), style: HlthChartText.axisLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(g.size.width - g.insets.right - tp.width, y - tp.height - 1),
    );
  }
}

/// A shaded horizontal "typical/healthy range" band between two values.
void paintBand(
  Canvas canvas,
  ChartGeometry g,
  double low,
  double high,
  Color color,
) {
  final rect = Rect.fromLTRB(
    g.insets.left,
    g.yForValue(high),
    g.size.width - g.insets.right,
    g.yForValue(low),
  );
  canvas.drawRect(rect, Paint()..color = color.withOpacity(0.14));
  final edge = Paint()
    ..color = color.withOpacity(0.4)
    ..strokeWidth = 1;
  canvas.drawLine(rect.topLeft, rect.topRight, edge);
  canvas.drawLine(rect.bottomLeft, rect.bottomRight, edge);
}

/// Draw one or more contiguous runs of points as a line, optionally filling
/// the area beneath. Breaks between runs (gaps) are left blank and marked.
void paintSeries(
  Canvas canvas,
  ChartGeometry g,
  List<List<Offset>> runs,
  Color accent, {
  bool fill = true,
  bool smooth = false,
}) {
  final baseY = g.insets.top + g.plotHeight;

  if (fill) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: HlthChartTokens.areaGradient(accent),
      stops: HlthChartTokens.areaStops,
    );
    final plotRect = Rect.fromLTWH(
      g.insets.left,
      g.insets.top,
      g.plotWidth,
      g.plotHeight,
    );
    final shader = gradient.createShader(plotRect);
    for (final run in runs) {
      if (run.length < 2) continue;
      final area = Path()
        ..moveTo(run.first.dx, baseY)
        ..lineTo(run.first.dx, run.first.dy);
      if (smooth) {
        _smoothThrough(area, run);
      } else {
        for (final p in run.skip(1)) {
          area.lineTo(p.dx, p.dy);
        }
      }
      area
        ..lineTo(run.last.dx, baseY)
        ..close();
      canvas.drawPath(area, Paint()..shader = shader);
    }
  }

  final linePaint = Paint()
    ..color = accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final run in runs) {
    if (run.isEmpty) continue;
    final path = Path()..moveTo(run.first.dx, run.first.dy);
    if (smooth) {
      _smoothThrough(path, run);
    } else {
      for (final p in run.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // A lone point (sparse / single-datapoint) needs a dot or it vanishes.
    if (run.length == 1) {
      canvas.drawCircle(
          run.first, 4.5, Paint()..color = HlthChartTokens.textPrimary);
      canvas.drawCircle(run.first, 3, Paint()..color = accent);
    }
  }

  // Mark the midpoints of gaps between runs with a faint "– –".
  for (var i = 0; i < runs.length - 1; i++) {
    if (runs[i].isEmpty || runs[i + 1].isEmpty) continue;
    final midX = (runs[i].last.dx + runs[i + 1].first.dx) / 2;
    final midY = (runs[i].last.dy + runs[i + 1].first.dy) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: '– –',
        style: HlthChartText.axisLabel.copyWith(
          color: HlthChartTokens.textMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(midX - tp.width / 2, midY - tp.height / 2));
  }
}

/// Append a smooth curve through [p] to [path], which must already be at p[0].
/// Catmull-Rom spline converted to cubic Béziers — the reaviz "smooth" area
/// look. Single points are left to the caller.
void _smoothThrough(Path path, List<Offset> p) {
  if (p.length < 2) return;
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = i == 0 ? p[0] : p[i - 1];
    final p1 = p[i];
    final p2 = p[i + 1];
    final p3 = (i + 2 < p.length) ? p[i + 2] : p2;
    final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
    final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
}
