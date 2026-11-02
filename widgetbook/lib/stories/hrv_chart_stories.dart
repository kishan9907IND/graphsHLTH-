import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

// One use-case per MEANINGFUL STATE, not per screen.
//
// The populated stories expose the TimeRange knob so a designer can flip
// between 3D and 7D in the review and watch the axis + density update.

@widgetbook.UseCase(name: 'Loading', type: HrvChart)
Widget hrvLoading(BuildContext context) =>
    _card(const HrvChartLive(state: ChartState.loading()));

@widgetbook.UseCase(name: 'Skeleton', type: HrvChart)
Widget hrvSkeleton(BuildContext context) =>
    _card(const HrvChartLive(state: ChartState.skeleton()));

@widgetbook.UseCase(name: 'Empty — first launch', type: HrvChart)
Widget hrvEmpty(BuildContext context) => _card(
      const HrvChartLive(
        state: ChartState.empty(
          message: 'Wear your device overnight to see your HRV baseline.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Partial — gaps in the week', type: HrvChart)
Widget hrvPartial(BuildContext context) {
  final range = _rangeKnob(context);
  return _card(
    HrvChartLive(
      state: ChartState.data(
          withGaps(syntheticHrv(days: range.days + 1))),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Full — populated', type: HrvChart)
Widget hrvFull(BuildContext context) {
  final range = _rangeKnob(context);
  final band = context.knobs.boolean(
    label: 'Baseline band',
    initialValue: true,
  );
  return _card(
    HrvChartLive(
      state: ChartState.data(syntheticHrv(days: range.days + 1)),
      range: range,
      showBaselineBand: band,
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: HrvChart)
Widget hrvError(BuildContext context) => _card(
      const HrvChartLive(
        state: ChartState.error(message: "Couldn't load HRV data."),
      ),
    );

/// A tiny host that re-renders the chart when the range knob changes,
/// wrapped in the standard ChartCard so every story sees the real chrome.
class HrvChartLive extends StatelessWidget {
  const HrvChartLive({
    super.key,
    required this.state,
    this.range = TimeRange.sevenDays,
    this.showBaselineBand = true,
  });
  final ChartState<HrvReading> state;
  final TimeRange range;
  final bool showBaselineBand;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'HRV',
      subtitle: 'Last ${range.days} Day',
      icon: Icons.favorite_border,
      iconColor: HlthChartTokens.hrv,
      child: HrvChart(
        state: state,
        now: storyNow,
        range: range,
        showBaselineBand: showBaselineBand,
      ),
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
