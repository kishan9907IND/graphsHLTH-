/// One state model shared by every chart in the package.
///
/// This is the part that actually makes it a design system. If HRV invents
/// its own empty state and SpO2 invents another, you have five charts, not
/// one system. Every chart takes a [ChartState] and every chart renders the
/// same five cases the same way.
///
/// - [ChartLoading]  — a quick fetch is in flight; show a compact spinner.
/// - [ChartSkeleton] — a slower fetch; show a shimmering placeholder that
///                     mimics the chart's final shape so layout doesn't jump.
/// - [ChartEmpty]    — the fetch succeeded but there is nothing to draw.
/// - [ChartError]    — the fetch failed.
/// - [ChartData]     — readings arrived. The chart decides how to render
///                     sparse vs populated via [ChartData.isSparse] and gap
///                     detection on the timestamps.
sealed class ChartState<T> {
  const ChartState();

  const factory ChartState.loading() = ChartLoading<T>;
  const factory ChartState.skeleton() = ChartSkeleton<T>;
  const factory ChartState.empty({required String message}) = ChartEmpty<T>;
  const factory ChartState.error({required String message}) = ChartError<T>;
  const factory ChartState.data(List<T> readings) = ChartData<T>;
}

final class ChartLoading<T> extends ChartState<T> {
  const ChartLoading();
}

final class ChartSkeleton<T> extends ChartState<T> {
  const ChartSkeleton();
}

final class ChartEmpty<T> extends ChartState<T> {
  const ChartEmpty({required this.message});
  final String message;
}

final class ChartError<T> extends ChartState<T> {
  const ChartError({required this.message});
  final String message;
}

final class ChartData<T> extends ChartState<T> {
  const ChartData(this.readings);
  final List<T> readings;

  /// A single point is not a trend. Charts should branch on this rather
  /// than trying to draw a line through one value.
  bool get isSparse => readings.length < 3;

  bool get isEmpty => readings.isEmpty;
}
