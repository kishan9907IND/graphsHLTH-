import 'package:flutter/material.dart';

import 'chart_state.dart';

/// Scaffold only — enough to make every story render so you can start the
/// design conversation today. The real drawing (baseline band, scrub
/// handle, snap behaviour) is the work that follows.
class HrvChart extends StatelessWidget {
  const HrvChart({
    super.key,
    required this.state,
    this.showBaselineBand = true,
    this.baselineWindowDays = 7,
    this.snapScrubToDatapoint = true,
  });

  final ChartState<HrvReading> state;
  final bool showBaselineBand;
  final int baselineWindowDays;
  final bool snapScrubToDatapoint;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ChartLoading() => const _Skeleton(),
      ChartEmpty(:final message) => _Message(message, icon: Icons.nightlight),
      ChartError(:final message) =>
        _Message(message, icon: Icons.error_outline),
      ChartData(:final readings) when readings.isEmpty =>
        _Message('No readings.', icon: Icons.nightlight),
      ChartData(:final readings) => _Plot(
          readings: readings,
          showBaselineBand: showBaselineBand && readings.length >= 3,
          baselineWindowDays: baselineWindowDays,
          snapScrubToDatapoint: snapScrubToDatapoint,
        ),
    };
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: scheme.outline),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder plot. Swap the body for fl_chart or a CustomPainter once the
/// visual direction is agreed — the surrounding states do not change.
class _Plot extends StatelessWidget {
  const _Plot({
    required this.readings,
    required this.showBaselineBand,
    required this.baselineWindowDays,
    required this.snapScrubToDatapoint,
  });

  final List<HrvReading> readings;
  final bool showBaselineBand;
  final int baselineWindowDays;
  final bool snapScrubToDatapoint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '${readings.length} readings\n'
          'baseline band: $showBaselineBand (${baselineWindowDays}d)\n'
          'snap scrub: $snapScrubToDatapoint',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
