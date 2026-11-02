/// Peripheral oxygen saturation, expressed as a percentage (0-100).
/// Clinical "normal" is 95-100; the chart paints the band accordingly.
class Spo2Reading {
  const Spo2Reading(this.timestamp, this.percent)
      : assert(percent >= 0 && percent <= 100);
  final DateTime timestamp;
  final double percent;
}
