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
    final row = catalog.matchFootLength(260, Audience.women).row!;
    expect(row.eu, 41);
    expect(row.uk, 7.5);
    expect(row.usWomen, 9.5);
    expect(row.jp, 26);
    expect(row.kr, 260);
  });

  test('known EU size resolves back to the same standard row', () {
    final row = catalog.matchKnownSize(SizeSystem.eu, 41, Audience.women).row;
    expect(row, isNotNull);
    expect(row!.footMm, 260);
    expect(row.usWomen, 9.5);
  });

  test('adult values outside the published standard are not clamped', () {
    expect(
      catalog.matchFootLength(205, Audience.women).status,
      MatchStatus.outOfRange,
    );
    expect(
      catalog.matchFootLength(325, Audience.men).status,
      MatchStatus.outOfRange,
    );
  });

  test('known sizes require an exact legal label', () {
    expect(
      catalog.matchKnownSize(SizeSystem.eu, 41.2, Audience.women).status,
      MatchStatus.unsupported,
    );
    expect(
      catalog.matchKnownSize(SizeSystem.eu, 99, Audience.women).status,
      MatchStatus.outOfRange,
    );
  });

  test('EU lookup uses the official EU pivot rather than a chained row', () {
    final row = catalog.matchKnownSize(SizeSystem.eu, 34.5, Audience.women).row;
    expect(row, isNotNull);
    expect(row!.footMm, 215);
    expect(row.uk, 2.5);
    expect(row.usWomen, 4.5);
  });

  test('child US numbering reset can return explicit candidates', () {
    final match = catalog.matchKnownSize(SizeSystem.us, 4, Audience.child);
    expect(match.status, MatchStatus.multipleCandidates);
    expect(match.candidates.map((row) => row.footMm), containsAll([120, 220]));
  });

  test('children standard keeps all directly verified rows', () {
    expect(catalog.childRows, hasLength(38));
    expect(catalog.childRows.first.footMm, 120);
    expect(catalog.childRows.last.footMm, 236);
  });

  test('every published standard foot-length row resolves to itself', () {
    for (final audience in Audience.values) {
      for (final expected in catalog.rowsFor(audience)) {
        final match = catalog.matchFootLength(expected.footMm, audience);
        expect(
          match.row,
          same(expected),
          reason: '${audience.name} ${expected.footMm} mm',
        );
      }
    }
  });

  test('every published label is preserved by exact reverse lookup', () {
    for (final audience in Audience.values) {
      for (final system in SizeSystem.values) {
        final rows = audience == Audience.child
            ? catalog.childRows
            : catalog.adultRowsBySystem[system]!;
        for (final expected in rows) {
          final label = expected.valueFor(system, audience);
          if (label == null) continue;
          final match = catalog.matchKnownSize(system, label, audience);
          expect(
            match.candidates,
            contains(expected),
            reason: '${audience.name} ${system.name} $label',
          );
        }
      }
    }
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

  test('26 cm men result includes every measured official brand match', () {
    final matches = catalog.nearestBrandMatches(
      260,
      Audience.men,
      limit: catalog.brandsFor(Audience.men).length,
    );

    expect(
      matches.map((item) => item.brand).toSet(),
      equals({'adidas', 'Converse', 'New Balance', 'Nike', 'Reebok', 'Vans'}),
    );
  });
}
