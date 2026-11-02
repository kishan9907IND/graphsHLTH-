/// Chart components for the HLTH app.
///
/// Public surface is split by concern:
///   - [ChartState] + the reading models are what callers construct.
///   - The five chart widgets (HrvChart, HrChart, StressChart, Spo2Chart,
///     SleepChart) are what they render.
///   - [ChartCard], [TimeRangeToggle], the theme tokens and [TimeRange] are
///     the dashboard-shell pieces a host screen composes around them.
library hlth_charts;

// Core state + layout primitives
export 'src/chart_state.dart';
export 'src/chart_card.dart';
export 'src/chart_shell.dart';
export 'src/chart_theme.dart';
export 'src/scrub_overlay.dart' show ScrubPoint;
export 'src/skeleton_box.dart' show SkeletonBox, ChartSkeletonBody;
export 'src/time_range.dart';
export 'src/time_range_toggle.dart';

// Reading models
export 'src/readings/hrv_reading.dart';
export 'src/readings/hr_reading.dart';
export 'src/readings/stress_reading.dart';
export 'src/readings/spo2_reading.dart';
export 'src/readings/sleep_segment.dart';

// Chart widgets
export 'src/charts/hrv_chart.dart';
export 'src/charts/hr_chart.dart';
export 'src/charts/stress_chart.dart';
export 'src/charts/spo2_chart.dart';
export 'src/charts/sleep_chart.dart';
