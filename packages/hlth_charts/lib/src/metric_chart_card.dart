import 'package:flutter/material.dart';

import 'chart_legend.dart';
import 'chart_state_body.dart';
import 'chart_theme.dart';
import 'metric_header.dart';
import 'range_switch.dart';
import 'time_range.dart';

export 'chart_state_body.dart' show ChartStatus;

/// Self-contained chart card for the Widgetbook catalog: header → Range
/// Switch → plot/state → legend, all in one dark panel. The full screen
/// composition (period navigator, change table, bottom nav) lives in
/// [MetricScreen]; this stays a compact component for per-state review.
class MetricChartCard extends StatelessWidget {
  const MetricChartCard({
    super.key,
    required this.headerLabel,
    required this.value,
    required this.unit,
    required this.rangeCaption,
    required this.range,
    required this.onRangeChanged,
    required this.status,
    required this.plot,
    required this.legend,
    this.rangeValue,
    this.statusLabel,
    this.statusColor = HlthChartTokens.series,
    this.plotHeight = 180,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Wear your band to start seeing this chart.',
    this.onRetry,
    this.onOpenSettings,
    this.accent = HlthChartTokens.hrv,
  });

  final String headerLabel;
  final String? value;
  final String unit;

  /// Uppercase caption under the value, e.g. "7-day average".
  final String rangeCaption;
  final String? rangeValue;
  final String? statusLabel;
  final Color statusColor;

  final TimeRange range;
  final ValueChanged<TimeRange> onRangeChanged;

  final ChartStatus status;
  final Widget plot;
  final List<LegendItem> legend;

  final double plotHeight;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MetricHeader(
            label: headerLabel,
            value: value,
            unit: unit,
            averageCaption: rangeCaption,
            rangeValue: rangeValue,
            statusLabel: statusLabel,
            statusColor: statusColor,
          ),
          const SizedBox(height: 14),
          RangeSwitch(value: range, onChanged: onRangeChanged),
          const SizedBox(height: 16),
          SizedBox(
            height: plotHeight,
            child: ChartStateBody(
              status: status,
              plot: plot,
              accent: accent,
              emptyTitle: emptyTitle,
              emptySubtitle: emptySubtitle,
              onRetry: onRetry,
              onOpenSettings: onOpenSettings,
            ),
          ),
          if (status == ChartStatus.data ||
              status == ChartStatus.partial) ...[
            const SizedBox(height: 12),
            ChartLegend(items: legend),
          ],
        ],
      ),
    );
  }
}
