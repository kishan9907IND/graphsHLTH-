/// A stress-index reading on the 0-100 Garmin/Fitbit convention —
/// 0-25 rest, 26-50 low, 51-75 moderate, 76-100 high.
class StressReading {
  const StressReading(this.timestamp, this.index)
      : assert(index >= 0 && index <= 100);
  final DateTime timestamp;
  final double index;
}
