/// A single overnight HRV reading, in milliseconds RMSSD.
class HrvReading {
  const HrvReading(this.timestamp, this.milliseconds);
  final DateTime timestamp;
  final double milliseconds;
}
