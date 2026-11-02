import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chart_shell.dart';
import '../chart_state.dart';
import '../chart_theme.dart';
import '../readings/sleep_segment.dart';

/// Hypnogram. Each night is a list of [SleepSegment]s and each segment
/// paints as a vertical bar whose height encodes its stage (deep lowest,
/// awake highest). This is the Sleep Quality card from the Figma.
///
/// Sleep is categorical — a scrub-value overlay would need to show a
/// stage label, so we handle its own touch rather than reuse ScrubOverlay.
class SleepChart extends StatefulWidget {
  const SleepChart({
    super.key,
    required this.state,
  });

  final ChartState<SleepSegment> state;

  @override
  State<SleepChart> createState() => _SleepChartState();
}

class _SleepChartState extends State<SleepChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return ChartShell<SleepSegment>(
      state: widget.state,
      accent: HlthChartTokens.sleepRem,
      emptyIcon: Icons.bedtime_outlined,
      dataBuilder: (context, data) {
        final segments = [...data.readings]
          ..sort((a, b) => a.start.compareTo(b.start));
        if (segments.isEmpty) {
          return const Center(
            child: Text(
              'No sleep recorded for this window.',
              style: HlthChartText.cardSubtitle,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _updateFromDx(d.localPosition.dx, size.width,
                  segments),
              onPanStart: (d) => _updateFromDx(d.localPosition.dx, size.width,
                  segments),
              onPanUpdate: (d) => _updateFromDx(
                  d.localPosition.dx, size.width, segments),
              onPanEnd: (_) => _clearAfter(),
              onTapUp: (_) => _clearAfter(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    size: size,
                    painter: _HypnogramPainter(
                      segments: segments,
                      selected: _selected,
                    ),
                  ),
                  if (_selected != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: Center(
                        child: _StageBadge(stage: segments[_selected!].stage),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateFromDx(double dx, double width, List<SleepSegment> segments) {
    final total = segments.last.end
        .difference(segments.first.start)
        .inMicroseconds
        .toDouble();
    final anchor = segments.first.start;
    final targetMicros = (dx / width) * total;
    for (var i = 0; i < segments.length; i++) {
      final startM = segments[i].start.difference(anchor).inMicroseconds;
      final endM = segments[i].end.difference(anchor).inMicroseconds;
      if (targetMicros >= startM && targetMicros <= endM) {
        if (_selected != i) {
          HapticFeedback.selectionClick();
          setState(() => _selected = i);
        }
        return;
      }
    }
  }

  void _clearAfter() {
    final at = _selected;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_selected == at) setState(() => _selected = null);
    });
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({required this.segments, required this.selected});
  final List<SleepSegment> segments;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const insetTop = 10.0;
    const insetBottom = 22.0;
    final plotTop = insetTop;
    final plotHeight = size.height - insetTop - insetBottom;
    final start = segments.first.start;
    final end = segments.last.end;
    final totalMicros = end.difference(start).inMicroseconds.toDouble();

    double xFor(DateTime t) =>
        (t.difference(start).inMicroseconds / totalMicros) * size.width;

    double heightFor(SleepStage s) {
      // Awake = 95% of plot, Deep = 25% — a visual ramp that reads
      // without a legend.
      switch (s) {
        case SleepStage.deep:
          return plotHeight * 0.30;
        case SleepStage.light:
          return plotHeight * 0.55;
        case SleepStage.rem:
          return plotHeight * 0.80;
        case SleepStage.awake:
          return plotHeight * 0.95;
      }
    }

    Color colorFor(SleepStage s) {
      switch (s) {
        case SleepStage.deep:
          return HlthChartTokens.sleepDeep;
        case SleepStage.light:
          return HlthChartTokens.sleepLight;
        case SleepStage.rem:
          return HlthChartTokens.sleepRem;
        case SleepStage.awake:
          return HlthChartTokens.sleepAwake;
      }
    }

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final left = xFor(seg.start);
      final right = xFor(seg.end);
      final h = heightFor(seg.stage);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left + 0.5, plotTop + plotHeight - h,
            (right - 0.5).clamp(left + 1, right), plotTop + plotHeight),
        const Radius.circular(2),
      );
      final paint = Paint()
        ..color = selected == i
            ? colorFor(seg.stage)
            : colorFor(seg.stage).withOpacity(0.85);
      canvas.drawRRect(rect, paint);
    }

    // Caption endpoints.
    final startLabel = _fmt(segments.first.start);
    final endLabel = _fmt(segments.last.end);
    final startTp = TextPainter(
      text: TextSpan(text: startLabel, style: HlthChartText.axisLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    final endTp = TextPainter(
      text: TextSpan(text: endLabel, style: HlthChartText.axisLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    startTp.paint(canvas, Offset(0, size.height - startTp.height));
    endTp.paint(canvas,
        Offset(size.width - endTp.width, size.height - endTp.height));
  }

  static String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour < 12 ? 'am' : 'pm';
    return '$h.$m$p';
  }

  @override
  bool shouldRepaint(_HypnogramPainter old) =>
      old.segments != segments || old.selected != selected;
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});
  final SleepStage stage;

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      SleepStage.deep => HlthChartTokens.sleepDeep,
      SleepStage.light => HlthChartTokens.sleepLight,
      SleepStage.rem => HlthChartTokens.sleepRem,
      SleepStage.awake => HlthChartTokens.sleepAwake,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        stage.label,
        style: HlthChartText.axisLabel.copyWith(
          color: HlthChartTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
