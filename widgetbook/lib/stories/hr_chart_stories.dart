import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Loading', type: HrChart)
Widget hrLoading(BuildContext context) =>
    _card(const _HrChartLive(state: ChartState.loading()));

@widgetbook.UseCase(name: 'Skeleton', type: HrChart)
Widget hrSkeleton(BuildContext context) =>
    _card(const _HrChartLive(state: ChartState.skeleton()));

@widgetbook.UseCase(name: 'Empty', type: HrChart)
Widget hrEmpty(BuildContext context) => _card(
      const _HrChartLive(
        state: ChartState.empty(
          message: 'Put your watch back on to see your heart rate.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Partial — gaps', type: HrChart)
Widget hrPartial(BuildContext context) {
  final range = _rangeKnob(context);
  final points = range == TimeRange.sevenDays ? 96 * 7 : 96 * 3;
  return _card(
    _HrChartLive(
      state: ChartState.data(withGaps(syntheticHr(points: points))),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Full — populated', type: HrChart)
Widget hrFull(BuildContext context) {
  final range = _rangeKnob(context);
  final points = range == TimeRange.sevenDays ? 96 * 7 : 96 * 3;
  return _card(
    _HrChartLive(
      state: ChartState.data(syntheticHr(points: points)),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: HrChart)
Widget hrError(BuildContext context) => _card(
      const _HrChartLive(
        state: ChartState.error(message: "Couldn't load heart-rate data."),
      ),
    );

class _HrChartLive extends StatelessWidget {
  const _HrChartLive({required this.state, this.range = TimeRange.sevenDays});
  final ChartState<HrReading> state;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Heart Rate',
      subtitle: 'Last ${range.days} Day',
      icon: Icons.favorite,
      iconColor: HlthChartTokens.hr,
      child: HrChart(state: state, now: storyNow, range: range),
    );
  }
}

TimeRange _rangeKnob(BuildContext context) {
  final sevenDays = context.knobs.boolean(
    label: 'Seven days (off = three)',
    initialValue: true,
  );
  return sevenDays ? TimeRange.sevenDays : TimeRange.threeDays;
}

Widget _card(Widget child) => Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    );
