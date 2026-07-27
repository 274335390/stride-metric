import 'package:flutter_test/flutter_test.dart';
import 'package:stride_metric/core/models.dart';
import 'package:stride_metric/core/shoe_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShoeCatalog catalog;

  setUpAll(() async {
    catalog = await ShoeCatalog.load();
  });

  test('adult standard contains the verified 215–320 mm rows', () {
    expect(catalog.adultRows, hasLength(22));
    expect(catalog.adultRows.first.footMm, 215);
    expect(catalog.adultRows.last.footMm, 320);
  });

  test('260 mm women standard conversion is exact', () {
    final row = catalog.nearest(260, Audience.women);
    expect(row.eu, 41);
    expect(row.uk, 7.5);
    expect(row.usWomen, 9.5);
    expect(row.jp, 26);
    expect(row.kr, 260);
  });

  test('known EU size resolves back to the same standard row', () {
    final row = catalog.byKnownSize(SizeSystem.eu, 41, Audience.women);
    expect(row, isNotNull);
    expect(row!.footMm, 260);
    expect(row.usWomen, 9.5);
  });

  test('children standard keeps all directly verified rows', () {
    expect(catalog.childRows, hasLength(38));
    expect(catalog.childRows.first.footMm, 120);
    expect(catalog.childRows.last.footMm, 236);
  });

  test('adidas child chart is present with all 36 official rows', () {
    final datasets = catalog.brands.where(
      (item) => item.name == 'adidas' && item.supports(Audience.child),
    );
    expect(datasets, isNotEmpty);
    expect(datasets.first.rows, hasLength(36));
  });

  test(
    'brand matching keeps measured foot length separate from shoe label',
    () {
      final matches = catalog.nearestBrandMatches(
        260,
        Audience.women,
        limit: 9,
      );
      final nike = matches.firstWhere((item) => item.brand == 'Nike');
      expect(nike.footMm, 258);
      expect(nike.eu, 42);
      expect(nike.us, 10);
      expect(nike.label, 26.5);
    },
  );
}
