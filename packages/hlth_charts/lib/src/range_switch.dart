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
    // HLTH-App-Flows V1 · node 946:6882: matte-inset trough, 2px padding,
    // 80px radius; selected segment is a matte-elevated capsule.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: HlthChartTokens.matteInset,
        borderRadius: BorderRadius.circular(80),
      ),
      child: Row(
        children: [
          for (final range in ranges)
            Expanded(
              child: _Segment(
                label: range.shortLabel,
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
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? HlthChartTokens.matteElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ).copyWith(
              color: selected
                  ? HlthChartTokens.textPrimary
                  : HlthChartTokens.dsTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
