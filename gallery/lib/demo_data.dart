import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';

import 'metric_detail_screen.dart';

/// Deterministic demo data + the five view models that pour each metric into
/// the one shared [MetricScreen] format. Fixed seeds so the gallery renders
/// identically on every load.

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
    final base = 64 + sin(t.hour / 24 * 2 * pi) * 10 + rng.nextDouble() * 6;
    final peak = t.hour == 7 || t.hour == 18;
    out.add(HrReading(t, (peak ? base + 40 : base).clamp(48, 180).toDouble(),
        zone: peak ? HrZone.peak : HrZone.normal));
  }
  return out;
}();

final List<StressReading> _stress = () {
  final rng = Random(19);
  final start = demoNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 34 + sin(i / 3) * 16 + rng.nextDouble() * 12;
    return StressReading(
        start.add(Duration(days: i, hours: 20)), v.clamp(0, 100).toDouble());
  });
}();

final List<Spo2Reading> _spo2 = () {
  final rng = Random(23);
  final start = demoNow.subtract(const Duration(days: 90));
  return List.generate(90, (i) {
    final v = 97 + sin(i / 5) * 1.1 + rng.nextDouble() * 1.4 - 0.7;
    return Spo2Reading(
        start.add(Duration(days: i, hours: 7)), v.clamp(90, 100).toDouble());
  });
}();

final List<SleepSegment> _sleep = () {
  // Hand-authored to match a real Apple Health night (the reference):
  // ~90-min cycles with deep concentrated early, REM lengthening toward
  // morning, brief awakenings. Stage totals sum exactly to the reference:
  // Awake 14m · REM 1h49m · Core 4h26m · Deep 1h4m. (Light == Core.)
  // Continuous — the "Partial / Not measured" states punch gaps separately.
  final steps = <(SleepStage, int)>[
    (SleepStage.awake, 3),
    (SleepStage.light, 16),
    (SleepStage.deep, 34), // deep-heavy first cycle
    (SleepStage.light, 24),
    (SleepStage.rem, 8),
    (SleepStage.light, 30),
    (SleepStage.deep, 20),
    (SleepStage.light, 28),
    (SleepStage.rem, 16),
    (SleepStage.awake, 4),
    (SleepStage.light, 32),
    (SleepStage.deep, 10),
    (SleepStage.light, 30),
    (SleepStage.rem, 22),
    (SleepStage.light, 26),
    (SleepStage.awake, 3),
    (SleepStage.light, 34),
    (SleepStage.rem, 27),
    (SleepStage.light, 22),
    (SleepStage.awake, 4),
    (SleepStage.light, 24),
    (SleepStage.rem, 36), // long morning REM
  ];
  var cursor = DateTime(demoNow.year, demoNow.month, demoNow.day - 1, 22, 0);
  final out = <SleepSegment>[];
  for (final (stage, mins) in steps) {
    final end = cursor.add(Duration(minutes: mins));
    out.add(SleepSegment(start: cursor, end: end, stage: stage));
    cursor = end;
  }
  return out;
}();

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

