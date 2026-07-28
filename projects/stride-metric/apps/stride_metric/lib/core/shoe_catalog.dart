import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

class ShoeCatalog {
  ShoeCatalog._({
    required this.adultRows,
    required this.adultRowsBySystem,
    required this.childRows,
    required this.brands,
  });

  final List<StandardSizeRow> adultRows;
  final Map<SizeSystem, List<StandardSizeRow>> adultRowsBySystem;
  final List<StandardSizeRow> childRows;
  final List<BrandDataset> brands;

  static Future<ShoeCatalog> load() async {
    final adultRaw =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/reference/gbt-36935-2025-adult-recommended.json',
              ),
            )
            as Map<String, dynamic>;
    final childRaw =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/reference/gbt-36935-2025-children.json',
              ),
            )
            as Map<String, dynamic>;
    final registry =
        jsonDecode(
              await rootBundle.loadString('assets/data/brand/registry.json'),
            )
            as Map<String, dynamic>;

    final adultRows =
        ((adultRaw['panels'] as Map<String, dynamic>)['mondopointPivot']
                as List<dynamic>)
            .map((raw) {
              final row = raw as Map<String, dynamic>;
              final mm = (row['mondopoint'] as num).toDouble();
              return StandardSizeRow(
                footMm: mm,
                eu: row['eu'] as num?,
                uk: row['ukAdult'] as num?,
                usMen: row['usMen'] as num?,
                usWomen: row['usWomen'] as num?,
                jp: mm / 10,
                kr: mm,
              );
            })
            .toList(growable: false);
    final adultPanels = adultRaw['panels'] as Map<String, dynamic>;
    List<StandardSizeRow> parseAdultPanel(String panel) =>
        (adultPanels[panel] as List<dynamic>)
            .map((raw) {
              final row = raw as Map<String, dynamic>;
              final mm = (row['mondopoint'] as num).toDouble();
              return StandardSizeRow(
                footMm: mm,
                eu: row['eu'] as num?,
                uk: row['ukAdult'] as num?,
                usMen: row['usMen'] as num?,
                usWomen: row['usWomen'] as num?,
                jp: mm / 10,
                kr: mm,
              );
            })
            .toList(growable: false);
    final adultRowsBySystem = <SizeSystem, List<StandardSizeRow>>{
      SizeSystem.eu: parseAdultPanel('euPivot'),
      SizeSystem.uk: parseAdultPanel('ukPivot'),
      SizeSystem.us: adultRows,
      SizeSystem.jp: adultRows,
      SizeSystem.kr: adultRows,
    };

    final childRows = (childRaw['rows'] as List<dynamic>)
        .map((raw) {
          final row = raw as Map<String, dynamic>;
          final mm = (row['footLengthMm'] as num).toDouble();
          return StandardSizeRow(
            footMm: mm,
            eu: row['eu'] as num?,
            uk: row['ukChild'] as num?,
            usChild: row['usChild'] as num?,
            jp: row['mondopoint'] == null ? null : mm / 10,
            kr: row['mondopoint'] as num?,
          );
        })
        .toList(growable: false);

    final brands = <BrandDataset>[];
    for (final raw in registry['brands'] as List<dynamic>) {
      final entry = raw as Map<String, dynamic>;
      final id = entry['id'] as String;
      final name = entry['name'] as String? ?? id;
      final paths = <String>{
        ...?((entry['datasetPaths'] as List<dynamic>?)?.cast<String>()),
        if (entry['datasetPath'] is String) entry['datasetPath'] as String,
      }.toList();
      for (final path in paths) {
        try {
          final assetPath = path.replaceFirst(
            'data/shoe/brand/',
            'assets/data/brand/',
          );
          final data =
              jsonDecode(await rootBundle.loadString(assetPath))
                  as Map<String, dynamic>;
          brands.add(_parseBrand('$id:${path.split('/').last}', name, data));
        } catch (_) {
          // Registry provenance entries can reference research-only files.
        }
      }
    }
    if (brands.isEmpty) {
      const knownFiles = [
        'adidas-adult.json',
        'adidas-kids.json',
        'asics-men.json',
        'asics-women.json',
        'asics-kids.json',
        'nike-adult.json',
        'nike-kids.json',
        'new-balance-adult.json',
        'new-balance-kids.json',
        'puma-adult.json',
        'puma-kids.json',
        'vans-unisex.json',
        'vans-kids.json',
      ];
      for (final file in knownFiles) {
        final data =
            jsonDecode(await rootBundle.loadString('assets/data/brand/$file'))
                as Map<String, dynamic>;
        brands.add(_parseBrand(file, _brandName(file), data));
      }
    }

    return ShoeCatalog._(
      adultRows: adultRows,
      adultRowsBySystem: adultRowsBySystem,
      childRows: childRows,
      brands: brands,
    );
  }

  static BrandDataset _parseBrand(
    String id,
    String name,
    Map<String, dynamic> data,
  ) {
    final audience = (data['audience'] as String? ?? '').toLowerCase();
    final isWomen = audience.contains('women');
    final isMen = audience.contains('men') && !isWomen;
    final isChild =
        audience.contains('kids') ||
        audience.contains('toddler') ||
        audience.contains('youth') ||
        audience.contains('child');
    final isAdultUnisex =
        audience.contains('adult') && !isWomen && !isMen ||
        audience.contains('unisex');
    final audiences = <Audience>{
      if (isWomen || isAdultUnisex) Audience.women,
      if (isMen || isAdultUnisex) Audience.men,
      if (isChild) Audience.child,
    };
    if (audiences.isEmpty) {
      audiences.addAll({Audience.women, Audience.men});
    }

    final allRows = <List<dynamic>>[];
    List<String> columns =
        (data['columns'] as List<dynamic>?)?.cast<String>() ?? const [];
    final segments = (data['segments'] as List<dynamic>?) ?? const [];
    if (segments.isEmpty && data['rows'] is List<dynamic>) {
      allRows.addAll(
        (data['rows'] as List<dynamic>).map(
          (e) => List<dynamic>.from(e as List),
        ),
      );
    }
    for (final segmentRaw in segments) {
      final segment = segmentRaw as Map<String, dynamic>;
      final segmentColumns =
          (segment['columns'] as List<dynamic>?)?.cast<String>() ?? columns;
      columns = columns.isEmpty ? segmentColumns : columns;
      for (final row in (segment['rows'] as List<dynamic>?) ?? const []) {
        final values = List<dynamic>.from(row as List);
        if (segmentColumns.length == columns.length) allRows.add(values);
      }
    }
    return BrandDataset(
      id: id,
      name: name,
      audiences: audiences,
      columns: columns,
      rows: allRows,
      note: data['scopeNote'] as String?,
    );
  }

  static String _brandName(String file) {
    if (file.startsWith('new-balance')) return 'New Balance';
    return switch (file.split('-').first) {
      'nike' => 'Nike',
      'adidas' => 'adidas',
      'asics' => 'ASICS',
      'puma' => 'PUMA',
      'vans' => 'Vans',
      _ => file,
    };
  }

  List<StandardSizeRow> rowsFor(Audience audience) =>
      audience == Audience.child ? childRows : adultRows;

  CatalogMatch matchFootLength(double footMm, Audience audience) {
    if (!footMm.isFinite || footMm <= 0) {
      return const CatalogMatch.invalidInput();
    }
    final rows = rowsFor(audience);
    if (rows.isEmpty) return const CatalogMatch.unsupported();
    if (footMm < rows.first.footMm || footMm > rows.last.footMm) {
      return const CatalogMatch.outOfRange();
    }
    for (final row in rows) {
      if ((row.footMm - footMm).abs() < 0.000001) {
        return CatalogMatch.withMatch(row);
      }
    }
    for (var index = 0; index < rows.length - 1; index++) {
      final lower = rows[index];
      final upper = rows[index + 1];
      if (footMm <= lower.footMm || footMm >= upper.footMm) continue;
      final midpoint = (lower.footMm + upper.footMm) / 2;
      if ((footMm - midpoint).abs() < 0.000001) {
        return CatalogMatch.multiple([lower, upper]);
      }
      return CatalogMatch.withMatch(footMm < midpoint ? lower : upper);
    }
    return const CatalogMatch.unsupported();
  }

  CatalogMatch matchKnownSize(SizeSystem system, num value, Audience audience) {
    final numericValue = value.toDouble();
    if (!numericValue.isFinite || numericValue <= 0) {
      return const CatalogMatch.invalidInput();
    }
    final rows = audience == Audience.child
        ? childRows
        : adultRowsBySystem[system] ?? const <StandardSizeRow>[];
    if (rows.isEmpty) return const CatalogMatch.unsupported();
    final available = <double>[];
    final matches = <StandardSizeRow>[];
    for (final row in rows) {
      final candidate = row.valueFor(system, audience);
      if (candidate == null) continue;
      available.add(candidate.toDouble());
      if ((candidate.toDouble() - numericValue).abs() < 0.000001) {
        matches.add(row);
      }
    }
    if (available.isEmpty) return const CatalogMatch.unsupported();
    if (numericValue < available.reduce((a, b) => a < b ? a : b) ||
        numericValue > available.reduce((a, b) => a > b ? a : b)) {
      return const CatalogMatch.outOfRange();
    }
    if (matches.isEmpty) return const CatalogMatch.unsupported();
    if (matches.length > 1) return CatalogMatch.multiple(matches);
    return CatalogMatch.withMatch(matches.single);
  }

  List<BrandDataset> brandsFor(Audience audience) {
    final seen = <String>{};
    return brands
        .where((dataset) => dataset.supports(audience))
        .where((dataset) => seen.add(dataset.name))
        .toList(growable: false);
  }

  List<BrandSizeMatch> nearestBrandMatches(
    double footMm,
    Audience audience, {
    int limit = 4,
  }) {
    final matches = <BrandSizeMatch>[];
    for (final brand in brandsFor(audience)) {
      final columns = brand.columns;
      int indexOf(List<String> candidates) {
        for (final candidate in candidates) {
          final index = columns.indexOf(candidate);
          if (index >= 0) return index;
        }
        return -1;
      }

      final footIndex = indexOf([
        'footLengthMm',
        'heelToeMm',
        'heelToeCm',
        'footLengthCm',
        'lengthCm',
        'footLengthIn',
        'lengthIn',
      ]);
      if (footIndex < 0) continue;

      double? rowFootMm(List<dynamic> row) {
        if (footIndex >= row.length) return null;
        final raw = row[footIndex];
        final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
        if (value == null) return null;
        final column = columns[footIndex];
        if (column.endsWith('Mm')) return value;
        if (column.endsWith('In')) return value * 25.4;
        return value * 10;
      }

      final measuredRows = <(double, List<dynamic>)>[];
      for (final row in brand.rows) {
        final measured = rowFootMm(row);
        if (measured == null) continue;
        measuredRows.add((measured, row));
      }
      if (measuredRows.isEmpty) continue;
      measuredRows.sort((a, b) => a.$1.compareTo(b.$1));
      if (footMm < measuredRows.first.$1 || footMm > measuredRows.last.$1) {
        continue;
      }
      List<dynamic>? closest;
      for (var index = 0; index < measuredRows.length; index++) {
        final current = measuredRows[index];
        if ((current.$1 - footMm).abs() < 0.000001) {
          closest = current.$2;
          break;
        }
        if (index == measuredRows.length - 1) continue;
        final next = measuredRows[index + 1];
        if (footMm > current.$1 && footMm < next.$1) {
          final midpoint = (current.$1 + next.$1) / 2;
          closest = footMm <= midpoint ? current.$2 : next.$2;
          break;
        }
      }
      if (closest == null) continue;

      Object? read(List<dynamic> row, int index) =>
          index < 0 || index >= row.length ? null : row[index];
      final usIndex = audience == Audience.men
          ? indexOf(['usMen', 'us', 'usKids', 'usYouth', 'usToddler'])
          : audience == Audience.women
          ? indexOf(['usWomen', 'us', 'usKids', 'usYouth', 'usToddler'])
          : indexOf(['usKids', 'usYouth', 'usToddler', 'us']);
      final measured = rowFootMm(closest);
      if (measured == null) continue;
      matches.add(
        BrandSizeMatch(
          brand: brand.name,
          footMm: measured,
          eu: read(closest, indexOf(['eu', 'euDisplay', 'de'])),
          uk: read(closest, indexOf(['uk'])),
          us: read(closest, usIndex),
          label: read(
            closest,
            indexOf([
              'jpLabelCm',
              'jpLabelMm',
              'cmLabel',
              'cmJpLabel',
              'japanLabelCm',
            ]),
          ),
        ),
      );
    }
    matches.sort(
      (a, b) => (a.footMm - footMm).abs().compareTo((b.footMm - footMm).abs()),
    );
    return matches.take(limit).toList(growable: false);
  }
}
