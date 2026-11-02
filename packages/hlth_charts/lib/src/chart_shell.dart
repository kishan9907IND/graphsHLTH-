import 'package:flutter/material.dart';

import 'chart_state.dart';
import 'chart_theme.dart';
import 'skeleton_box.dart';

/// The one state switch every chart in the package shares. If HRV draws
/// its own empty placeholder and SpO2 draws another, the dashboard reads
/// as five separate systems — route all five chart widgets through here.
class ChartShell<T> extends StatelessWidget {
  const ChartShell({
    super.key,
    required this.state,
    required this.accent,
    required this.emptyIcon,
    required this.dataBuilder,
  });

  final ChartState<T> state;
  final Color accent;
  final IconData emptyIcon;
  final Widget Function(BuildContext context, ChartData<T> data) dataBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ChartLoading() => _CompactSpinner(accent: accent),
      ChartSkeleton() => const ChartSkeletonBody(),
      ChartEmpty(:final message) =>
        _Message(text: message, icon: emptyIcon),
      ChartError(:final message) =>
        _Message(text: message, icon: Icons.error_outline),
      ChartData<T> data when data.isEmpty =>
        _Message(text: 'No readings.', icon: emptyIcon),
      ChartData<T> data => dataBuilder(context, data),
    };
  }
}

class _CompactSpinner extends StatelessWidget {
  const _CompactSpinner({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(accent),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: HlthChartTokens.textSecondary),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: HlthChartText.cardSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
