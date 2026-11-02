import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

/// One interactive use-case: the Status knob switches between
/// data/loading/skeleton/empty/error/permission-off; the Range Switch tabs
/// (and pinch) change 1D/1W/1M/3M live.
@widgetbook.UseCase(name: 'Chart card', type: HrvPlot)
Widget hrvCard(BuildContext context) {
  final status = context.knobs.list<ChartStatus>(
    label: 'Status',
    options: ChartStatus.values,
    initialOption: ChartStatus.data,
    labelBuilder: (s) => s.name,
  );
  return _frame(_HrvCard(status: status));
}

class _HrvCard extends StatefulWidget {
  const _HrvCard({required this.status});
  final ChartStatus status;
  @override
  State<_HrvCard> createState() => _HrvCardState();
}

class _HrvCardState extends State<_HrvCard> {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final data = windowed(hrvData, storyNow, _range, (r) => r.timestamp);
    return MetricChartCard(
      headerLabel: 'Average HRV',
      value: data.isEmpty
          ? null
          : meanOf(data.map((r) => r.milliseconds)).round().toString(),
      unit: 'ms',
      rangeCaption: _range.rangeCaption(storyNow),
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      status: widget.status,
      accent: HlthChartTokens.hrv,
      legend: const [
        LegendItem(label: 'HRV', color: HlthChartTokens.hrv),
        LegendItem(
            label: 'Baseline band',
            color: HlthChartTokens.hrv,
            swatch: LegendSwatch.band),
      ],
      plot: HrvPlot(
        readings: hrvData,
        now: storyNow,
        range: _range,
        onZoom: (d) => setState(() => _range = stepRange(_range, d)),
      ),
    );
  }
}

Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
