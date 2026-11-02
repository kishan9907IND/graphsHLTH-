import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Chart card', type: Spo2Plot)
Widget spo2Card(BuildContext context) {
  final status = context.knobs.list<ChartStatus>(
    label: 'Status',
    options: ChartStatus.values,
    initialOption: ChartStatus.data,
    labelBuilder: (s) => s.name,
  );
  return _frame(_Spo2Card(status: status));
}

class _Spo2Card extends StatefulWidget {
  const _Spo2Card({required this.status});
  final ChartStatus status;
  @override
  State<_Spo2Card> createState() => _Spo2CardState();
}

class _Spo2CardState extends State<_Spo2Card> {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final data = windowed(spo2Data, storyNow, _range, (r) => r.timestamp);
    return MetricChartCard(
      headerLabel: 'Average SpO₂',
      value: data.isEmpty
          ? null
          : meanOf(data.map((r) => r.percent)).round().toString(),
      unit: '%',
      rangeCaption: _range.rangeCaption(storyNow),
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      status: widget.status,
      accent: HlthChartTokens.spo2,
      legend: const [
        LegendItem(label: 'SpO₂', color: HlthChartTokens.spo2),
        LegendItem(
            label: 'Healthy range',
            color: HlthChartTokens.spo2,
            swatch: LegendSwatch.band),
      ],
      plot: Spo2Plot(
        readings: spo2Data,
        now: storyNow,
        range: _range,
        onZoom: (d) => setState(() => _range = stepRange(_range, d)),
      ),
    );
  }
}

Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
