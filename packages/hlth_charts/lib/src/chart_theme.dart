import 'package:flutter/material.dart';

/// Colour tokens pulled off the Figma reference (node 512:7913).
///
/// One file, one source of truth. If HRV ends up using one purple and SpO2
/// a different purple, the dashboard stops reading as a system — pull the
/// values from here, never inline a hex code in a chart widget.
class HlthChartTokens {
  const HlthChartTokens._();

  // Surface
  static const Color background = Color(0xFF0A0A0F);
  static const Color cardSurface = Color(0xFF1C1C22);
  static const Color cardSurfaceHigh = Color(0xFF26262D);
  static const Color divider = Color(0xFF2E2E36);
  static const Color axis = Color(0xFF38383E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA0);
  static const Color textMuted = Color(0xFF6E6E76);

  // Metric accents
  static const Color hrv = Color(0xFF7B5CFF);       // vivid purple
  static const Color hr = Color(0xFFF27A82);        // coral
  static const Color hrAccent = Color(0xFFB8E86B);  // zone-highlight green
  static const Color stress = Color(0xFFFFA552);    // warm amber
  static const Color spo2 = Color(0xFF9EC9E8);      // sky blue

  // Sleep stage ramp — ordered deep → awake so the hypnogram reads
  // vertically without a legend.
  static const Color sleepDeep = Color(0xFF5B6EC9);
  static const Color sleepLight = Color(0xFFA3B9F5);
  static const Color sleepRem = Color(0xFFC8B5FF);
  static const Color sleepAwake = Color(0xFFFF9B9B);

  // Design-system series accent (the lime "Resting" line on the Chart/Card
  // master) and the muted "Typical range" band behind it.
  static const Color series = Color(0xFFC5E63D);
  static const Color typicalBand = Color(0xFF5E6630);

  // CTA pill buttons ("Try again", "Open Settings") — white fill, dark text.
  static const Color ctaFill = Color(0xFFFFFFFF);
  static const Color ctaText = Color(0xFF0A0A0F);

  // Design-system surfaces (HLTH-App-Flows V1). matteInset is the tab-strip
  // trough, matteElevated the selected tab pill, surfaceRaised the insight
  // pill. dsTextSecondary is the DS's lighter secondary text.
  static const Color matteInset = Color(0xFF100F15);
  static const Color matteElevated = Color(0xFF202326);
  static const Color surfaceRaised = Color(0xFF1C1C1C);
  static const Color dsTextSecondary = Color(0xFFC7C8C8);

  // Insight pill: a small positive-status dot on a raised surface.
  static const Color insightDot = Color(0xFF2FD4A7);

  // Status dot for "Syncing…".
  static const Color syncDot = Color(0xFFC5E63D);

  // Scrub + handle
  static const Color scrubDot = Color(0xFFFFFFFF);
  static const Color scrubDotShadow = Color(0x4D7B5CFF);

  // Gradient for area fills (primary opaque → transparent).
  static List<Color> areaGradient(Color accent) => [
        accent.withOpacity(0.85),
        accent.withOpacity(0.35),
        accent.withOpacity(0.00),
      ];

  static const List<double> areaStops = [0.0, 0.6, 1.0];
}

/// Typography pulled from the Figma. Keeps the chart cards readable at
/// Dynamic Type 2.0 without clipping — any size you add here must be
/// checked at the TextScaleAddon's 2.0 setting.
class HlthChartText {
  const HlthChartText._();

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: HlthChartTokens.textPrimary,
    height: 1.2,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: HlthChartTokens.textSecondary,
    height: 1.2,
  );

  static const TextStyle metricPrimary = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: HlthChartTokens.textPrimary,
    letterSpacing: -0.5,
    height: 1.0,
  );

  static const TextStyle metricSuffix = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: HlthChartTokens.textSecondary,
    letterSpacing: 1.0,
    height: 1.0,
  );

  static const TextStyle axisLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: HlthChartTokens.textMuted,
    letterSpacing: 0.5,
    height: 1.0,
  );

  static const TextStyle rangePill = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
  );
}

/// The Material 3 ThemeData the Widgetbook (and any host app) should use
/// so charts sit on their intended surface without the stories having to
/// paint their own background.
ThemeData hlthDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: HlthChartTokens.background,
    canvasColor: HlthChartTokens.background,
    colorScheme: base.colorScheme.copyWith(
      surface: HlthChartTokens.cardSurface,
      surfaceContainerHighest: HlthChartTokens.cardSurfaceHigh,
      primary: HlthChartTokens.hrv,
      onSurface: HlthChartTokens.textPrimary,
      onSurfaceVariant: HlthChartTokens.textSecondary,
      outline: HlthChartTokens.divider,
      outlineVariant: HlthChartTokens.axis,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: HlthChartTokens.textPrimary,
      displayColor: HlthChartTokens.textPrimary,
    ),
  );
}
