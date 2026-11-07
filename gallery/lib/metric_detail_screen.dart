import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';

/// The shared detail screen chrome (built literally from Figma 658:12415) used
/// for every metric. Only the chart slot and the header/low-high values change
/// per metric — the background, app bar, tabs, cards, carousel and bottom nav
/// stay identical across HRV / Heart / Stress / SpO2 / Sleep.

// Figma tokens.
const _bg = Color(0xFF0A0A0A);
const _surfaceRaised = Color(0xFF1C1C1C);
const _border = Color(0xFF333536);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFC7C8C8);
const _textTertiary = Color(0xFF9A99A1);
const _brand = Color(0xFFD0ED29);
const _barOlive = Color(0xFF8CA23E);

/// Per-metric content poured into the shared screen.
class MetricDetail {
  const MetricDetail({
    required this.title,
    required this.headerLabel,
    required this.bigValue,
    required this.caption,
    required this.rightValue,
    required this.rightStatus,
    required this.rightStatusColor,
    required this.periodCaption,
    required this.chart,
    required this.lowValue,
    required this.lowSub,
    required this.highValue,
    required this.highSub,
    this.lowLabel = 'LOWEST',
    this.highLabel = 'HIGHEST',
    this.chartHeight = 190,
  });

  final String title;
  final String headerLabel;
  final String bigValue;
  final String caption;
  final String rightValue;
  final String rightStatus;
  final Color rightStatusColor;
  final String periodCaption;
  final Widget chart;
  final double chartHeight;
  final String lowLabel, lowValue, lowSub;
  final String highLabel, highValue, highSub;
}

class MetricDetailScreen extends StatefulWidget {
  const MetricDetailScreen({super.key, required this.detail, this.onBack});
  final MetricDetail detail;
  final VoidCallback? onBack;

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  TimeRange _range = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    return ColoredBox(
      color: _bg,
      child: Column(
        children: [
          _statusBar(),
          _appBar(d.title),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RangeSwitch(
                    value: _range,
                    onChanged: (r) => setState(() => _range = r),
                  ),
                  const SizedBox(height: 18),
                  _header(d),
                  const SizedBox(height: 14),
                  PeriodNavigator(
                      label: d.periodCaption, onPrev: () {}, onNext: () {}),
                  const SizedBox(height: 12),
                  Container(
                    height: d.chartHeight,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surfaceRaised,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: d.chart,
                  ),
                  const SizedBox(height: 16),
                  _askCopilot(),
                  const SizedBox(height: 12),
                  _lowestHighest(d),
                  const SizedBox(height: 12),
                  _bandsRow(),
                  const SizedBox(height: 16),
                  _articles(),
                  const SizedBox(height: 10),
                  _dots(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _bottomNav(),
        ],
      ),
    );
  }

