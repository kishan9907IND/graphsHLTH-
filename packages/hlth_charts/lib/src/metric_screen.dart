import 'package:flutter/material.dart';

import 'baseline_progress.dart';
import 'change_table.dart';
import 'chart_state_body.dart';
import 'chart_theme.dart';
import 'insight_pill.dart';
import 'metric_config.dart';
import 'metric_header.dart';
import 'period_navigator.dart';
import 'range_switch.dart';
import 'scrub_overlay.dart';
import 'time_range.dart';

/// The full per-metric screen in the SpO₂-spec format, top to bottom:
///
///   App bar (back · title)
///   Header (value + average · reference range + status pill)
///   Range Switch (1D / 7D / 1M / 3M)
///   Period navigator (‹ 7–13 Oct ›)
///   Chart panel  — or a building-baseline progress card
///   Insight pill (optional) · Live CTA (optional)
///   "How your … changed" table
///   Bottom nav (Home · Workout · Insights · Device)
///
/// One widget renders any metric from a [MetricViewModel]. It owns the
/// selected range and the period offset; pinch-zoom steps the range in/out.
class MetricScreen extends StatefulWidget {
  const MetricScreen({
    super.key,
    required this.model,
    this.now,
    this.initialRange = TimeRange.week,
    this.onBack,
  });

  final MetricViewModel model;
  final DateTime? now;
  final TimeRange initialRange;
  final VoidCallback? onBack;

  @override
  State<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends State<MetricScreen> {
  late TimeRange _range = widget.initialRange;
  int _periodOffset = 0; // 0 = current window, -1 = one window back, …
  late final DateTime _baseNow = widget.now ?? DateTime.now();

  static const _order = [
    TimeRange.threeMonths,
    TimeRange.month,
    TimeRange.week,
    TimeRange.day,
  ];

  // Shift the window anchor back/forward by whole periods of the range.
  DateTime get _now => _baseNow.add(_range.duration * _periodOffset);

  void _zoom(ZoomDirection dir) {
    final i = _order.indexOf(_range);
    final next = switch (dir) {
      ZoomDirection.inward => (i + 1).clamp(0, _order.length - 1),
      ZoomDirection.outward => (i - 1).clamp(0, _order.length - 1),
    };
    if (_order[next] != _range) {
      setState(() {
        _range = _order[next];
        _periodOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final status = m.statusFor(_range);
    final insight = m.insightFor?.call(_range);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MetricHeader(
          label: m.headerLabel,
          value: m.headerValue(_range),
          unit: m.unit,
          averageCaption: m.averageCaption(_range),
          rangeValue: m.rangeValue?.call(_range),
          statusLabel: m.statusLabel,
          statusColor: m.statusColor,
        ),
        const SizedBox(height: 16),
        RangeSwitch(
          value: _range,
          onChanged: (r) => setState(() {
            _range = r;
            _periodOffset = 0;
          }),
        ),
        const SizedBox(height: 8),
        PeriodNavigator(
          label: _range.rangeCaption(_now),
          onPrev: () => setState(() => _periodOffset -= 1),
          onNext: _periodOffset < 0
              ? () => setState(() => _periodOffset += 1)
              : null,
        ),
        const SizedBox(height: 12),
        if (status == ChartStatus.buildingBaseline && m.baseline != null)
          BaselineProgress(
            captured: m.baseline!.captured,
            total: m.baseline!.total,
            headline: m.baseline!.headline,
            checkBack: m.baseline!.checkBack,
            explanation: m.baseline!.explanation,
            accent: m.accent,
          )
        else
          _ChartPanel(
            child: ChartStateBody(
              status: status,
              accent: m.accent,
              emptyTitle: m.emptyTitle,
              emptySubtitle: m.emptySubtitle,
              plot: m.plotBuilder(_range, _zoom),
            ),
          ),
        if (status == ChartStatus.data && insight != null) ...[
          const SizedBox(height: 12),
          InsightPill(message: insight, onTap: () {}),
        ],
        if (m.cta != null) ...[
          const SizedBox(height: 12),
          InsightCta(
            title: m.cta!.title,
            subtitle: m.cta!.subtitle,
            icon: m.cta!.icon,
            accent: m.accent,
            onTap: () {},
          ),
        ],
        const SizedBox(height: 20),
        ChangeTable(title: m.changeTitle, rows: m.changeRows(_range)),
        const SizedBox(height: 24),
      ],
    );

    return DecoratedBox(
      // Subtle green glow bleeding down from the top, as on the SpO₂ screen.
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.1,
          colors: [Color(0x332F3A1A), HlthChartTokens.background],
          stops: [0.0, 0.6],
        ),
        color: HlthChartTokens.background,
      ),
      child: Column(
        children: [
          _AppBar(title: m.title, onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: body,
            ),
          ),
          const _BottomNav(),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Row(
        children: [
          Material(
            color: HlthChartTokens.cardSurfaceHigh,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new,
                    size: 16, color: HlthChartTokens.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: HlthChartText.cardTitle.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _items = <(IconData, String)>[
    (Icons.home, 'Home'),
    (Icons.directions_run, 'Workout'),
    (Icons.insights, 'Insights'),
    (Icons.watch, 'Device'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: HlthChartTokens.divider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _items[i].$1,
                  size: 22,
                  color: i == 0
                      ? HlthChartTokens.textPrimary
                      : HlthChartTokens.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  _items[i].$2,
                  style: HlthChartText.axisLabel.copyWith(
                    color: i == 0
                        ? HlthChartTokens.textPrimary
                        : HlthChartTokens.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
