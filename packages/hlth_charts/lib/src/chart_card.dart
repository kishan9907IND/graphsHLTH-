import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// The dark card wrapper you see in every slot on the Figma reference:
/// coloured icon, title, "Last 7 Day" subtitle, collapse chevron on the
/// right. One wrapper means every chart card has identical padding,
/// corner radius and header spacing — differences you see across cards
/// are the data, not the chrome.
class ChartCard extends StatefulWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
    this.initiallyExpanded = true,
    this.height = 220,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  /// Optional secondary row under the header — e.g. the "Today  72–90bpm"
  /// metric readout, or the 3D/7D time-range toggle.
  final Widget? trailing;

  final bool initiallyExpanded;

  /// Fixed card body height. Charts expect a bounded box; letting them
  /// grow unbounded breaks fl_chart's layout.
  final double height;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HlthChartTokens.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.icon,
            iconColor: widget.iconColor,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.trailing != null) ...[
                  const SizedBox(height: 12),
                  widget.trailing!,
                ],
                const SizedBox(height: 12),
                SizedBox(height: widget.height, child: widget.child),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
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
        // Collapse chevron. 44pt hit target per iOS HIG — the visual icon
        // is 24pt but the InkWell swallows the whole square.
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: HlthChartTokens.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
