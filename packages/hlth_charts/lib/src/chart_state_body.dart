import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';
import 'skeleton_box.dart';

/// Display status of a chart. Mirrors the states across the SpO₂ spec:
/// a quick [loading] spinner, a [skeleton] placeholder, [empty], [error]
/// (retry), [permissionOff] (settings CTA), [buildingBaseline] (handled by
/// the screen, which swaps in a progress card), and [data] (the plot shows).
enum ChartStatus {
  loading,
  skeleton,
  empty,
  error,
  permissionOff,
  buildingBaseline,
  data,
}

/// The shared body that renders either the plot (for [ChartStatus.data]) or
/// the matching state overlay. One switch so every chart treats the states
/// identically. [buildingBaseline] falls through to the plot slot here —
/// the screen decides to show a progress card instead.
class ChartStateBody extends StatelessWidget {
  const ChartStateBody({
    super.key,
    required this.status,
    required this.plot,
    this.accent = HlthChartTokens.series,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Wear your band to start seeing this chart.',
    this.errorTitle = "Couldn't load data",
    this.errorSubtitle = 'Check your connection and try again.',
    this.permissionTitle = 'Health access is off',
    this.permissionSubtitle = 'Allow access in Settings to show this chart.',
    this.onRetry,
    this.onOpenSettings,
  });

  final ChartStatus status;
  final Widget plot;
  final Color accent;
  final String emptyTitle;
  final String emptySubtitle;
  final String errorTitle;
  final String errorSubtitle;
  final String permissionTitle;
  final String permissionSubtitle;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ChartStatus.data:
      case ChartStatus.buildingBaseline:
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
