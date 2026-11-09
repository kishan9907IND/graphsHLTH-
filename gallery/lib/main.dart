import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';

import 'demo_data.dart';
import 'metric_detail_screen.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HLTH Charts',
      debugShowCheckedModeBanner: false,
      theme: hlthDarkTheme(),
      home: const GalleryHome(),
    );
  }
}

/// Responsive preview harness:
///   - left rail  → which metric (HRV / HR / Stress / SpO2 / Sleep)
///   - top tabs   → which screen size (390×844 base + other breakpoints)
///   - centre     → that metric's screen, laid out at the chosen width and
///                  scaled to fit so you check real responsive behaviour.
class GalleryHome extends StatefulWidget {
  const GalleryHome({super.key});

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  DemoMetric _metric = DemoMetric.hr;
  ScreenSize _size = _sizes[1];
  ChartStatus _status = ChartStatus.data;

  static const _sizes = <ScreenSize>[
    ScreenSize('Compact', 360, 780),
    ScreenSize('Base · 390×844', 390, 844),
    ScreenSize('Large', 430, 932),
    ScreenSize('Tablet', 820, 1180),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060609),
      body: SafeArea(
        child: Row(
          children: [
            _MetricRail(
              selected: _metric,
              onSelect: (m) => setState(() => _metric = m),
            ),
            Expanded(
              child: Column(
                children: [
                  _SizeTabs(
                    sizes: _sizes,
                    selected: _size,
                    onSelect: (s) => setState(() => _size = s),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _PhoneFrame(
                          key: ValueKey(
                              '${_metric.name}-${_size.label}-${_status.name}'),
                          size: _size,
                          child: MetricDetailScreen(
                            detail: detailFor(_metric),
                            status: _status,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _StateRail(
              selected: _status,
              onSelect: (s) => setState(() => _status = s),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenSize {
  const ScreenSize(this.label, this.width, this.height);
  final String label;
  final double width;
  final double height;
}

class _MetricRail extends StatelessWidget {
  const _MetricRail({required this.selected, required this.onSelect});
  final DemoMetric selected;
  final ValueChanged<DemoMetric> onSelect;

  static const _items = <(DemoMetric, IconData, String)>[
    (DemoMetric.hrv, Icons.monitor_heart_outlined, 'HRV'),
    (DemoMetric.hr, Icons.favorite, 'Heart'),
    (DemoMetric.stress, Icons.self_improvement, 'Stress'),
    (DemoMetric.spo2, Icons.air, 'SpO₂'),
    (DemoMetric.sleep, Icons.bedtime, 'Sleep'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: const Color(0xFF0E0E13),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Metric', style: HlthChartText.axisLabel),
          const SizedBox(height: 12),
          for (final (metric, icon, label) in _items)
            _RailButton(
              icon: icon,
              label: label,
              selected: metric == selected,
              onTap: () => onSelect(metric),
            ),
        ],
      ),
    );
  }
}

class _StateRail extends StatelessWidget {
  const _StateRail({required this.selected, required this.onSelect});
  final ChartStatus selected;
  final ValueChanged<ChartStatus> onSelect;

  // Figma 4 states (Default / Empty / Partial / Under calculation) + extras.
  static const _items = <(ChartStatus, IconData, String)>[
    (ChartStatus.data, Icons.show_chart, 'Default'),
    (ChartStatus.empty, Icons.inbox_outlined, 'Empty'),
    (ChartStatus.partial, Icons.linear_scale, 'Partial'),
    (ChartStatus.buildingBaseline, Icons.hourglass_bottom, 'Calculating'),
    (ChartStatus.loading, Icons.sync, 'Loading'),
    (ChartStatus.skeleton, Icons.blur_on, 'Skeleton'),
    (ChartStatus.error, Icons.error_outline, 'Error'),
    (ChartStatus.permissionOff, Icons.lock_outline, 'Permission'),
    (ChartStatus.notMeasured, Icons.sensors_off, 'Not meas.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      color: const Color(0xFF0E0E13),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('State', style: HlthChartText.axisLabel),
            const SizedBox(height: 12),
            for (final (status, icon, label) in _items)
              _RailButton(
                icon: icon,
                label: label,
                selected: status == selected,
                onTap: () => onSelect(status),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? HlthChartTokens.textPrimary : HlthChartTokens.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: selected
            ? HlthChartTokens.cardSurfaceHigh
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: HlthChartText.axisLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeTabs extends StatelessWidget {
  const _SizeTabs({
    required this.sizes,
    required this.selected,
    required this.onSelect,
  });
  final List<ScreenSize> sizes;
  final ScreenSize selected;
  final ValueChanged<ScreenSize> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: [
          for (final size in sizes)
            _SizeChip(
              label: size.label,
              selected: size == selected,
              onTap: () => onSelect(size),
            ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
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
      color:
          selected ? HlthChartTokens.textPrimary : HlthChartTokens.cardSurface,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

/// A fixed-size phone bezel that scales to fit the available area, so the
/// metric screen lays out at its true width (real responsive behaviour) and
/// the whole device just scales visually.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({super.key, required this.size, required this.child});
  final ScreenSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: size.width + 16,
        height: size.height + 16,
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(44),
          border: Border.all(color: const Color(0xFF1E1E24), width: 2),
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: MediaQuery(
              data: MediaQueryData(size: Size(size.width, size.height)),
              child: Material(
                color: HlthChartTokens.background,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
