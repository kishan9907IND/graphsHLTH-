import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// One use-case per MEANINGFUL STATE, not per screen.
//
// "Empty — first launch" and "Empty — sensor disconnected" look identical
// today. They are still separate entries, because the moment someone decides
// one of them should say something different, the catalog already has a slot
// for it. Organise by state and the discussion stays about behaviour.

@widgetbook.UseCase(name: 'Loading', type: HrvChart)
Widget hrvLoading(BuildContext context) => _frame(
      const HrvChart(state: ChartState.loading()),
    );

@widgetbook.UseCase(name: 'Empty — first launch', type: HrvChart)
Widget hrvEmptyFirstLaunch(BuildContext context) => _frame(
      const HrvChart(
        state: ChartState.empty(
          message: 'Wear your device overnight to see your HRV baseline.',
        ),
      ),
    );

@widgetbook.UseCase(name: 'Empty — sensor disconnected', type: HrvChart)
Widget hrvEmptyDisconnected(BuildContext context) => _frame(
      const HrvChart(
        state: ChartState.empty(
          message: 'No readings since Tuesday. Check your device connection.',
        ),
      ),
    );

/// The awkward one. A single point has no trend, no baseline, no band.
/// Decide here what the axis does rather than discovering it in production.
@widgetbook.UseCase(name: 'Single datapoint', type: HrvChart)
Widget hrvSinglePoint(BuildContext context) => _frame(
      HrvChart(
        state: ChartState.data([
          HrvReading(DateTime(2026, 11, 1), 48),
        ]),
      ),
    );

@widgetbook.UseCase(name: 'Sparse — gaps in the week', type: HrvChart)
Widget hrvSparse(BuildContext context) => _frame(
      HrvChart(
        state: ChartState.data([
          HrvReading(DateTime(2026, 10, 26), 52),
          HrvReading(DateTime(2026, 10, 27), 47),
          // deliberate three-day gap
          HrvReading(DateTime(2026, 10, 31), 61),
          HrvReading(DateTime(2026, 11, 1), 58),
        ]),
      ),
    );

@widgetbook.UseCase(name: 'Populated — 30 days', type: HrvChart)
Widget hrvPopulated(BuildContext context) {
  // Knobs are the live-toggle drawer. During a review, drag these instead
  // of arguing in the abstract about whether the band is too tight.
  final showBaseline = context.knobs.boolean(
    label: 'Show baseline band',
    initialValue: true,
  );
  final baselineDays = context.knobs.int.slider(
    label: 'Baseline window (days)',
    initialValue: 7,
    min: 3,
    max: 14,
  );
  final snapToPoint = context.knobs.boolean(
    label: 'Scrub snaps to datapoint',
    initialValue: true,
  );

  return _frame(
    HrvChart(
      state: ChartState.data(_syntheticMonth()),
      showBaselineBand: showBaseline,
      baselineWindowDays: baselineDays,
      snapScrubToDatapoint: snapToPoint,
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: HrvChart)
Widget hrvError(BuildContext context) => _frame(
      const HrvChart(
        state: ChartState.error(message: "Couldn't load HRV data."),
      ),
    );

/// Every story sits in the same padded card so comparisons across states
/// are honest. Differences you see are the component, not the frame.
Widget _frame(Widget child) => Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(height: 220, child: child),
    );

List<HrvReading> _syntheticMonth() {
  final rng = Random(7); // fixed seed — stories must be deterministic
  final start = DateTime(2026, 10, 3);
  return List.generate(30, (i) {
    final drift = 50 + sin(i / 4) * 6;
    return HrvReading(
      start.add(Duration(days: i)),
      drift + rng.nextDouble() * 8 - 4,
    );
  });
}
