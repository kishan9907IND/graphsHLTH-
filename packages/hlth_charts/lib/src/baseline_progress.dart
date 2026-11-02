import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The "building baseline" card from the SpO₂ spec ("Not enough data ·
/// building baseline"): a captured/total segmented progress bar, a short
/// headline, a check-back line, and an explanation of why a few nights
/// isn't enough yet. Shown in place of the chart while [captured] < [total].
class BaselineProgress extends StatelessWidget {
  const BaselineProgress({
    super.key,
    required this.captured,
    required this.total,
    required this.headline,
    required this.checkBack,
    required this.explanation,
    this.accent = HlthChartTokens.series,
  });

  final int captured;
  final int total;
  final String headline;
  final String checkBack;
  final String explanation;
  final Color accent;

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
          Text(
            headline,
            style: HlthChartText.cardTitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < captured
                          ? accent
                          : HlthChartTokens.cardSurfaceHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            checkBack,
            style: HlthChartText.cardSubtitle.copyWith(
              color: HlthChartTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: HlthChartText.cardSubtitle.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
