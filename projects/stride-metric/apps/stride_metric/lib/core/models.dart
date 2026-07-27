enum Audience { women, men, child }

enum LengthUnit { mm, cm, inch }

enum ConversionInput { footLength, knownSize }

enum SizeSystem { eu, uk, us, jp, kr }

extension LengthUnitText on LengthUnit {
  String get symbol => switch (this) {
    LengthUnit.mm => 'mm',
    LengthUnit.cm => 'cm',
    LengthUnit.inch => 'in',
  };
}

extension SizeSystemText on SizeSystem {
  String get label => name.toUpperCase();
}

String compactNumber(num? value, {int maxDecimals = 2}) {
  if (value == null) return '—';
  var fixed = value.toStringAsFixed(maxDecimals);
  if (!fixed.contains('.')) return fixed;
  fixed = fixed.replaceFirst(RegExp(r'0+$'), '');
  return fixed.replaceFirst(RegExp(r'\.$'), '');
}

double displayLength(double mm, LengthUnit unit) => switch (unit) {
  LengthUnit.mm => mm,
  LengthUnit.cm => mm / 10,
  LengthUnit.inch => mm / 25.4,
};

double toMillimetres(double value, LengthUnit unit) => switch (unit) {
  LengthUnit.mm => value,
  LengthUnit.cm => value * 10,
  LengthUnit.inch => value * 25.4,
};

String formatLength(double mm, LengthUnit unit) {
  final decimals = unit == LengthUnit.inch
      ? 2
      : unit == LengthUnit.cm
      ? 1
      : 0;
  return '${compactNumber(displayLength(mm, unit), maxDecimals: decimals)} ${unit.symbol}';
}

class StandardSizeRow {
  const StandardSizeRow({
    required this.footMm,
    this.eu,
    this.uk,
    this.usMen,
    this.usWomen,
    this.usChild,
    this.jp,
    this.kr,
  });

  final double footMm;
  final num? eu;
  final num? uk;
  final num? usMen;
  final num? usWomen;
  final num? usChild;
  final num? jp;
  final num? kr;

  num? usFor(Audience audience) => switch (audience) {
    Audience.women => usWomen,
    Audience.men => usMen,
    Audience.child => usChild,
  };

  num? valueFor(SizeSystem system, Audience audience) => switch (system) {
    SizeSystem.eu => eu,
    SizeSystem.uk => uk,
    SizeSystem.us => usFor(audience),
    SizeSystem.jp => jp,
    SizeSystem.kr => kr,
  };
}

class BrandDataset {
  const BrandDataset({
    required this.id,
    required this.name,
    required this.audiences,
    required this.columns,
    required this.rows,
    this.note,
  });

  final String id;
  final String name;
  final Set<Audience> audiences;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final String? note;

  bool supports(Audience audience) => audiences.contains(audience);
}

class BrandSizeMatch {
  const BrandSizeMatch({
    required this.brand,
    required this.footMm,
    required this.eu,
    required this.uk,
    required this.us,
    required this.label,
  });

  final String brand;
  final double footMm;
  final Object? eu;
  final Object? uk;
  final Object? us;
  final Object? label;
}

class ConversionResult {
  const ConversionResult({
    required this.row,
    required this.audience,
    required this.input,
    this.inputSystem,
    this.inputValue,
  });

  final StandardSizeRow row;
  final Audience audience;
  final ConversionInput input;
  final SizeSystem? inputSystem;
  final num? inputValue;
}

class ShoeProfile {
  const ShoeProfile({
    required this.name,
    required this.audience,
    required this.leftFootMm,
    required this.rightFootMm,
    this.width = 'regular',
  });

  final String name;
  final Audience audience;
  final double leftFootMm;
  final double rightFootMm;
  final String width;

  double get fittingFootMm =>
      leftFootMm >= rightFootMm ? leftFootMm : rightFootMm;
}
