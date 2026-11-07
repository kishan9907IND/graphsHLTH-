import 'package:flutter/material.dart';
import 'package:hlth_charts/hlth_charts.dart';

/// Literal build of the Figma Stress screen (HLTH-App-Flows V1, node
/// 658:12415). Tokens taken from that file. The article-card photos can't be
/// fetched through this environment's proxy, so those tiles use a styled
/// placeholder; everything else is built as-is.
class StressScreen extends StatefulWidget {
  const StressScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<StressScreen> createState() => _StressScreenState();
}

// Figma tokens.
const _bg = Color(0xFF0A0A0A);
const _surfaceRaised = Color(0xFF1C1C1C);
const _border = Color(0xFF333536);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFC7C8C8);
const _textTertiary = Color(0xFF9A99A1);
const _green = Color(0xFF22C55E);
const _brand = Color(0xFFD0ED29);
const _barOlive = Color(0xFF8CA23E);

class _StressScreenState extends State<StressScreen> {
  TimeRange _range = TimeRange.week;

  // Literal data from the reference.
  static const _values = [40.0, 52.0, 58.0, 48.0, 54.0, 33.0, 42.0];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _highlight = 2; // Wed

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Column(
        children: [
          _statusBar(),
          _appBar(),
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
                  _header(),
                  const SizedBox(height: 14),
                  PeriodNavigator(
                    label: '21–27 Sep',
                    onPrev: () {},
                    onNext: () {},
                  ),
                  const SizedBox(height: 12),
                  _chartCard(),
                  const SizedBox(height: 16),
                  _askCopilot(),
                  const SizedBox(height: 12),
                  _lowestHighest(),
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
          children: [
            const Text('9:41',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, size: 16, color: _textPrimary),
                SizedBox(width: 5),
                Icon(Icons.wifi, size: 16, color: _textPrimary),
                SizedBox(width: 5),
                Icon(Icons.battery_full, size: 18, color: _textPrimary),
              ],
            ),
          ],
        ),
      );

  Widget _appBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            _circleButton(Icons.arrow_back_ios_new, widget.onBack),
            const Expanded(
              child: Text('Stress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

  Widget _header() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Stress',
                    style: TextStyle(color: _textSecondary, fontSize: 14)),
                SizedBox(height: 2),
                Text('42',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 48,
                        height: 1.0,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Weekly average',
                    style: TextStyle(color: _textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('28–66',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Moderate Range',
                  style: TextStyle(
                      color: _green, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      );

  Widget _chartCard() => Container(
        height: 190,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        decoration: BoxDecoration(
          color: _surfaceRaised,
          borderRadius: BorderRadius.circular(24),
        ),
        child: CustomPaint(
          painter: _StressBars(
            values: _values,
            labels: _labels,
            highlight: _highlight,
          ),
        ),
      );

  Widget _askCopilot() => Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [_brand, Color(0xFF7B5CFF), Color(0xFF46CEE8)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _surfaceRaised,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: _brand),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Ask Copilot about this week',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.chevron_right, color: _textSecondary),
            ],
          ),
        ),
      );

  Widget _lowestHighest() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceRaised,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(child: _stat('LOWEST', '33', 'Sat, 26 Sep')),
            Container(width: 1, height: 44, color: _border),
            const SizedBox(width: 16),
            Expanded(child: _stat('HIGHEST', '58', 'Wed, 23 Sep')),
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
                  fontSize: 26,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 12)),
        ],
      );

  Widget _bandsRow() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _surfaceRaised,
          borderRadius: BorderRadius.circular(20),
        ),
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
          children: [
            _articleCard(),
            const SizedBox(width: 12),
            _articleCard(),
          ],
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
                  shape: BoxShape.circle,
                ),
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
                color: _brand, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 5),
          _dot(),
          const SizedBox(width: 5),
          _dot(),
        ],
      );

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: _border, shape: BoxShape.circle),
      );

  Widget _bottomNav() {
    const items = [
      (Icons.home, 'Home'),
      (Icons.directions_run, 'Workout'),
      (Icons.add, 'Insights'),
      (Icons.watch, 'Device'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1,
                    size: 22,
                    color: i == 0 ? _textPrimary : _textTertiary),
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

class _StressBars extends CustomPainter {
  _StressBars({
    required this.values,
    required this.labels,
    required this.highlight,
  });
  final List<double> values;
  final List<String> labels;
  final int highlight;

  @override
  void paint(Canvas canvas, Size size) {
    const maxY = 100.0;
    const rightPad = 28.0; // room for Y labels
    const bottomPad = 20.0;
    final plotW = size.width - rightPad;
    final plotH = size.height - bottomPad;

    double yFor(double v) => plotH * (1 - v / maxY);

    // Horizontal gridlines + right-side Y labels at 0 / 50 / 100.
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

    // Bars.
    final slot = plotW / values.length;
    final barW = slot * 0.5;
    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final top = yFor(values[i]);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - barW / 2, top, cx + barW / 2, plotH),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = i == highlight ? _brand : _barOlive,
      );
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
