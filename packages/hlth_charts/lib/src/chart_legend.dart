import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// Legend row from the Chart/Card master — a colour swatch plus a label per
/// series. A solid dot means a line/point series; a soft rounded chip means
/// a band (the "Typical range").
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [for (final item in items) _LegendChip(item: item)],
    );
  }
}

enum LegendSwatch { dot, band }

class LegendItem {
  const LegendItem({
    required this.label,
    required this.color,
    this.swatch = LegendSwatch.dot,
  });

  final String label;
  final Color color;
  final LegendSwatch swatch;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.item});
  final LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (item.swatch) {
          LegendSwatch.dot => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
          LegendSwatch.band => Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.35),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: item.color.withOpacity(0.6)),
              ),
            ),
        },
        const SizedBox(width: 6),
        Text(item.label, style: HlthChartText.cardSubtitle),
      ],
    );
  }
}
