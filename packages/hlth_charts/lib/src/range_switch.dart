import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_theme.dart';
import 'time_range.dart';

/// The Range Switch from the Figma design system — a full-width segmented
/// control with Day / Week / Month / 3M. Selected segment is a white pill
/// with dark text; the rest are transparent with muted labels.
///
/// Each segment is a 44pt-tall touch target. Switching fires a selection
/// haptic — the same feedback the scrub uses, so the whole surface feels
/// consistent under the thumb.
class RangeSwitch extends StatelessWidget {
  const RangeSwitch({
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final range in ranges)
            Expanded(
              child: _Segment(
                label: range.tabLabel,
                selected: range == value,
                onTap: () {
                  if (range != value) {
                    HapticFeedback.selectionClick();
                    onChanged(range);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? HlthChartTokens.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
