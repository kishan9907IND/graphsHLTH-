import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Chart card', type: StressPlot)
Widget stressCard(BuildContext context) {
  final status = context.knobs.list<ChartStatus>(
    label: 'Status',
    options: ChartStatus.values,
    initialOption: ChartStatus.data,
    labelBuilder: (s) => s.name,
  );
  return _frame(_StressCard(status: status));
}

class _StressCard extends StatefulWidget {
  const _StressCard({required this.status});
  final ChartStatus status;
  @override
  State<_StressCard> createState() => _StressCardState();
}

class _StressCardState extends State<_StressCard> {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final data = windowed(stressData, storyNow, _range, (r) => r.timestamp);
    return MetricChartCard(
      headerLabel: 'Average stress',
      value: data.isEmpty
          ? null
          : meanOf(data.map((r) => r.index)).round().toString(),
      unit: '',
      rangeCaption: _range.rangeCaption(storyNow),
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      status: widget.status,
      accent: HlthChartTokens.stress,
      legend: const [
        LegendItem(label: 'Stress index', color: HlthChartTokens.stress),
      ],
      plot: StressPlot(
        readings: stressData,
        now: storyNow,
        range: _range,
        onZoom: (d) => setState(() => _range = stepRange(_range, d)),
      ),
    );
  }
}

Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
