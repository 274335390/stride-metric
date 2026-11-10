import 'package:flutter_test/flutter_test.dart';
import 'package:stride_metric/core/models.dart';

void main() {
  group('number formatting', () {
    test('removes redundant trailing zeroes', () {
      expect(compactNumber(26.0), '26');
      expect(compactNumber(26.5), '26.5');
      expect(compactNumber(10.24), '10.24');
    });

    test('formats each length unit from internal millimetres', () {
      expect(formatLength(260, LengthUnit.mm), '260 mm');
      expect(formatLength(260, LengthUnit.cm), '26 cm');
      expect(formatLength(260, LengthUnit.inch), '10.24 in');
    });
  });

  test('profile fitting length uses the longer foot', () {
    const profile = ShoeProfile(
      name: 'test',
      audience: Audience.women,
      leftFootMm: 258,
      rightFootMm: 260,
    );
    expect(profile.fittingFootMm, 260);
  });
}
