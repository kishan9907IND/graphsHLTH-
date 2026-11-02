import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

// Sleep doesn't have a 3d/7d toggle in the same way — one card = one night.
// Three/seven day summaries would be a different component (a sleep ring
// row, or a stacked-duration bar). Not building that yet.

@widgetbook.UseCase(name: 'Loading', type: SleepChart)
Widget sleepLoading(BuildContext context) =>
    _card(const _SleepLive(state: ChartState.loading()));

@widgetbook.UseCase(name: 'Skeleton', type: SleepChart)
Widget sleepSkeleton(BuildContext context) =>
    _card(const _SleepLive(state: ChartState.skeleton()));

@widgetbook.UseCase(name: 'Empty', type: SleepChart)
Widget sleepEmpty(BuildContext context) => _card(
      const _SleepLive(
        state: ChartState.empty(
          message: 'No sleep tracked last night.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Partial — fragmented night', type: SleepChart)
Widget sleepPartial(BuildContext context) => _card(
      _SleepLive(
        state: ChartState.data(withGaps(syntheticSleep())),
      ),
    );

@widgetbook.UseCase(name: 'Full — healthy night', type: SleepChart)
Widget sleepFull(BuildContext context) => _card(
      _SleepLive(state: ChartState.data(syntheticSleep())),
    );

@widgetbook.UseCase(name: 'Error', type: SleepChart)
Widget sleepError(BuildContext context) => _card(
      const _SleepLive(
        state: ChartState.error(message: "Couldn't load sleep data."),
      ),
    );

class _SleepLive extends StatelessWidget {
  const _SleepLive({required this.state});
  final ChartState<SleepSegment> state;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Sleep Quality',
      subtitle: 'Last night',
      icon: Icons.bedtime,
      iconColor: HlthChartTokens.sleepRem,
      child: SleepChart(state: state),
    );
  }
}

Widget _card(Widget child) => Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    );
