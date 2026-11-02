import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';

/// Deterministic demo data + the five view models that pour each metric into
/// the one shared [MetricScreen] format. Fixed seeds so the gallery renders
/// identically on every load (and diffs cleanly between deploys).

final DateTime demoNow = DateTime(2026, 11, 1, 20, 0);

// ---------------------------------------------------------------------------
// Synthetic series (90 days of history so 1M / 3M have something to show).
// ---------------------------------------------------------------------------

final List<HrvReading> _hrv = () {
  final rng = Random(7);
  final start = demoNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final drift = 50 + sin(i / 6) * 7;
    return HrvReading(
      start.add(Duration(days: i, hours: 7)),
      drift + rng.nextDouble() * 8 - 4,
    );
  });
}();

final List<HrReading> _hr = () {
  final rng = Random(11);
  final start = demoNow.subtract(const Duration(days: 90));
  final out = <HrReading>[];
  for (var h = 0; h < 90 * 24; h++) {
    final t = start.add(Duration(hours: h));
    final hourOfDay = t.hour;
    final base = 64 + sin(hourOfDay / 24 * 2 * pi) * 10 + rng.nextDouble() * 6;
    final isPeak = hourOfDay == 7 || hourOfDay == 18;
    out.add(HrReading(
      t,
      (isPeak ? base + 40 : base).clamp(48, 180).toDouble(),
      zone: isPeak ? HrZone.peak : HrZone.normal,
    ));
  }
  return out;
}();

final List<StressReading> _stress = () {
  final rng = Random(19);
  final start = demoNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 34 + sin(i / 3) * 16 + rng.nextDouble() * 12;
    return StressReading(
      start.add(Duration(days: i, hours: 20)),
      v.clamp(0, 100).toDouble(),
    );
  });
}();

final List<Spo2Reading> _spo2 = () {
  final rng = Random(23);
  final start = demoNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 97 + sin(i / 5) * 1.1 + rng.nextDouble() * 1.4 - 0.7;
    return Spo2Reading(
      start.add(Duration(days: i, hours: 7)),
      v.clamp(90, 100).toDouble(),
    );
  });
}();

