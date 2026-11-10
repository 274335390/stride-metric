enum LengthUnit {
  millimeter,
  centimeter,
  inch,
}

/// Canonical length used by the domain engine.
///
/// All matching is performed with integer millimeters. The data layer remains
/// responsible for preserving the exact source value and source unit for
/// audit and display.
extension type const LengthMm(int value) implements int {
  factory LengthMm.from(num value, LengthUnit unit) {
    final double millimeters = switch (unit) {
      LengthUnit.millimeter => value.toDouble(),
      LengthUnit.centimeter => value.toDouble() * 10,
      LengthUnit.inch => value.toDouble() * 25.4,
    };
    return LengthMm(millimeters.round());
  }

  double asCentimeters() => value / 10;

  double asInches() => value / 25.4;
}
