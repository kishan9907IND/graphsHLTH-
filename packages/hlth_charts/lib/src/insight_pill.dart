import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';

/// New component: the Insight Pill. A short, accented takeaway that sits
/// between the chart and the stats — "Heart rate above your resting
/// baseline", "SpO₂ stable overnight". It's the one line a user reads if
/// they read nothing else, so it gets the pale-lime highlight treatment
/// from the dashboard's "150 Heart Points" banner.
class InsightPill extends StatelessWidget {
  const InsightPill({
    super.key,
    required this.message,
    this.icon = Icons.auto_awesome,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HlthChartTokens.insightFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: HlthChartTokens.insightText.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: HlthChartTokens.insightText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: HlthChartText.cardSubtitle.copyWith(
                color: HlthChartTokens.insightText,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
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
