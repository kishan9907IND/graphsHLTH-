import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Loading', type: StressChart)
Widget stressLoading(BuildContext context) =>
    _card(const _StressChartLive(state: ChartState.loading()));

@widgetbook.UseCase(name: 'Skeleton', type: StressChart)
Widget stressSkeleton(BuildContext context) =>
    _card(const _StressChartLive(state: ChartState.skeleton()));

@widgetbook.UseCase(name: 'Empty', type: StressChart)
Widget stressEmpty(BuildContext context) => _card(
      const _StressChartLive(
        state: ChartState.empty(
          message:
              'Stress tracking needs 24h of wear to produce a baseline.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Partial — gaps', type: StressChart)
Widget stressPartial(BuildContext context) {
  final range = _rangeKnob(context);
  return _card(
    _StressChartLive(
      state: ChartState.data(
          withGaps(syntheticStress(days: range.days))),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Full — populated', type: StressChart)
Widget stressFull(BuildContext context) {
  final range = _rangeKnob(context);
  return _card(
    _StressChartLive(
      state: ChartState.data(syntheticStress(days: range.days)),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: StressChart)
Widget stressError(BuildContext context) => _card(
      const _StressChartLive(
        state: ChartState.error(message: "Couldn't load stress data."),
      ),
    );

class _StressChartLive extends StatelessWidget {
  const _StressChartLive({
    required this.state,
    this.range = TimeRange.sevenDays,
  });
  final ChartState<StressReading> state;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Stress',
      subtitle: 'Last ${range.days} Day',
      icon: Icons.self_improvement,
      iconColor: HlthChartTokens.stress,
      child: StressChart(state: state, now: storyNow, range: range),
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