  Widget _statusBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('9:41',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Row(children: [
              Icon(Icons.signal_cellular_alt, size: 16, color: _textPrimary),
              SizedBox(width: 5),
              Icon(Icons.wifi, size: 16, color: _textPrimary),
              SizedBox(width: 5),
              Icon(Icons.battery_full, size: 18, color: _textPrimary),
            ]),
          ],
        ),
      );

  Widget _appBar(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            _circleButton(Icons.arrow_back_ios_new, widget.onBack),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ),
            _circleButton(Icons.inventory_2_outlined, () {}),
          ],
        ),
      );

  Widget _circleButton(IconData icon, VoidCallback? onTap) => Material(
        color: _surfaceRaised,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 17, color: _textPrimary),
          ),
        ),
      );

  Widget _header(MetricDetail d) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.headerLabel,
                    style: const TextStyle(color: _textSecondary, fontSize: 14)),
                const SizedBox(height: 2),
                Text(d.bigValue,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 44,
                        height: 1.0,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(d.caption,
                    style: const TextStyle(color: _textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(d.rightValue,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(d.rightStatus,
                  style: TextStyle(
                      color: d.rightStatusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      );

  Widget _askCopilot() => Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [_brand, Color(0xFF7B5CFF), Color(0xFF46CEE8)]),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: _surfaceRaised, borderRadius: BorderRadius.circular(17)),
          child: Row(
            children: const [
              Icon(Icons.auto_awesome, size: 20, color: _brand),
              SizedBox(width: 12),
              Expanded(
                child: Text('Ask Copilot about this week',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right, color: _textSecondary),
            ],
          ),
        ),
      );

  Widget _lowestHighest(MetricDetail d) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _surfaceRaised, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Expanded(child: _stat(d.lowLabel, d.lowValue, d.lowSub)),
            Container(width: 1, height: 44, color: _border),
            const SizedBox(width: 16),
            Expanded(child: _stat(d.highLabel, d.highValue, d.highSub)),
          ],
        ),
      );

  Widget _stat(String label, String value, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _textTertiary, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 12)),
        ],
      );

  Widget _bandsRow() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: _surfaceRaised, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: const [
            Icon(Icons.info_outline, size: 18, color: _textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Text('What the bands mean',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, color: _textSecondary),
          ],
        ),
      );

  Widget _articles() => SizedBox(
        height: 150,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [_articleCard(), const SizedBox(width: 12), _articleCard()],
        ),
      );

  Widget _articleCard() => Container(
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2E2A), Color(0xFF241F1D)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Resting heart rate for Women : How it changes by life stage',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right,
                    size: 18, color: _textPrimary),
              ),
            ),
          ],
        ),
      );

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                  color: _brand, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          _dot(),
          const SizedBox(width: 5),
          _dot(),
        ],
      );

  Widget _dot() => Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: _border, shape: BoxShape.circle));

  Widget _bottomNav() {
    const items = [
      (Icons.home, 'Home'),
      (Icons.directions_run, 'Workout'),
      (Icons.add, 'Insights'),
      (Icons.watch, 'Device'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration:
          const BoxDecoration(border: Border(top: BorderSide(color: _border, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1,
                    size: 22, color: i == 0 ? _textPrimary : _textTertiary),
                const SizedBox(height: 4),
                Text(items[i].$2,
                    style: TextStyle(
                        fontSize: 10,
                        color: i == 0 ? _textPrimary : _textTertiary)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The Stress bar chart (olive bars, one highlighted in brand lime) — Stress's
/// existing chart component, kept as the chart for that screen.
class StressBarsChart extends StatelessWidget {
  const StressBarsChart({
    super.key,
    required this.values,
    required this.labels,
    required this.highlight,
  });
  final List<double> values;
  final List<String> labels;
  final int highlight;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StressBars(values, labels, highlight));
}

class _StressBars extends CustomPainter {
  _StressBars(this.values, this.labels, this.highlight);
  final List<double> values;
  final List<String> labels;
  final int highlight;

  @override
  void paint(Canvas canvas, Size size) {
    const maxY = 100.0;
    const rightPad = 28.0;
    const bottomPad = 20.0;
    final plotW = size.width - rightPad;
    final plotH = size.height - bottomPad;
    double yFor(double v) => plotH * (1 - v / maxY);

    final grid = Paint()
      ..color = _border.withOpacity(0.6)
      ..strokeWidth = 1;
    for (final v in [0.0, 50.0, 100.0]) {
      final y = yFor(v);
      canvas.drawLine(Offset(0, y), Offset(plotW, y), grid);
      final tp = TextPainter(
        text: TextSpan(
            text: v.toInt().toString(),
            style: const TextStyle(color: _textTertiary, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plotW + 8, y - tp.height / 2));
    }

    final slot = plotW / values.length;
    final barW = slot * 0.5;
    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - barW / 2, yFor(values[i]), cx + barW / 2, plotH),
        const Radius.circular(5),
      );
      canvas.drawRRect(
          rect, Paint()..color = i == highlight ? _brand : _barOlive);
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: _textTertiary, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, plotH + 5));
    }
  }

  @override
  bool shouldRepaint(_StressBars old) => old.values != values;
}
