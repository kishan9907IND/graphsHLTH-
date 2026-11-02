import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

// Sleep is one night — the Range Switch shows but the hypnogram is the same
// night regardless (a multi-night summary is a separate component).
@widgetbook.UseCase(name: 'Chart card', type: SleepPlot)
Widget sleepCard(BuildContext context) {
  final status = context.knobs.list<ChartStatus>(
    label: 'Status',
    options: ChartStatus.values,
    initialOption: ChartStatus.data,
    labelBuilder: (s) => s.name,
  );
  return _frame(_SleepCard(status: status));
}

class _SleepCard extends StatefulWidget {
  const _SleepCard({required this.status});
  final ChartStatus status;
  @override
  State<_SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<_SleepCard> {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final totalMin =
        sleepData.fold<int>(0, (s, seg) => s + seg.duration.inMinutes);
    return MetricChartCard(
      headerLabel: 'Time asleep',
      value: '${totalMin ~/ 60}h ${totalMin % 60}m',
      unit: '',
      rangeCaption: 'Last night',
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      status: widget.status,
      accent: HlthChartTokens.sleepRem,
      legend: const [
        LegendItem(label: 'Deep', color: HlthChartTokens.sleepDeep),
        LegendItem(label: 'Light', color: HlthChartTokens.sleepLight),
        LegendItem(label: 'REM', color: HlthChartTokens.sleepRem),
        LegendItem(label: 'Awake', color: HlthChartTokens.sleepAwake),
      ],
      plot: SleepPlot(segments: sleepData),
    );
  }
}

Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