double _mean(Iterable<double> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

// For the "Partial / Gap" state: punch two holes (a recent few hours and a
// couple of days last week) so a gap is visible at any range.
bool _inHole(DateTime t) {
  final a1 = demoNow.subtract(const Duration(days: 5));
  final a2 = demoNow.subtract(const Duration(days: 3));
  final b1 = demoNow.subtract(const Duration(hours: 8));
  final b2 = demoNow.subtract(const Duration(hours: 6));
  return (t.isAfter(a1) && t.isBefore(a2)) ||
      (t.isAfter(b1) && t.isBefore(b2));
}

List<T> _gapped<T>(List<T> all, DateTime Function(T) ts) =>
    [for (final a in all) if (!_inHole(ts(a))) a];

List<T> _win<T>(List<T> all, TimeRange r, DateTime Function(T) ts) =>
    windowed(all, demoNow, r, ts);

double? _meanInWindow<T>(
  List<T> all,
  double Function(T) val,
  DateTime Function(T) ts,
  DateTime start,
  DateTime end,
) {
  final xs = [
    for (final a in all)
      if (!ts(a).isBefore(start) && !ts(a).isAfter(end)) val(a),
  ];
  return xs.isEmpty ? null : _mean(xs);
}

/// Build the "How your … changed" rows by comparing the mean of the last N
/// days against the N days before that.
List<ChangeRow> _changeRows<T>(
  List<T> all,
  double Function(T) val,
  DateTime Function(T) ts,
  String unit,
) {
  ChangeRow make(int d, String label) {
    final cur =
        _meanInWindow(all, val, ts, demoNow.subtract(Duration(days: d)), demoNow);
    final prev = _meanInWindow(all, val, ts,
        demoNow.subtract(Duration(days: 2 * d)), demoNow.subtract(Duration(days: d)));
    if (cur == null || prev == null) {
      return ChangeRow(period: label, change: null, unit: unit, trend: Trend.tbd);
    }
    final r = (cur - prev).round();
    final str = r == 0 ? '0' : '${r > 0 ? '+' : '−'}${r.abs()}';
    final trend = r > 0 ? Trend.high : (r < 0 ? Trend.low : Trend.normal);
    return ChangeRow(period: label, change: str, unit: unit, trend: trend);
  }

  return [
    make(3, '3 day'),
    make(7, '7 day'),
    make(14, '14 day'),
    make(30, '30 day'),
    make(90, '90 day'),
  ];
}

String _avgCaption(TimeRange r) => switch (r) {
      TimeRange.day => 'Daily average',
      TimeRange.week => '7-day average',
      TimeRange.month => '30-day average',
      TimeRange.threeMonths => '90-day average',
    };

// ---------------------------------------------------------------------------
// View models.
// ---------------------------------------------------------------------------

enum DemoMetric { hrv, hr, stress, spo2, sleep }

// ---------------------------------------------------------------------------
// Detail-screen configs: same chrome for every metric, each with its own
// existing chart + header + low/high values.
// ---------------------------------------------------------------------------

const _green = Color(0xFF22C55E);
const _grey = Color(0xFFC7C8C8);
const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
String _stamp(DateTime d) => '${_wd[d.weekday - 1]}, ${d.day} ${_mo[d.month - 1]}';

(String, String) _extreme<T>(
  List<T> xs,
  double Function(T) v,
  DateTime Function(T) t, {
  required bool max,
}) {
  if (xs.isEmpty) return ('–', '');
  var best = xs.first;
  for (final x in xs) {
    if (max ? v(x) > v(best) : v(x) < v(best)) best = x;
  }
  return (v(best).round().toString(), _stamp(t(best)));
}

final String _period = TimeRange.week.rangeCaption(demoNow);

MetricDetail detailFor(DemoMetric metric) => switch (metric) {
      DemoMetric.hrv => () {
          final d = _win(_hrv, TimeRange.week, (x) => x.timestamp);
          final lo = _extreme(d, (x) => x.milliseconds, (x) => x.timestamp,
              max: false);
          final hi = _extreme(d, (x) => x.milliseconds, (x) => x.timestamp,
              max: true);
          return MetricDetail(
            title: 'HRV',
            headerLabel: 'HRV',
            bigValue: _mean(d.map((x) => x.milliseconds)).round().toString(),
            caption: '7-day average',
            rightValue: '40–60 ms',
            rightStatus: 'Normal Range',
            rightStatusColor: _green,
            periodCaption: _period,
            chart: HrvPlot(readings: _hrv, now: demoNow, range: TimeRange.week),
            lowValue: lo.$1,
            lowSub: lo.$2,
            highValue: hi.$1,
            highSub: hi.$2,
          );
        }(),
      DemoMetric.hr => () {
          final d = _win(_hr, TimeRange.week, (x) => x.timestamp);
          final bpm = d.map((x) => x.bpm).toList();
          final lo = _extreme(d, (x) => x.bpm, (x) => x.timestamp, max: false);
          final hi = _extreme(d, (x) => x.bpm, (x) => x.timestamp, max: true);
          return MetricDetail(
            title: 'Heart Rate',
            headerLabel: 'Heart rate',
            bigValue: '${bpm.reduce(min).round()}–${bpm.reduce(max).round()}',
            caption: 'Avg today',
            rightValue: '80–124 bpm',
            rightStatus: '7-day baseline',
            rightStatusColor: _grey,
            periodCaption: _period,
            chart: HrPlot(readings: _hr, now: demoNow, range: TimeRange.week),
            lowValue: lo.$1,
            lowSub: lo.$2,
            highValue: hi.$1,
            highSub: hi.$2,
          );
        }(),
      DemoMetric.stress => const MetricDetail(
          title: 'Stress',
          headerLabel: 'Stress',
          bigValue: '42',
          caption: 'Weekly average',
          rightValue: '28–66',
          rightStatus: 'Moderate Range',
          rightStatusColor: _green,
          periodCaption: '21–27 Sep',
          chart: StressBarsChart(
            values: [40, 52, 58, 48, 54, 33, 42],
            labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            highlight: 2,
          ),
          lowValue: '33',
          lowSub: 'Sat, 26 Sep',
          highValue: '58',
          highSub: 'Wed, 23 Sep',
        ),
      DemoMetric.spo2 => () {
          final d = _win(_spo2, TimeRange.week, (x) => x.timestamp);
          final lo =
              _extreme(d, (x) => x.percent, (x) => x.timestamp, max: false);
          final hi =
              _extreme(d, (x) => x.percent, (x) => x.timestamp, max: true);
          return MetricDetail(
            title: 'SpO₂',
            headerLabel: 'SpO₂',
            bigValue: _mean(d.map((x) => x.percent)).round().toString(),
            caption: '7-day average',
            rightValue: '95–100 %',
            rightStatus: 'Normal Range',
            rightStatusColor: _green,
            periodCaption: _period,
            chart: Spo2Plot(readings: _spo2, now: demoNow, range: TimeRange.week),
            lowValue: lo.$1,
            lowSub: lo.$2,
            highValue: hi.$1,
            highSub: hi.$2,
          );
        }(),
      DemoMetric.sleep => () {
          Duration inStage(SleepStage s) => _sleep
              .where((x) => x.stage == s)
              .fold(Duration.zero, (a, x) => a + x.duration);
          String hm(Duration x) => '${x.inHours}h ${x.inMinutes % 60}m';
          final asleep = _sleep
              .where((s) => s.stage != SleepStage.awake)
              .fold(Duration.zero, (a, s) => a + s.duration);
          return MetricDetail(
            title: 'Sleep',
            headerLabel: 'Time asleep',
            bigValue: hm(asleep),
            caption: 'Last night',
            rightValue: hm(asleep + inStage(SleepStage.awake) +
                const Duration(minutes: 28)),
            rightStatus: 'Time in bed',
            rightStatusColor: _grey,
            periodCaption: 'Last night',
            chart: SleepPlot(segments: _sleep),
            chartHeight: 210,
            lowLabel: 'DEEP',
            lowValue: hm(inStage(SleepStage.deep)),
            lowSub: 'Deepest stage',
            highLabel: 'CORE',
            highValue: hm(inStage(SleepStage.light)),
            highSub: 'Most of the night',
          );
        }(),
    };

MetricViewModel modelFor(DemoMetric metric) => switch (metric) {
      DemoMetric.hrv => _hrvModel(),
      DemoMetric.hr => _hrModel(),
      DemoMetric.stress => _stressModel(),
      DemoMetric.spo2 => _spo2Model(),
      DemoMetric.sleep => _sleepModel(),
    };

MetricViewModel _hrvModel() => MetricViewModel(
      title: 'HRV',
      icon: Icons.monitor_heart_outlined,
      accent: HlthChartTokens.hrv,
      headerLabel: 'HRV',
      unit: 'ms',
      legend: const [
        LegendItem(label: 'HRV', color: HlthChartTokens.hrv),
        LegendItem(
            label: 'Baseline band',
            color: HlthChartTokens.hrv,
            swatch: LegendSwatch.band),
      ],
      averageCaption: _avgCaption,
      rangeValue: (_) => '40–60 ms',
      statusLabel: 'Normal Range',
      headerValue: (r) {
        final d = _win(_hrv, r, (x) => x.timestamp);
        return d.isEmpty
            ? null
            : _mean(d.map((x) => x.milliseconds)).round().toString();
      },
      statusFor: (r) =>
          _win(_hrv, r, (x) => x.timestamp).isEmpty
              ? ChartStatus.empty
              : ChartStatus.data,
      plotBuilder: (r, status, onZoom) => HrvPlot(
        readings:
            status == ChartStatus.partial ? _gapped(_hrv, (x) => x.timestamp) : _hrv,
        now: demoNow,
        range: r,
        onZoom: onZoom,
      ),
      insightFor: (_) =>
          'Your HRV is trending above your 30-day baseline — good recovery.',
      changeTitle: 'How your HRV changed',
      changeRows: (_) =>
          _changeRows(_hrv, (x) => x.milliseconds, (x) => x.timestamp, 'ms'),
    );

MetricViewModel _hrModel() => MetricViewModel(
      title: 'Heart Rate',
      icon: Icons.favorite,
      accent: HlthChartTokens.hr,
      headerLabel: 'Heart rate',
      unit: 'bpm',
      legend: const [
        LegendItem(label: 'Heart rate', color: HlthChartTokens.hr),
        LegendItem(label: 'Active zone', color: HlthChartTokens.hrAccent),
      ],
      averageCaption: (r) => switch (r) {
        TimeRange.day => 'Avg today',
        TimeRange.week => '7-day avg',
        TimeRange.month => '30-day avg',
        TimeRange.threeMonths => '90-day avg',
      },
      // Right column shows the multi-day baseline range, like Apple Health.
      rangeCaption: '7-day baseline',
      rangeValue: (_) {
        final d = _win(_hr, TimeRange.week, (x) => x.timestamp)
            .map((x) => x.bpm)
            .toList();
        if (d.isEmpty) return null;
        return '${d.reduce(min).round()}–${d.reduce(max).round()} bpm';
      },
      statusLabel: null,
      headerValue: (r) {
        final d = _win(_hr, r, (x) => x.timestamp).map((x) => x.bpm).toList();
        if (d.isEmpty) return null;
        return '${d.reduce(min).round()}–${d.reduce(max).round()}';
      },
      statusFor: (r) => _win(_hr, r, (x) => x.timestamp).isEmpty
          ? ChartStatus.empty
          : ChartStatus.data,
      plotBuilder: (r, status, onZoom) => HrPlot(
        readings:
            status == ChartStatus.partial ? _gapped(_hr, (x) => x.timestamp) : _hr,
        now: demoNow,
        range: r,
        onZoom: onZoom,
      ),
      insightFor: (_) =>
          'Two active-zone spikes today — both around your usual workout times.',
      cta: const CtaSpec(
        title: 'Live heart rate',
        subtitle: 'Tap to check now',
        icon: Icons.favorite_border,
      ),
      changeTitle: 'How your heart rate changed',
      changeRows: (_) =>
          _changeRows(_hr, (x) => x.bpm, (x) => x.timestamp, 'bpm'),
    );

MetricViewModel _stressModel() => MetricViewModel(
      title: 'Stress',
      icon: Icons.self_improvement,
      accent: HlthChartTokens.stress,
      headerLabel: 'Stress',
      unit: '',
      legend: const [
        LegendItem(label: 'Stress index', color: HlthChartTokens.stress),
      ],
      averageCaption: _avgCaption,
      rangeValue: (_) => '0–100',
      statusLabel: 'Low–Moderate',
      statusColor: HlthChartTokens.stress,
      headerValue: (r) {
        final d = _win(_stress, r, (x) => x.timestamp);
        return d.isEmpty ? null : _mean(d.map((x) => x.index)).round().toString();
      },
      statusFor: (r) => _win(_stress, r, (x) => x.timestamp).isEmpty
          ? ChartStatus.empty
          : ChartStatus.data,
      plotBuilder: (r, status, onZoom) => StressPlot(
        readings: status == ChartStatus.partial
            ? _gapped(_stress, (x) => x.timestamp)
            : _stress,
        now: demoNow,
        range: r,
        onZoom: onZoom,
      ),
      insightFor: (_) =>
          'Most of your week sat in the low-to-moderate band.',
      changeTitle: 'How your stress changed',
      changeRows: (_) =>
          _changeRows(_stress, (x) => x.index, (x) => x.timestamp, 'pts'),
    );

MetricViewModel _spo2Model() => MetricViewModel(
      title: 'SpO₂',
      icon: Icons.air,
      accent: HlthChartTokens.spo2,
      headerLabel: 'SpO₂',
      unit: '%',
      legend: const [
        LegendItem(label: 'SpO₂', color: HlthChartTokens.spo2),
        LegendItem(
            label: 'Healthy range',
            color: HlthChartTokens.spo2,
            swatch: LegendSwatch.band),
      ],
      averageCaption: _avgCaption,
      rangeValue: (_) => '95–100 %',
      statusLabel: 'Normal Range',
      headerValue: (r) {
        final d = _win(_spo2, r, (x) => x.timestamp);
        return d.isEmpty ? null : _mean(d.map((x) => x.percent)).round().toString();
      },
      statusFor: (r) => _win(_spo2, r, (x) => x.timestamp).isEmpty
          ? ChartStatus.empty
          : ChartStatus.data,
      plotBuilder: (r, status, onZoom) => Spo2Plot(
        readings: status == ChartStatus.partial
            ? _gapped(_spo2, (x) => x.timestamp)
            : _spo2,
        now: demoNow,
        range: r,
        onZoom: onZoom,
      ),
      insightFor: (_) =>
          'SpO₂ stayed inside the healthy 95–100% range every night this week.',
      baseline: const BaselineSpec(
        captured: 3,
        total: 7,
        headline: '3 of 7 Nights.',
        checkBack: 'Please check back in 4 days.',
        explanation:
            'Blood oxygen is measured while you sleep. We need about a week '
            'of nights before rolling changes mean anything — a single night '
            'tells you very little.',
      ),
      changeTitle: 'How your SpO₂ changed',
      changeRows: (_) =>
          _changeRows(_spo2, (x) => x.percent, (x) => x.timestamp, 'pts'),
    );

MetricViewModel _sleepModel() {
  Duration inStage(SleepStage st) => _sleep
      .where((s) => s.stage == st)
      .fold(Duration.zero, (a, s) => a + s.duration);
  final asleepMin = _sleep
      .where((s) => s.stage != SleepStage.awake)
      .fold<int>(0, (s, seg) => s + seg.duration.inMinutes);
  final awakeMin = inStage(SleepStage.awake).inMinutes;
  // Time in bed = time asleep + awake + a short settle/rouse buffer.
  final inBedMin = asleepMin + awakeMin + 28;
  String hm(int m) => '${m ~/ 60}h ${m % 60}m';
  String hmd(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';
  return MetricViewModel(
    title: 'Sleep',
    icon: Icons.bedtime,
    accent: HlthChartTokens.sleepRem,
    // Paired header like Apple Health: Time in bed (left) · Time asleep (right).
    headerLabel: 'Time in bed',
    unit: '',
    legend: const [
      LegendItem(label: 'Awake', color: HlthChartTokens.sleepAwake),
      LegendItem(label: 'REM', color: HlthChartTokens.sleepRem),
      LegendItem(label: 'Core', color: HlthChartTokens.sleepLight),
      LegendItem(label: 'Deep', color: HlthChartTokens.sleepDeep),
    ],
    averageCaption: (_) => 'Last night',
    rangeCaption: 'Time asleep',
    rangeValue: (_) => hm(asleepMin),
    statusLabel: null,
    headerValue: (_) => hm(inBedMin),
    statusFor: (_) => _sleep.isEmpty ? ChartStatus.empty : ChartStatus.data,
    plotBuilder: (r, status, onZoom) => SleepPlot(
      segments: status == ChartStatus.partial
          ? _gapped(_sleep, (x) => x.start)
          : _sleep,
    ),
    insightFor: (_) =>
        'Deep sleep was ${hmd(inStage(SleepStage.deep))} — a little below your usual.',
    changeTitle: 'Stages',
    changeRows: (_) => [
      ChangeRow(
          period: 'Awake',
          change: hmd(inStage(SleepStage.awake)),
          unit: '',
          trend: Trend.low),
      ChangeRow(
          period: 'REM',
          change: hmd(inStage(SleepStage.rem)),
          unit: '',
          trend: Trend.high),
      ChangeRow(
          period: 'Core',
          change: hmd(inStage(SleepStage.light)),
          unit: '',
          trend: Trend.normal),
      ChangeRow(
          period: 'Deep',
          change: hmd(inStage(SleepStage.deep)),
          unit: '',
          trend: Trend.normal),
    ],
  );
}
