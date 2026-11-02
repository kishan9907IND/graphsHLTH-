import 'package:flutter/material.dart';

import 'chart_theme.dart';
import 'insight_pill.dart';
import 'metric_chart_card.dart';
import 'metric_config.dart';
import 'scrub_overlay.dart';
import 'stats_card.dart';
import 'time_range.dart';

/// The full per-metric screen in the fixed HLTH format, top to bottom:
///
///   App bar (back · title · calendar)
///   → Chart card  (header · Range Switch · plot · legend)
///   → Insight pill   (new)
///   → Live CTA       (optional)
///   → Stats card     (lows/highs/resting/…)
///
/// One widget renders any metric: hand it a [MetricViewModel]. It owns the
/// selected range, and pinch-to-zoom on the plot steps that range in/out.
class MetricScreen extends StatefulWidget {
  const MetricScreen({
    super.key,
    required this.model,
    this.now,
    this.initialRange = TimeRange.week,
    this.onBack,
    this.scrollable = true,
  });

  final MetricViewModel model;
  final DateTime? now;
  final TimeRange initialRange;
  final VoidCallback? onBack;

  /// When embedded in a device frame that already clips, keep this true so
  /// long content scrolls inside the phone rather than overflowing.
  final bool scrollable;

  @override
  State<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends State<MetricScreen> {
  late TimeRange _range = widget.initialRange;
  late final DateTime _now = widget.now ?? DateTime.now();

  // Order from widest to narrowest window. Pinch inward drills toward 1D.
  static const _order = [
    TimeRange.threeMonths,
    TimeRange.month,
    TimeRange.week,
    TimeRange.day,
  ];

  void _zoom(ZoomDirection dir) {
    final i = _order.indexOf(_range);
    final next = switch (dir) {
      ZoomDirection.inward => (i + 1).clamp(0, _order.length - 1),
      ZoomDirection.outward => (i - 1).clamp(0, _order.length - 1),
    };
    if (_order[next] != _range) setState(() => _range = _order[next]);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final status = m.statusFor(_range);
    final insight = m.insightFor?.call(_range);
    final stats = m.statsFor(_range);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MetricChartCard(
          headerLabel: m.headerLabel,
          value: m.headerValue(_range),
          unit: m.unit,
          rangeCaption: _range.rangeCaption(_now),
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
          status: status,
          accent: m.accent,
          legend: m.legend,
          emptyTitle: m.emptyTitle,
          emptySubtitle: m.emptySubtitle,
          plot: m.plotBuilder(_range, _zoom),
        ),
        if (status == ChartStatus.data && insight != null) ...[
          const SizedBox(height: 12),
          InsightPill(message: insight),
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
        if (status == ChartStatus.data) ...[
          const SizedBox(height: 12),
          StatsCard(
            title: stats.title,
            stats: stats.stats,
            caption: stats.caption,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );

    return ColoredBox(
      color: HlthChartTokens.background,
      child: Column(
        children: [
          _AppBar(title: m.title, onBack: widget.onBack),
          Expanded(
            child: widget.scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: body,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: body,
                  ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: HlthChartTokens.textPrimary,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: HlthChartText.cardTitle.copyWith(fontSize: 18),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: HlthChartTokens.cardSurfaceHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: HlthChartTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
