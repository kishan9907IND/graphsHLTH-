import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_legend.dart';
import 'chart_theme.dart';
import 'metric_header.dart';
import 'range_switch.dart';
import 'skeleton_box.dart';
import 'time_range.dart';

/// The display status of a chart card. Mirrors the states on the Figma
/// Chart/Card master: a quick [loading] spinner, a [skeleton] placeholder
/// for slower fetches, [empty], [error] (with retry), [permissionOff] (with
/// a settings CTA), and [data] (the plot renders).
enum ChartStatus { loading, skeleton, empty, error, permissionOff, data }

/// The unified Chart/Card — the one format every metric is poured into:
/// header → Range Switch → plot/state → legend. Swap the [plot] and the
/// header fields and you have a different metric in the same frame.
class MetricChartCard extends StatelessWidget {
  const MetricChartCard({
    super.key,
    required this.headerLabel,
    required this.value,
    required this.unit,
    required this.rangeCaption,
    required this.range,
    required this.onRangeChanged,
    required this.status,
    required this.plot,
    required this.legend,
    this.syncStatus,
    this.plotHeight = 180,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Wear your band to start seeing this chart.',
    this.errorTitle = "Couldn't load data",
    this.errorSubtitle = 'Check your connection and try again.',
    this.permissionTitle = 'Health access is off',
    this.permissionSubtitle = 'Allow access in Settings to show this chart.',
    this.onRetry,
    this.onOpenSettings,
    this.accent = HlthChartTokens.hrv,
  });

  final String headerLabel;
  final String? value;
  final String unit;
  final String rangeCaption;
  final String? syncStatus;

  final TimeRange range;
  final ValueChanged<TimeRange> onRangeChanged;

  final ChartStatus status;
  final Widget plot;
  final List<LegendItem> legend;

  final double plotHeight;
  final String emptyTitle;
  final String emptySubtitle;
  final String errorTitle;
  final String errorSubtitle;
  final String permissionTitle;
  final String permissionSubtitle;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MetricHeader(
            label: headerLabel,
            value: value,
            unit: unit,
            rangeCaption: rangeCaption,
            syncStatus: syncStatus,
          ),
          const SizedBox(height: 14),
          RangeSwitch(value: range, onChanged: onRangeChanged),
          const SizedBox(height: 16),
          SizedBox(height: plotHeight, child: _body()),
          if (status == ChartStatus.data) ...[
            const SizedBox(height: 12),
            ChartLegend(items: legend),
          ],
        ],
      ),
    );
  }

  Widget _body() {
    switch (status) {
      case ChartStatus.data:
        return plot;
      case ChartStatus.loading:
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        );
      case ChartStatus.skeleton:
        return const ChartSkeletonBody();
      case ChartStatus.empty:
        return _StateMessage(title: emptyTitle, subtitle: emptySubtitle);
      case ChartStatus.error:
        return _StateMessage(
          title: errorTitle,
          subtitle: errorSubtitle,
          action: _CtaButton(label: 'Try again', onTap: onRetry),
        );
      case ChartStatus.permissionOff:
        return _StateMessage(
          title: permissionTitle,
          subtitle: permissionSubtitle,
          action: _CtaButton(label: 'Open Settings', onTap: onOpenSettings),
        );
    }
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: HlthChartText.cardTitle),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: HlthChartText.cardSubtitle,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HlthChartTokens.ctaFill,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: HlthChartText.rangePill.copyWith(
              color: HlthChartTokens.ctaText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
