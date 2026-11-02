/// A continuous span of one sleep stage. A night is a list of these,
/// contiguous in time, with [start] of one equal to [end] of the previous.
///
/// Sleep is categorical, not scalar — a mean doesn't mean anything. The
/// chart renders stacked bars whose height is the stage's position in the
/// awake→deep ramp rather than a value.
class SleepSegment {
  const SleepSegment({
    required this.start,
    required this.end,
    required this.stage,
  }) : assert(end != start);

  final DateTime start;
  final DateTime end;
  final SleepStage stage;

  Duration get duration => end.difference(start);
}

enum SleepStage {
  awake(order: 3, label: 'Awake'),
  rem(order: 2, label: 'REM'),
  light(order: 1, label: 'Light'),
  deep(order: 0, label: 'Deep');

  const SleepStage({required this.order, required this.label});
  final int order;
  final String label;
}
