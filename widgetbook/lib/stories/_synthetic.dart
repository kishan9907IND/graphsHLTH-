import 'dart:math';

import 'package:hlth_charts/hlth_charts.dart';

/// Deterministic synthetic data for the stories (90 days of history so every
/// range has something to show). Fixed seeds — a catalog that mutates on
/// reload can't be reviewed or diffed.

final DateTime storyNow = DateTime(2026, 11, 1, 20, 0);

final List<HrvReading> hrvData = () {
  final rng = Random(7);
  final start = storyNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final drift = 50 + sin(i / 6) * 7;
    return HrvReading(
      start.add(Duration(days: i, hours: 7)),
      drift + rng.nextDouble() * 8 - 4,
    );
  });
}();

final List<HrReading> hrData = () {
  final rng = Random(11);
  final start = storyNow.subtract(const Duration(days: 90));
  final out = <HrReading>[];
  for (var h = 0; h < 90 * 24; h++) {
    final t = start.add(Duration(hours: h));
    final base = 64 + sin(t.hour / 24 * 2 * pi) * 10 + rng.nextDouble() * 6;
    final peak = t.hour == 7 || t.hour == 18;
    out.add(HrReading(t, (peak ? base + 40 : base).clamp(48, 180).toDouble(),
        zone: peak ? HrZone.peak : HrZone.normal));
  }
  return out;
}();

final List<StressReading> stressData = () {
  final rng = Random(19);
  final start = storyNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 34 + sin(i / 3) * 16 + rng.nextDouble() * 12;
    return StressReading(
        start.add(Duration(days: i, hours: 20)), v.clamp(0, 100).toDouble());
  });
}();

final List<Spo2Reading> spo2Data = () {
  final rng = Random(23);
  final start = storyNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 97 + sin(i / 5) * 1.1 + rng.nextDouble() * 1.4 - 0.7;
    return Spo2Reading(
        start.add(Duration(days: i, hours: 7)), v.clamp(90, 100).toDouble());
  });
}();

final List<SleepSegment> sleepData = () {
  final rng = Random(29);
  final start = DateTime(storyNow.year, storyNow.month, storyNow.day - 1, 22);
  const stages = [
    SleepStage.light, SleepStage.deep, SleepStage.light, SleepStage.rem,
    SleepStage.awake, SleepStage.light, SleepStage.deep, SleepStage.rem,
    SleepStage.light, SleepStage.rem, SleepStage.light, SleepStage.awake,
  ];
  var cursor = start;
  final out = <SleepSegment>[];
  for (final s in stages) {
    final mins = switch (s) {
      SleepStage.awake => 2 + rng.nextInt(4),
      SleepStage.rem => 15 + rng.nextInt(20),
      SleepStage.light => 25 + rng.nextInt(30),
      SleepStage.deep => 20 + rng.nextInt(30),
    };
    final end = cursor.add(Duration(minutes: mins));
    out.add(SleepSegment(start: cursor, end: end, stage: s));
    cursor = end;
  }
  return out;
}();

/// Punch a middle chunk out of a series for the "partial / broken with gaps"
/// knob setting.
List<T> withGaps<T>(List<T> items) {
  if (items.length < 6) return items;
  final cut = items.length ~/ 3;
  return [...items.take(cut), ...items.skip(cut * 2)];
}

/// Step the range in/out for a pinch gesture — inward drills toward 1D.
TimeRange stepRange(TimeRange r, ZoomDirection d) {
  const order = [
    TimeRange.threeMonths,
    TimeRange.month,
    TimeRange.week,
    TimeRange.day,
  ];
  final i = order.indexOf(r);
  final n = d == ZoomDirection.inward
      ? (i + 1).clamp(0, order.length - 1)
      : (i - 1).clamp(0, order.length - 1);
  return order[n];
}

double meanOf(Iterable<double> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
