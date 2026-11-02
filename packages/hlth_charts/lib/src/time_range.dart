/// Every chart agrees on what "3d" and "7d" mean. Define once; a chart
/// that invents its own window ends up telling a different story than the
/// card next to it.
enum TimeRange {
  threeDays(days: 3, label: '3D'),
  sevenDays(days: 7, label: '7D');

  const TimeRange({required this.days, required this.label});
  final int days;
  final String label;

  Duration get duration => Duration(days: days);
}

/// Filter a timestamp-bearing list to the trailing window ending at [now].
/// Charts call this before plotting so the x-axis and the data agree.
List<T> windowed<T>(
  Iterable<T> items,
  DateTime now,
  TimeRange range,
  DateTime Function(T) timestampOf,
) {
  final cutoff = now.subtract(range.duration);
  return [
    for (final item in items)
      if (!timestampOf(item).isBefore(cutoff) &&
          !timestampOf(item).isAfter(now))
        item,
  ];
}
