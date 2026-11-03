import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The two-column number block from the SpO₂ screen. Left: a small label,
/// the big value with a unit, and an uppercase average caption ("WEEKLY
/// AVERAGE"). Right: the reference range ("95–100 %") and a status pill
/// ("● Normal Range").
///
/// Missing data shows the "– –" treatment in place of the value.
class MetricHeader extends StatelessWidget {
  const MetricHeader({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.averageCaption,
    this.rangeValue,
    this.rangeCaption,
    this.statusLabel,
    this.statusColor = HlthChartTokens.series,
  });

  /// e.g. "SpO2".
  final String label;

  /// The formatted value, or null for the "– –" missing treatment.
  final String? value;

  /// e.g. "%", "bpm", "ms".
  final String unit;

  /// Small uppercase caption under the value, e.g. "WEEKLY AVERAGE" or
  /// "3 OF 7 NIGHTS CAPTURED".
  final String averageCaption;

  /// Right-column reference range, e.g. "95–100 %". Null hides the column.
  final String? rangeValue;

  /// Small label above the right-column value, e.g. "7-day baseline". Null
  /// shows the value with no caption.
  final String? rangeCaption;

  /// Right-column status pill text, e.g. "Normal Range". Null hides the pill.
  final String? statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
              const SizedBox(height: 6),
              Text(
                averageCaption.toUpperCase(),
                style: HlthChartText.axisLabel.copyWith(letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        if (rangeValue != null || statusLabel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rangeCaption != null) ...[
                Text(rangeCaption!, style: HlthChartText.cardSubtitle),
                const SizedBox(height: 4),
              ],
              if (rangeValue != null)
                Text(
                  rangeValue!,
                  style: HlthChartText.cardTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (statusLabel != null) ...[
                const SizedBox(height: 8),
                _StatusPill(label: statusLabel!, color: statusColor),
              ],
            ],
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: HlthChartText.cardSubtitle.copyWith(
              color: HlthChartTokens.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
