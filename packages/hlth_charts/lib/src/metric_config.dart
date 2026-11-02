import 'package:flutter/widgets.dart';

import 'chart_legend.dart';
import 'metric_chart_card.dart';
import 'scrub_overlay.dart';
import 'stats_card.dart';
import 'time_range.dart';

/// Everything the one unified screen needs to render a single metric. Swap
/// the view model and the same [MetricScreen] shows a different metric in
/// the identical format — this is the "one format, charts changed across"
/// contract.
///
/// The per-range fields are callbacks because the header value, the status
/// and the plot all change when the user switches 1D/1W/1M/3M.
class MetricViewModel {
  const MetricViewModel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.headerLabel,
    required this.unit,
    required this.legend,
    required this.headerValue,
    required this.statusFor,
    required this.plotBuilder,
    required this.statsFor,
    this.insightFor,
    this.cta,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Wear your band to start seeing this chart.',
  });

  /// App-bar title, e.g. "Heart Rate".
  final String title;
  final IconData icon;
  final Color accent;

  /// Header label above the big number, e.g. "Resting heart rate".
  final String headerLabel;
  final String unit;
  final List<LegendItem> legend;

  /// The big number for a given range, or null for the "– –" treatment.
  final String? Function(TimeRange range) headerValue;

  final ChartStatus Function(TimeRange range) statusFor;

  /// Builds the plot for a range. [onZoom] is wired to pinch-to-zoom so the
  /// plot can ask the screen to step the range in/out.
  final Widget Function(TimeRange range, ValueChanged<ZoomDirection>? onZoom)
      plotBuilder;

  /// The stats card below the chart (Median/High/Resting/Low…) per range.
  final StatsSpec Function(TimeRange range) statsFor;

  /// Optional one-line insight pill for a range.
  final String? Function(TimeRange range)? insightFor;

  /// Optional live-action CTA ("Live heart rate / Tap to check now").
  final CtaSpec? cta;

  final String emptyTitle;
  final String emptySubtitle;
}

/// Data for the stats card below the chart.
class StatsSpec {
  const StatsSpec({required this.title, required this.stats, this.caption});
  final String title;
  final List<MetricStat> stats;
  final String? caption;
}

/// Data for the live-action CTA card.
class CtaSpec {
  const CtaSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
}
