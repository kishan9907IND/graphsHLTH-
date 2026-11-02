import 'package:flutter/painting.dart';

/// Coordinate maths used by every chart painter in the package. Centralises
/// the value→pixel transform so every chart agrees on how to position a
/// datapoint for the scrub overlay.
class ChartGeometry {
  ChartGeometry({
    required this.size,
    required this.minY,
    required this.maxY,
    required this.insets,
  }) : assert(maxY > minY);

  final Size size;
  final double minY;
  final double maxY;

  /// Space reserved for axis labels / baseline captions. Charts without
  /// labels pass EdgeInsets.zero.
  final EdgeInsets insets;

  double get plotWidth => size.width - insets.left - insets.right;
  double get plotHeight => size.height - insets.top - insets.bottom;

  /// Map a 0-based point index to the x pixel position (centre of its
  /// slot). Pass [count] because an area chart treats indices as fence
  /// posts (count-1 segments) while a bar chart treats them as rails
  /// (count slots).
  double xForIndex(int index, int count, {bool fencePost = true}) {
    if (count <= 1) return insets.left + plotWidth / 2;
    if (fencePost) {
      return insets.left + plotWidth * index / (count - 1);
    }
    final slot = plotWidth / count;
    return insets.left + slot * index + slot / 2;
  }

  /// Map a 0..1 fraction across the window to an x pixel position. Used
  /// when points are placed by timestamp (so gaps show as gaps) rather
  /// than by index.
  double xForFraction(double f) => insets.left + plotWidth * f.clamp(0.0, 1.0);

  double yForValue(double v) {
    final clamped = v.clamp(minY, maxY);
    final t = (clamped - minY) / (maxY - minY);
    return insets.top + plotHeight * (1 - t);
  }
}
