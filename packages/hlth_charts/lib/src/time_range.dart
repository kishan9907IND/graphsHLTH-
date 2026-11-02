/// The four ranges from the Figma Range Switch: 1D / 1W / 1M / 3M.
///
/// Every chart agrees on what each range means — its window length, the
/// x-axis ticks it produces, and the gap threshold past which a missing
/// stretch is drawn as a break rather than a line. Define once; a chart
/// that invents its own window tells a different story than the card next
/// to it.
enum TimeRange {
  day(shortLabel: '1D', tabLabel: 'Day'),
  week(shortLabel: '7D', tabLabel: 'Week'),
  month(shortLabel: '1M', tabLabel: 'Month'),
  threeMonths(shortLabel: '3M', tabLabel: '3M');

  const TimeRange({required this.shortLabel, required this.tabLabel});

  /// "1D" / "1W" / "1M" / "3M" — the compact form.
  final String shortLabel;

  /// "Day" / "Week" / "Month" / "3M" — the Range Switch tab label.
  final String tabLabel;

  Duration get duration => switch (this) {
        TimeRange.day => const Duration(days: 1),
        TimeRange.week => const Duration(days: 7),
        TimeRange.month => const Duration(days: 30),
        TimeRange.threeMonths => const Duration(days: 90),
      };

  /// Past this gap between consecutive readings, the series is broken and a
  /// "no data" marker is drawn instead of a connecting line. Scaled to the
  /// range so a 2h gap matters in Day view but not in 3M view.
  Duration get gapThreshold => switch (this) {
        TimeRange.day => const Duration(hours: 2),
        TimeRange.week => const Duration(days: 1, hours: 12),
        TimeRange.month => const Duration(days: 4),
        TimeRange.threeMonths => const Duration(days: 10),
      };

  DateTime windowStart(DateTime now) => now.subtract(duration);

  /// Fractional x-position (0..1) of a timestamp within the window.
  double fractionOf(DateTime t, DateTime now) {
    final start = windowStart(now);
    final total = now.difference(start).inMicroseconds;
    if (total <= 0) return 0;
    return (t.difference(start).inMicroseconds / total).clamp(0.0, 1.0);
  }

  /// X-axis ticks for this range, anchored at [now]. Each tick carries the
  /// fraction across the plot width where it sits and the label to draw —
  /// hours for Day, weekdays for Week, dates for Month, months for 3M.
  List<AxisTick> axisTicks(DateTime now) {
    switch (this) {
      case TimeRange.day:
        // Every 6h ending at now's hour: e.g. 02am · 08am · 02pm · 08pm.
        final start = windowStart(now);
        final ticks = <AxisTick>[];
        for (var h = 0; h <= 4; h++) {
          final t = start.add(Duration(hours: 6 * h));
          ticks.add(AxisTick(fractionOf(t, now), _hourLabel(t)));
        }
        return ticks;
      case TimeRange.week:
        // One per day, weekday short name.
        final ticks = <AxisTick>[];
        for (var d = 6; d >= 0; d--) {
          final t = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: d));
          ticks.add(AxisTick(fractionOf(t, now), _weekdayLabel(t)));
        }
        return ticks;
      case TimeRange.month:
        // ~weekly: day-of-month numbers.
        final ticks = <AxisTick>[];
        for (var w = 4; w >= 0; w--) {
          final t = now.subtract(Duration(days: 7 * w));
          ticks.add(AxisTick(fractionOf(t, now), '${t.day}'));
        }
        return ticks;
      case TimeRange.threeMonths:
        // Month boundaries: Aug · Sep · Oct.
        final ticks = <AxisTick>[];
        for (var m = 3; m >= 0; m--) {
          final t = DateTime(now.year, now.month - m, 1);
          ticks.add(AxisTick(fractionOf(t, now), _monthLabel(t)));
        }
        return ticks;
    }
  }

  /// A human-readable description of the window for the metric header —
  /// "6 Oct" for a day, "30 Sep – 6 Oct" for a week, etc.
  String rangeCaption(DateTime now) {
    final start = windowStart(now);
    switch (this) {
      case TimeRange.day:
        return _dateLabel(now);
      case TimeRange.week:
      case TimeRange.month:
        return '${_dateLabel(start)} – ${_dateLabel(now)}';
      case TimeRange.threeMonths:
        return '${_monthLabel(start)} – ${_monthLabel(now)}';
    }
  }

  static String _hourLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final p = t.hour < 12 ? 'am' : 'pm';
    return '$h$p';
  }

  static String _weekdayLabel(DateTime t) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(t.weekday - 1) % 7];
  }

  static String _monthLabel(DateTime t) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(t.month - 1) % 12];
  }

  static String _dateLabel(DateTime t) => '${t.day} ${_monthLabel(t)}';
}

/// A single x-axis tick: where it sits (0..1 across the plot) and its label.
class AxisTick {
  const AxisTick(this.fraction, this.label);
  final double fraction;
  final String label;
}

/// Filter a timestamp-bearing list to a range's trailing window ending at
/// [now], sorted ascending. Charts call this before plotting so the axis
/// and the data agree.
List<T> windowed<T>(
  Iterable<T> items,
  DateTime now,
  TimeRange range,
  DateTime Function(T) timestampOf,
) {
  final start = range.windowStart(now);
  final out = [
    for (final item in items)
      if (!timestampOf(item).isBefore(start) &&
          !timestampOf(item).isAfter(now))
        item,
  ]..sort((a, b) => timestampOf(a).compareTo(timestampOf(b)));
  return out;
}

/// Split a sorted series wherever consecutive points exceed the range's
/// gap threshold. Each inner list is a contiguous run to draw as one line;
/// the breaks between them are where a "no data" marker belongs.
List<List<T>> splitOnGaps<T>(
  List<T> sorted,
  TimeRange range,
  DateTime Function(T) timestampOf,
) {
  if (sorted.isEmpty) return const [];
  final runs = <List<T>>[];
  var current = <T>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final gap = timestampOf(sorted[i]).difference(timestampOf(sorted[i - 1]));
    if (gap > range.gapThreshold) {
      runs.add(current);
      current = <T>[sorted[i]];
    } else {
      current.add(sorted[i]);
    }
  }
  runs.add(current);
  return runs;
}
