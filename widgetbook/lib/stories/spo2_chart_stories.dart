import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '_synthetic.dart';

@widgetbook.UseCase(name: 'Loading', type: Spo2Chart)
Widget spo2Loading(BuildContext context) =>
    _card(const _Spo2Live(state: ChartState.loading()));

@widgetbook.UseCase(name: 'Skeleton', type: Spo2Chart)
Widget spo2Skeleton(BuildContext context) =>
    _card(const _Spo2Live(state: ChartState.skeleton()));

@widgetbook.UseCase(name: 'Empty', type: Spo2Chart)
Widget spo2Empty(BuildContext context) => _card(
      const _Spo2Live(
        state: ChartState.empty(
          message:
              'Sleep with your device on for 3 nights to see your SpO₂ trend.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Partial — gaps', type: Spo2Chart)
Widget spo2Partial(BuildContext context) {
  final range = _rangeKnob(context);
  return _card(
    _Spo2Live(
      state: ChartState.data(withGaps(syntheticSpo2(days: range.days))),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Full — populated', type: Spo2Chart)
Widget spo2Full(BuildContext context) {
  final range = _rangeKnob(context);
  return _card(
    _Spo2Live(
      state: ChartState.data(syntheticSpo2(days: range.days)),
      range: range,
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: Spo2Chart)
Widget spo2Error(BuildContext context) => _card(
      const _Spo2Live(
        state: ChartState.error(message: "Couldn't load SpO₂ data."),
      ),
    );

class _Spo2Live extends StatelessWidget {
  const _Spo2Live({required this.state, this.range = TimeRange.sevenDays});
  final ChartState<Spo2Reading> state;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'SpO₂',
      subtitle: 'Last ${range.days} Day',
      icon: Icons.air,
      iconColor: HlthChartTokens.spo2,
      child: Spo2Chart(state: state, now: storyNow, range: range),
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
