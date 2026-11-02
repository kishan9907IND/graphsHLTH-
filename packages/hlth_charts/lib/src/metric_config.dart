import 'package:flutter/widgets.dart';

import 'change_table.dart';
import 'chart_legend.dart';
import 'chart_state_body.dart';
import 'chart_theme.dart';
import 'scrub_overlay.dart';
import 'time_range.dart';

/// Everything the one unified [MetricScreen] needs to render a single metric
/// in the SpO₂-spec format. Swap the view model → same screen, different
/// metric. Per-range fields are callbacks because the value, status, plot
/// and change table all depend on the selected 1D/7D/1M/3M range.
class MetricViewModel {
  const MetricViewModel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.headerLabel,
    required this.unit,
    required this.legend,
    required this.averageCaption,
    required this.headerValue,
    required this.statusFor,
    required this.plotBuilder,
    required this.changeTitle,
    required this.changeRows,
    this.rangeValue,
    this.statusLabel,
    this.statusColor = HlthChartTokens.series,
    this.baseline,
    this.insightFor,
    this.cta,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Wear your band to start seeing this chart.',
  });

  final String title;
  final IconData icon;
  final Color accent;

  final String headerLabel;
  final String unit;
  final List<LegendItem> legend;

  /// Uppercase caption under the big value, per range ("7-DAY AVERAGE").
  final String Function(TimeRange range) averageCaption;

  /// Big value for a range, or null for the "– –" treatment.
  final String? Function(TimeRange range) headerValue;

  /// Right-column reference range ("95–100 %"), per range. Optional.
  final String? Function(TimeRange range)? rangeValue;

  /// Right-column status pill ("Normal Range"). Static across ranges.
  final String? statusLabel;
  final Color statusColor;

  final ChartStatus Function(TimeRange range) statusFor;

  /// Builds the plot for a range and status. The status lets a metric swap
  /// in gapped data for [ChartStatus.partial] vs. the full series for
  /// [ChartStatus.data].
  final Widget Function(
    TimeRange range,
    ChartStatus status,
    ValueChanged<ZoomDirection>? onZoom,
  ) plotBuilder;

  /// "How your SpO₂ changed".
  final String changeTitle;
  final List<ChangeRow> Function(TimeRange range) changeRows;

  /// Shown instead of the chart when statusFor == buildingBaseline.
  final BaselineSpec? baseline;

  /// Optional one-line insight pill.
  final String? Function(TimeRange range)? insightFor;

  /// Optional live-action CTA.
  final CtaSpec? cta;

  final String emptyTitle;
  final String emptySubtitle;
}

/// Progress copy for the "building baseline" state.
class BaselineSpec {
  const BaselineSpec({
    required this.captured,
    required this.total,
    required this.headline,
    required this.checkBack,
    required this.explanation,
  });
  final int captured;
  final int total;
  final String headline;
  final String checkBack;
  final String explanation;
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
