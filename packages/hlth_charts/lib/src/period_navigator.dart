import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';

/// The `‹ 7–13 Oct ›` stepper above the chart. Steps the visible window one
/// period back/forward. Chevrons are 44pt touch targets; [onPrev]/[onNext]
/// may be null to disable an end (e.g. no future data).
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Chevron(icon: Icons.chevron_left, onTap: onPrev),
        Text(
          label,
          style: HlthChartText.cardSubtitle.copyWith(
            color: HlthChartTokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        _Chevron(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? HlthChartTokens.textSecondary
                : HlthChartTokens.textMuted,
          ),
        ),
      ),
    );
  }
}
