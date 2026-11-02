import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The card that sits below the chart — "Active heart rate · Today" with
/// Median / High columns, or Resting / Low / High for other metrics. This
/// is the "Lows and Highs or Resting or other parameter space" the format
/// reserves. Each metric supplies its own stat set; the layout is fixed so
/// the card reads the same across the dashboard.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.stats,
    this.caption,
  });

  final String title;
  final List<MetricStat> stats;

  /// e.g. "Heart rate above your resting baseline".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: HlthChartText.cardTitle),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final stat in stats)
                Expanded(child: _StatColumn(stat: stat)),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 14),
            Text(caption!, style: HlthChartText.cardSubtitle),
          ],
        ],
      ),
    );
  }
}

class MetricStat {
  const MetricStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat});
  final MetricStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(stat.label, style: HlthChartText.cardSubtitle),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              stat.value,
              style: HlthChartText.metricPrimary.copyWith(fontSize: 26),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(stat.unit, style: HlthChartText.metricSuffix),
            ),
          ],
        ),
      ],
    );
  }
}
