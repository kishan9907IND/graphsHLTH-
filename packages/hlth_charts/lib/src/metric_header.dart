import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The number block from the HR page: a small label, a big value with a
/// unit suffix, and a date-range caption. Optionally a sync-status line
/// ("• Syncing · last updated 2h ago").
///
/// The big value is the "numbers as shown in the HR page" — when data is
/// missing it shows the "--" treatment rather than a zero.
class MetricHeader extends StatelessWidget {
  const MetricHeader({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.rangeCaption,
    this.syncStatus,
  });

  /// e.g. "Resting heart rate".
  final String label;

  /// The formatted value, or null to show the "--" missing treatment.
  final String? value;

  /// e.g. "bpm", "ms", "%".
  final String unit;

  /// e.g. "30 Sep – 6 Oct".
  final String rangeCaption;

  /// e.g. "Syncing · last updated 2h ago". Null hides the row.
  final String? syncStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: HlthChartText.cardSubtitle),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value ?? '– –', style: HlthChartText.metricPrimary),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: HlthChartText.metricSuffix),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(rangeCaption, style: HlthChartText.cardSubtitle),
        if (syncStatus != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: HlthChartTokens.syncDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(syncStatus!, style: HlthChartText.cardSubtitle),
            ],
          ),
        ],
      ],
    );
  }
}
