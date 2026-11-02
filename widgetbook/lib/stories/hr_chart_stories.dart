import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Chart card', type: HrPlot)
Widget hrCard(BuildContext context) {
  final status = context.knobs.list<ChartStatus>(
    label: 'Status',
    options: ChartStatus.values,
    initialOption: ChartStatus.data,
    labelBuilder: (s) => s.name,
  );
  return _frame(_HrCard(status: status));
}

class _HrCard extends StatefulWidget {
  const _HrCard({required this.status});
  final ChartStatus status;
  @override
  State<_HrCard> createState() => _HrCardState();
}

class _HrCardState extends State<_HrCard> {
  TimeRange _range = TimeRange.day;

  @override
  Widget build(BuildContext context) {
    final data = windowed(hrData, storyNow, _range, (r) => r.timestamp);
    return MetricChartCard(
      headerLabel: 'Resting heart rate',
      value: data.isEmpty
          ? null
          : data.map((r) => r.bpm).reduce(min).round().toString(),
      unit: 'bpm',
      rangeCaption: _range.rangeCaption(storyNow),
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      status: widget.status,
      accent: HlthChartTokens.hr,
      legend: const [
        LegendItem(label: 'Heart rate', color: HlthChartTokens.hr),
        LegendItem(label: 'Active zone', color: HlthChartTokens.hrAccent),
      ],
      plot: HrPlot(
        readings: hrData,
        now: storyNow,
        range: _range,
        onZoom: (d) => setState(() => _range = stepRange(_range, d)),
      ),
    );
  }
}

Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
