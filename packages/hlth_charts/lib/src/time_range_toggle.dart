import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';
import 'time_range.dart';

/// The pill-shaped segmented control from the Figma's Workout Stats card.
/// Minimum touch target is 44pt per segment — if you add a fifth range,
/// enforce the width constraint rather than letting the pills shrink.
class TimeRangeToggle extends StatelessWidget {
  const TimeRangeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.ranges = TimeRange.values,
  });

  final TimeRange value;
  final ValueChanged<TimeRange> onChanged;
  final List<TimeRange> ranges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurfaceHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in ranges)
            _Pill(
              label: range.label,
              selected: range == value,
              onTap: () {
                if (range != value) {
                  HapticFeedback.selectionClick();
                  onChanged(range);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? HlthChartTokens.textPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: HlthChartText.rangePill.copyWith(
              color: selected
                  ? HlthChartTokens.background
                  : HlthChartTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
