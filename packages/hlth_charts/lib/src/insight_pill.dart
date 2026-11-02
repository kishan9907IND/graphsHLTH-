import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';

/// The Insight Pill (HLTH-App-Flows V1 · node 946:6525). A slim single-line
/// takeaway — "Saturday was your strongest day in six weeks" — on a raised
/// dark surface, with a positive-status dot on the left and a trailing
/// chevron. Tappable: it usually drills into the detail behind the insight.
class InsightPill extends StatelessWidget {
  const InsightPill({
    super.key,
    required this.message,
    this.onTap,
    this.dotColor = HlthChartTokens.insightDot,
  });

  final String message;
  final VoidCallback? onTap;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      // pl 12 / pr 10 / py 9, gap 9 — from the DS spec.
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                height: 1.3,
                color: HlthChartTokens.dsTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 9),
          const Icon(
            Icons.chevron_right,
            size: 14,
            color: HlthChartTokens.dsTextSecondary,
          ),
        ],
      ),
    );

    return Material(
      color: HlthChartTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              child: content,
            ),
    );
  }
}

/// The tappable CTA card from the HR page ("Live heart rate / Tap to check
/// now" with a chevron). Distinct from [InsightPill]: this one is an
/// action, so it has a 56pt+ tap target and a trailing chevron.
class InsightCta extends StatelessWidget {
  const InsightCta({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = HlthChartTokens.hr,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HlthChartTokens.cardSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: HlthChartText.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: HlthChartText.cardSubtitle),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: HlthChartTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
