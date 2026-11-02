import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The "How your SpO₂ changed" table — one row per look-back period with a
/// signed change and a trend pill. When a metric is still building its
/// baseline, every row reads "– – pts" with a [Trend.tbd] pill.
class ChangeTable extends StatelessWidget {
  const ChangeTable({super.key, required this.title, required this.rows});

  final String title;
  final List<ChangeRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: HlthChartText.cardTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: HlthChartTokens.cardSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const _HeaderRow(),
              for (final row in rows) _DataRow(row: row),
            ],
          ),
        ),
      ],
    );
  }
}

enum Trend {
  high(label: 'High'),
  normal(label: 'Normal'),
  low(label: 'Low'),
  tbd(label: 'TBD');

  const Trend({required this.label});
  final String label;
}

class ChangeRow {
  const ChangeRow({
    required this.period,
    required this.change,
    required this.unit,
    required this.trend,
  });

  final String period;

  /// Formatted signed change, e.g. "+1", "0", "−2", or null for "– –".
  final String? change;
  final String unit;
  final Trend trend;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Period', style: HlthChartText.cardSubtitle),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Change',
              textAlign: TextAlign.center,
              style: HlthChartText.cardSubtitle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Trend',
              textAlign: TextAlign.right,
              style: HlthChartText.cardSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.row});
  final ChangeRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: HlthChartTokens.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(row.period, style: HlthChartText.cardSubtitle),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  row.change ?? '– –',
                  style: HlthChartText.cardTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(width: 3),
                Text(row.unit, style: HlthChartText.cardSubtitle),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _TrendPill(trend: row.trend),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend});
  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      Trend.high => HlthChartTokens.series,
      Trend.normal => HlthChartTokens.series,
      Trend.low => HlthChartTokens.hr,
      Trend.tbd => HlthChartTokens.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            trend.label,
            style: HlthChartText.cardSubtitle.copyWith(
              color: HlthChartTokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
