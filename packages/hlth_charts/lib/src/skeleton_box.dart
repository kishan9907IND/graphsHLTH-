import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// Shimmering placeholder that mimics a chart's final shape. Prevents the
/// card from reflowing when real data arrives — reserve the space now,
/// animate a subtle sweep so the user knows something is coming.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.height,
    this.width,
  });

  final BorderRadius borderRadius;
  final double? height;
  final double? width;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.0 + 2.0 * t, 0),
                end: Alignment(1.0 + 2.0 * t, 0),
                colors: const [
                  HlthChartTokens.cardSurfaceHigh,
                  Color(0xFF2E2E36),
                  HlthChartTokens.cardSurfaceHigh,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Container(color: HlthChartTokens.cardSurfaceHigh),
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton that mimics a line/area chart: a wavy strip near the bottom
/// plus a short label stub at the top-left. Picked over a plain rectangle
/// because the layout stays stable once the real chart renders in place.
class ChartSkeletonBody extends StatelessWidget {
  const ChartSkeletonBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(
          width: 80,
          height: 14,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SkeletonBox(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
