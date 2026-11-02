import 'dart:math';

import 'package:hlth_charts/hlth_charts.dart';

/// Deterministic synthetic data for the stories. Fixed seeds are
/// non-negotiable — a chart that renders differently on each reload can't
/// be reviewed, and a design-system catalog that mutates can't be diffed.

final DateTime storyNow = DateTime(2026, 11, 1, 20, 0);

List<HrvReading> syntheticHrv({int days = 7, int seed = 7}) {
  final rng = Random(seed);
  final start = storyNow.subtract(Duration(days: days));
  return List.generate(days, (i) {
    final drift = 50 + sin(i / 4) * 6;
    return HrvReading(
      start.add(Duration(days: i, hours: 7)),
      drift + rng.nextDouble() * 8 - 4,
    );
  });
}

List<HrReading> syntheticHr({int points = 96, int seed = 11}) {
  // ~15-min intervals across a day. Sprinkle a few peak-zone callouts so
  // the accent colour is exercised.
  final rng = Random(seed);
  final anchor =
      DateTime(storyNow.year, storyNow.month, storyNow.day, 6, 0);
  return List.generate(points, (i) {
    final base = 72 + sin(i / 8) * 10 + rng.nextDouble() * 6 - 3;
    final isPeak = i == 22 || i == 23 || i == 60 || i == 61;
    final zone = isPeak ? HrZone.peak : HrZone.normal;
    final bpm = isPeak ? base + 22 : base;
    return HrReading(
      anchor.add(Duration(minutes: 15 * i)),
      bpm.clamp(50, 180).toDouble(),
      zone: zone,
    );
  });
}

List<StressReading> syntheticStress({int days = 7, int seed = 19}) {
  final rng = Random(seed);
  final start = storyNow.subtract(Duration(days: days - 1));
  return List.generate(days, (i) {
    final v = 32 + sin(i / 2) * 18 + rng.nextDouble() * 10;
    return StressReading(
      start.add(Duration(days: i, hours: 20)),
      v.clamp(0, 100).toDouble(),
    );
  });
}

List<Spo2Reading> syntheticSpo2({int days = 7, int seed = 23}) {
  final rng = Random(seed);
  final start = storyNow.subtract(Duration(days: days - 1));
  return List.generate(days, (i) {
    final v = 97 + sin(i / 3) * 1.2 + rng.nextDouble() * 1.4 - 0.7;
    return Spo2Reading(
      start.add(Duration(days: i, hours: 7)),
      v.clamp(90, 100).toDouble(),
    );
  });
}

List<SleepSegment> syntheticSleep({int seed = 29}) {
  final rng = Random(seed);
  // ~8h night, 10pm → 6am. Build a plausible sequence of segments.
  final start = DateTime(storyNow.year, storyNow.month, storyNow.day - 1, 22);
  final stages = <SleepStage>[
    SleepStage.light,
    SleepStage.deep,
    SleepStage.light,
    SleepStage.rem,
    SleepStage.awake,
    SleepStage.light,
    SleepStage.deep,
    SleepStage.rem,
    SleepStage.light,
    SleepStage.rem,
    SleepStage.light,
    SleepStage.awake,
    SleepStage.light,
    SleepStage.rem,
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
}

/// Mutilate a series so the "partial / broken with gaps" story has
/// something to show: punch out a middle chunk, keeping the endpoints.
List<T> withGaps<T>(List<T> items) {
  if (items.length < 5) return items;
  final cut = items.length ~/ 3;
  return [
    ...items.take(cut),
    ...items.skip(cut * 2),
  ];
}