final List<SleepSegment> _sleep = () {
  final rng = Random(29);
  final start = DateTime(demoNow.year, demoNow.month, demoNow.day - 1, 22);
  const stages = [
    SleepStage.light, SleepStage.deep, SleepStage.light, SleepStage.rem,
    SleepStage.awake, SleepStage.light, SleepStage.deep, SleepStage.rem,
    SleepStage.light, SleepStage.rem, SleepStage.light, SleepStage.awake,
    SleepStage.light, SleepStage.rem,
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

// ---------------------------------------------------------------------------
// Small stats helpers.
// ---------------------------------------------------------------------------

double _mean(Iterable<double> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

// ---------------------------------------------------------------------------
// View models.
// ---------------------------------------------------------------------------

enum DemoMetric { hrv, hr, stress, spo2, sleep }

MetricViewModel modelFor(DemoMetric metric) => switch (metric) {
      DemoMetric.hrv => _hrvModel(),
      DemoMetric.hr => _hrModel(),
      DemoMetric.stress => _stressModel(),
      DemoMetric.spo2 => _spo2Model(),
      DemoMetric.sleep => _sleepModel(),
    };

MetricViewModel _hrvModel() {
  List<HrvReading> win(TimeRange r) =>
      windowed(_hrv, demoNow, r, (x) => x.timestamp);
  return MetricViewModel(
    title: 'HRV',
    icon: Icons.monitor_heart_outlined,
    accent: HlthChartTokens.hrv,
    headerLabel: 'Average HRV',
    unit: 'ms',
    legend: const [
      LegendItem(label: 'HRV', color: HlthChartTokens.hrv),
      LegendItem(
          label: 'Baseline band',
          color: HlthChartTokens.hrv,
          swatch: LegendSwatch.band),
    ],
    headerValue: (r) {
      final d = win(r);
      return d.isEmpty ? null : _mean(d.map((x) => x.milliseconds)).round().toString();
    },
    statusFor: (r) => win(r).isEmpty ? ChartStatus.empty : ChartStatus.data,
    plotBuilder: (r, onZoom) =>
        HrvPlot(readings: _hrv, now: demoNow, range: r, onZoom: onZoom),
    insightFor: (r) =>
        'Your HRV is trending above your 30-day baseline — a sign of good recovery.',
    statsFor: (r) {
      final d = win(r).map((x) => x.milliseconds).toList();
      final lo = d.isEmpty ? 0 : d.reduce(min);
      final hi = d.isEmpty ? 0 : d.reduce(max);
      return StatsSpec(
        title: 'Overnight HRV',
        stats: [
          MetricStat(label: 'Low', value: lo.round().toString(), unit: 'ms'),
          MetricStat(label: 'High', value: hi.round().toString(), unit: 'ms'),
        ],
        caption: 'RMSSD measured during sleep.',
      );
    },
  );
}

MetricViewModel _hrModel() {
  List<HrReading> win(TimeRange r) =>
      windowed(_hr, demoNow, r, (x) => x.timestamp);
  return MetricViewModel(
    title: 'Heart Rate',
    icon: Icons.favorite,
    accent: HlthChartTokens.hr,
    headerLabel: 'Resting heart rate',
    unit: 'bpm',
    legend: const [
      LegendItem(label: 'Heart rate', color: HlthChartTokens.hr),
      LegendItem(label: 'Active zone', color: HlthChartTokens.hrAccent),
    ],
    headerValue: (r) {
      final d = win(r).map((x) => x.bpm).toList();
      return d.isEmpty ? null : d.reduce(min).round().toString();
    },
    statusFor: (r) => win(r).isEmpty ? ChartStatus.empty : ChartStatus.data,
    plotBuilder: (r, onZoom) =>
        HrPlot(readings: _hr, now: demoNow, range: r, onZoom: onZoom),
    insightFor: (r) =>
        'Two active-zone spikes today — both around your usual workout times.',
    cta: const CtaSpec(
      title: 'Live heart rate',
      subtitle: 'Tap to check now',
      icon: Icons.favorite_border,
    ),
    statsFor: (r) {
      final d = win(r).map((x) => x.bpm).toList();
      final median = d.isEmpty ? 0 : _mean(d);
      final hi = d.isEmpty ? 0 : d.reduce(max);
      return StatsSpec(
        title: 'Active heart rate · Today',
        stats: [
          MetricStat(
              label: 'Median', value: median.round().toString(), unit: 'bpm'),
          MetricStat(label: 'High', value: hi.round().toString(), unit: 'bpm'),
        ],
        caption: 'Heart rate above your resting baseline.',
      );
    },
  );
}

MetricViewModel _stressModel() {
  List<StressReading> win(TimeRange r) =>
      windowed(_stress, demoNow, r, (x) => x.timestamp);
  return MetricViewModel(
    title: 'Stress',
    icon: Icons.self_improvement,
    accent: HlthChartTokens.stress,
    headerLabel: 'Average stress',
    unit: '',
    legend: const [
      LegendItem(label: 'Stress index', color: HlthChartTokens.stress),
    ],
    headerValue: (r) {
      final d = win(r);
      return d.isEmpty ? null : _mean(d.map((x) => x.index)).round().toString();
    },
    statusFor: (r) => win(r).isEmpty ? ChartStatus.empty : ChartStatus.data,
    plotBuilder: (r, onZoom) =>
        StressPlot(readings: _stress, now: demoNow, range: r, onZoom: onZoom),
    insightFor: (r) =>
        'Most of your week sat in the low-to-moderate band — one high-stress evening on Thursday.',
    statsFor: (r) {
      final d = win(r).map((x) => x.index).toList();
      final lo = d.isEmpty ? 0 : d.reduce(min);
      final hi = d.isEmpty ? 0 : d.reduce(max);
      return StatsSpec(
        title: 'Stress range',
        stats: [
          MetricStat(label: 'Calmest', value: lo.round().toString(), unit: ''),
          MetricStat(label: 'Peak', value: hi.round().toString(), unit: ''),
        ],
        caption: '0 rest · 100 high.',
      );
    },
  );
}

MetricViewModel _spo2Model() {
  List<Spo2Reading> win(TimeRange r) =>
      windowed(_spo2, demoNow, r, (x) => x.timestamp);
  return MetricViewModel(
    title: 'SpO₂',
    icon: Icons.air,
    accent: HlthChartTokens.spo2,
    headerLabel: 'Average SpO₂',
    unit: '%',
    legend: const [
      LegendItem(label: 'SpO₂', color: HlthChartTokens.spo2),
      LegendItem(
          label: 'Healthy range',
          color: HlthChartTokens.spo2,
          swatch: LegendSwatch.band),
    ],
    headerValue: (r) {
      final d = win(r);
      return d.isEmpty ? null : _mean(d.map((x) => x.percent)).round().toString();
    },
    statusFor: (r) => win(r).isEmpty ? ChartStatus.empty : ChartStatus.data,
    plotBuilder: (r, onZoom) =>
        Spo2Plot(readings: _spo2, now: demoNow, range: r, onZoom: onZoom),
    insightFor: (r) =>
        'SpO₂ stayed inside the healthy 95–100% range every night this week.',
    statsFor: (r) {
      final d = win(r).map((x) => x.percent).toList();
      final lo = d.isEmpty ? 0 : d.reduce(min);
      return StatsSpec(
        title: 'Overnight SpO₂',
        stats: [
          MetricStat(label: 'Lowest', value: lo.round().toString(), unit: '%'),
          MetricStat(label: 'Average',
              value: _mean(d).round().toString(), unit: '%'),
        ],
        caption: 'Below 90% for a sustained period is worth a mention to a doctor.',
      );
    },
  );
}

MetricViewModel _sleepModel() {
  final totalMin = _sleep.fold<int>(
      0, (s, seg) => s + seg.duration.inMinutes);
  final hours = totalMin ~/ 60;
  final mins = totalMin % 60;
  return MetricViewModel(
    title: 'Sleep Quality',
    icon: Icons.bedtime,
    accent: HlthChartTokens.sleepRem,
    headerLabel: 'Time asleep',
    unit: '',
    legend: const [
      LegendItem(label: 'Deep', color: HlthChartTokens.sleepDeep),
      LegendItem(label: 'Light', color: HlthChartTokens.sleepLight),
      LegendItem(label: 'REM', color: HlthChartTokens.sleepRem),
      LegendItem(label: 'Awake', color: HlthChartTokens.sleepAwake),
    ],
    headerValue: (r) => '${hours}h ${mins}m',
    statusFor: (r) => _sleep.isEmpty ? ChartStatus.empty : ChartStatus.data,
    // Sleep is one night — the range tabs still show, but the hypnogram is
    // the same night regardless (a multi-night summary is a separate widget).
    plotBuilder: (r, onZoom) => SleepPlot(segments: _sleep),
    insightFor: (r) =>
        'You got 1h 20m of deep sleep — on the low side; a cooler room can help.',
    statsFor: (r) {
      Duration inStage(SleepStage st) => _sleep
          .where((s) => s.stage == st)
          .fold(Duration.zero, (a, s) => a + s.duration);
      String hm(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';
      return StatsSpec(
        title: 'Stages',
        stats: [
          MetricStat(
              label: 'Deep', value: hm(inStage(SleepStage.deep)), unit: ''),
          MetricStat(
              label: 'REM', value: hm(inStage(SleepStage.rem)), unit: ''),
        ],
        caption: 'Last night · 10.00pm – 6.00am.',
      );
    },
  );
}
