/// Chart components for the HLTH app.
///
/// The public surface, by concern:
///   - Reading models + [ChartState] are what callers construct.
///   - The five plot widgets (HrvPlot, HrPlot, StressPlot, Spo2Plot,
///     SleepPlot) render a single metric's series.
///   - [MetricChartCard] is the one unified Chart/Card format; [MetricScreen]
///     wraps it into a full phone screen driven by a [MetricViewModel], so
///     swapping the view model swaps the metric in an identical layout.
///   - [RangeSwitch], [ChartLegend], [MetricHeader], [InsightPill],
///     [InsightCta], [StatsCard] and the theme tokens are the shell pieces.
library;

// Core model + theme + ranges
export 'src/chart_state.dart';
export 'src/chart_theme.dart';
export 'src/time_range.dart' show TimeRange, AxisTick, windowed, splitOnGaps;

// Design-system primitives
export 'src/range_switch.dart';
export 'src/chart_legend.dart';
export 'src/metric_header.dart';
export 'src/insight_pill.dart';
export 'src/stats_card.dart';
export 'src/skeleton_box.dart' show SkeletonBox, ChartSkeletonBody;
export 'src/scrub_overlay.dart' show ScrubPoint, ZoomDirection;

// Unified format
export 'src/metric_chart_card.dart';
export 'src/metric_config.dart';
export 'src/metric_screen.dart';

// Reading models
export 'src/readings/hrv_reading.dart';
export 'src/readings/hr_reading.dart';
export 'src/readings/stress_reading.dart';
export 'src/readings/spo2_reading.dart';
export 'src/readings/sleep_segment.dart';

// Plot widgets
export 'src/charts/hrv_chart.dart';
export 'src/charts/hr_chart.dart';
export 'src/charts/stress_chart.dart';
export 'src/charts/spo2_chart.dart';
export 'src/charts/sleep_chart.dart';
