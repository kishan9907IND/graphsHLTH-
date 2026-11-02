/// A beats-per-minute sample. [zone] tags a reading that crossed a
/// threshold worth highlighting — the chart paints these bars in the
/// accent colour so they stand out without needing a tooltip.
class HrReading {
  const HrReading(this.timestamp, this.bpm, {this.zone = HrZone.normal});
  final DateTime timestamp;
  final double bpm;
  final HrZone zone;
}

enum HrZone { normal, elevated, peak }
