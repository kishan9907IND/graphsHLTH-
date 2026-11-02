/// One state model shared by every chart in the package.
///
/// This is the part that actually makes it a design system. If HRV invents
/// its own empty state and SpO2 invents another, you have five charts, not
/// one system. Every chart takes a [ChartState] and every chart renders the
/// four cases the same way.
sealed class ChartState<T> {
  const ChartState();

  const factory ChartState.loading() = ChartLoading<T>;
  const factory ChartState.empty({required String message}) = ChartEmpty<T>;
  const factory ChartState.error({required String message}) = ChartError<T>;
  const factory ChartState.data(List<T> readings) = ChartData<T>;
}

final class ChartLoading<T> extends ChartState<T> {
  const ChartLoading();
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
}

/// A single overnight HRV reading, in milliseconds RMSSD.
class HrvReading {
  const HrvReading(this.timestamp, this.milliseconds);
  final DateTime timestamp;
  final double milliseconds;
}
