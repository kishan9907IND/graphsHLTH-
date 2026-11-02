import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';

/// Direction a pinch gesture resolves to. Pinch-out (fingers apart) drills
/// *in* to a shorter range (3M → 1M → 1W → 1D); pinch-in zooms back out.
enum ZoomDirection { inward, outward }

/// Shared touch layer for the line/area/bar charts. Handles the three
/// mobile gestures the brief calls for, all through one scale recogniser
/// (a pan and a pinch can't live in separate GestureDetectors on the same
/// box — scale subsumes pan):
///
///   - **Tap**  — scale start+end with no travel: selects the nearest point.
///   - **Drag** — one finger moving: the selection follows, snapping to the
///                nearest datapoint with a haptic click on each new point.
///   - **Pinch**— two fingers: once the scale crosses a threshold, fires
///                [onZoom] once so the host can change the range tab.
///
/// Mouse hover is deliberately absent — a value that only appears on hover
/// reads wrong on a tablet and doesn't exist on a phone.
class ScrubOverlay extends StatefulWidget {
  const ScrubOverlay({
    super.key,
    required this.points,
    required this.builder,
    this.accent = HlthChartTokens.hrv,
    this.onZoom,
    this.clearDelay = const Duration(seconds: 2),
  });

  final List<ScrubPoint> points;
  final Widget Function(BuildContext context, Size size) builder;
  final Color accent;

  /// Called once per pinch gesture when the scale crosses the threshold.
  /// Null disables pinch-to-zoom for this chart.
  final ValueChanged<ZoomDirection>? onZoom;

  final Duration clearDelay;

  @override
  State<ScrubOverlay> createState() => _ScrubOverlayState();
}

class _ScrubOverlayState extends State<ScrubOverlay> {
  int? _selectedIndex;
  bool _zoomFiredThisGesture = false;
  int _pointerCount = 0;

  void _selectFromDx(double dx) {
    if (widget.points.isEmpty) return;
    var best = 0;
    var bestDistance = double.infinity;
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
      if (_selectedIndex == at) setState(() => _selectedIndex = null);
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
          onScaleStart: (details) {
            _zoomFiredThisGesture = false;
            _pointerCount = details.pointerCount;
            if (details.pointerCount == 1) {
              _selectFromDx(details.localFocalPoint.dx);
            }
          },
          onScaleUpdate: (details) {
            _pointerCount = details.pointerCount;
            if (details.pointerCount >= 2) {
              if (widget.onZoom == null || _zoomFiredThisGesture) return;
              if (details.scale > 1.3) {
                _zoomFiredThisGesture = true;
                HapticFeedback.mediumImpact();
                widget.onZoom!(ZoomDirection.inward);
              } else if (details.scale < 0.77) {
                _zoomFiredThisGesture = true;
                HapticFeedback.mediumImpact();
                widget.onZoom!(ZoomDirection.outward);
              }
            } else {
              _selectFromDx(details.localFocalPoint.dx);
            }
          },
          onScaleEnd: (_) {
            if (_pointerCount < 2) _clearAfterDelay();
          },
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
    const badgeWidth = 80.0;
    return (dotX - badgeWidth / 2).clamp(0.0, width - badgeWidth);
  }
}

/// A datapoint known to the scrub layer. [x]/[y] are chart-local pixels,
/// [label] is the formatted value for the badge.
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
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = HlthChartTokens.textPrimary.withOpacity(0.25)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(x, point.y),
      10,
      Paint()
        ..color = HlthChartTokens.scrubDotShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
        Offset(x, point.y), 6, Paint()..color = HlthChartTokens.scrubDot);
    canvas.drawCircle(
      Offset(x, point.y),
      6,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HlthChartText.axisLabel.copyWith(
          color: HlthChartTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
