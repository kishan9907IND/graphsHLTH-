import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';

/// Shared touch-scrub layer for the line/area/bar charts.
///
/// Why this exists:
///   fl_chart's built-in touch handler is tap-centred — great on desktop,
///   wrong on mobile. On a phone you want to **drag your thumb along the
///   chart** and have the selection follow, snapping to the nearest
///   datapoint with a haptic click. That's this widget's whole job.
///
/// Behaviour:
///   - Starts invisible. A touch-down or pan-start reveals the dot.
///   - The dot snaps to the x-position of the nearest datapoint.
///   - Each snap fires a selectionClick haptic.
///   - Lifting your finger clears the selection after a short delay so
///     the value label stays readable.
///   - Minimum hit area is the full chart. The visible dot is 12pt; the
///     invisible gesture target is the whole canvas.
///   - Mouse hover is DISABLED by design — a chart that reveals a value
///     on hover reads wrong on a tablet, and on a phone there is no hover.
class ScrubOverlay extends StatefulWidget {
  const ScrubOverlay({
    super.key,
    required this.points,
    required this.builder,
    this.accent = HlthChartTokens.hrv,
    this.clearDelay = const Duration(seconds: 2),
  });

  /// Datapoint positions in local chart coordinates (x within the chart
  /// width, paired with the value to show in the badge).
  final List<ScrubPoint> points;

  /// The chart painter rendered beneath the overlay. Receives the chart
  /// size so it can lay out at the overlay's measured bounds.
  final Widget Function(BuildContext context, Size size) builder;

  final Color accent;
  final Duration clearDelay;

  @override
  State<ScrubOverlay> createState() => _ScrubOverlayState();
}

class _ScrubOverlayState extends State<ScrubOverlay> {
  int? _selectedIndex;

  void _updateFromDx(double dx, double width) {
    if (widget.points.isEmpty) return;
    int best = 0;
    double bestDistance = double.infinity;
    for (var i = 0; i < widget.points.length; i++) {
      final d = (widget.points[i].x - dx).abs();
      if (d < bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    if (best != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = best);
    }
  }

  void _clearAfterDelay() {
    final at = _selectedIndex;
    Future.delayed(widget.clearDelay, () {
      if (!mounted) return;
      if (_selectedIndex == at) {
        setState(() => _selectedIndex = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final selected =
            _selectedIndex != null ? widget.points[_selectedIndex!] : null;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _updateFromDx(details.localPosition.dx, size.width);
          },
          onTapUp: (_) => _clearAfterDelay(),
          onPanStart: (details) {
            _updateFromDx(details.localPosition.dx, size.width);
          },
          onPanUpdate: (details) {
            _updateFromDx(details.localPosition.dx, size.width);
          },
          onPanEnd: (_) => _clearAfterDelay(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.builder(context, size),
              if (selected != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScrubPainter(
                      point: selected,
                      accent: widget.accent,
                    ),
                  ),
                ),
              if (selected != null)
                Positioned(
                  left: _badgeLeft(selected.x, size.width),
                  top: 0,
                  child: _ValueBadge(
                    text: selected.label,
                    accent: widget.accent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _badgeLeft(double dotX, double width) {
    const badgeWidth = 72.0;
    final clamped = dotX - badgeWidth / 2;
    return clamped.clamp(0.0, width - badgeWidth);
  }
}

/// A datapoint known to the scrub layer. [x] is in chart-local pixels, [y]
/// is where the dot should sit vertically on the plotted series, and
/// [label] is the formatted value for the badge (e.g. "48 ms" or "07 AM").
class ScrubPoint {
  const ScrubPoint({required this.x, required this.y, required this.label});
  final double x;
  final double y;
  final String label;
}

class _ScrubPainter extends CustomPainter {
  _ScrubPainter({required this.point, required this.accent});
  final ScrubPoint point;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final x = point.x.clamp(0.0, size.width);
    final line = Paint()
      ..color = HlthChartTokens.textPrimary.withOpacity(0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);

    final shadow = Paint()
      ..color = HlthChartTokens.scrubDotShadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(x, point.y), 10, shadow);

    final dot = Paint()..color = HlthChartTokens.scrubDot;
    canvas.drawCircle(Offset(x, point.y), 6, dot);

    final ring = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(x, point.y), 6, ring);
  }

  @override
  bool shouldRepaint(_ScrubPainter old) => old.point != point;
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.5), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: HlthChartText.axisLabel.copyWith(
          color: HlthChartTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
