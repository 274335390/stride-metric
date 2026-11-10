import 'package:size_domain/size_domain.dart';

void main() {
  final Provenance provenance = Provenance(
    datasetId: 'fixture',
    sourceIds: const <String>['official_fixture'],
    retrievedAt: DateTime.utc(2026, 7, 26),
    market: 'US',
    brandId: 'fixture_brand',
  );

  final ShoeChart childChart = ShoeChart(
    chartId: 'child_fixture',
    provenance: provenance,
    confidence: Confidence.brandExact,
    rows: const <ShoeChartRow>[
      ShoeChartRow(
        rowKey: 'little-1',
        audience: Audience.littleKids,
        labels: <String, String>{'usKids': '1', 'eu': '32'},
        applicableFootMinMm: LengthMm(194),
        applicableFootMaxMm: LengthMm(199),
      ),
      ShoeChartRow(
        rowKey: 'youth-1',
        audience: Audience.bigKidsYouth,
        labels: <String, String>{'usKids': '1', 'eu': '32'},
        applicableFootMinMm: LengthMm(200),
        applicableFootMaxMm: LengthMm(205),
      ),
    ],
  );

  const ShoeConversionEngine shoeEngine = ShoeConversionEngine();
  final ShoeRecommendation childResult = shoeEngine.recommendByFootLength(
    request: const ShoeRecommendationRequest(
      footLength: LengthMm(197),
      audience: Audience.littleKids,
      targetSystems: <String>{'usKids', 'eu'},
    ),
    chart: childChart,
  );
  assert(childResult.status == RecommendationStatus.resolved);
  assert(childResult.candidates.single.rowKey == 'little-1');

  final ShoeRecommendation outOfRange = shoeEngine.recommendByFootLength(
    request: const ShoeRecommendationRequest(
      footLength: LengthMm(250),
      audience: Audience.littleKids,
      targetSystems: <String>{'eu'},
    ),
    chart: childChart,
  );
  assert(outOfRange.status == RecommendationStatus.outOfRange);

  final ClothingChart clothingChart = ClothingChart(
    chartId: 'clothing_fixture',
    provenance: provenance,
    confidence: Confidence.brandExact,
    measurementPriority: const <BodyMeasurement>[
      BodyMeasurement.bust,
      BodyMeasurement.waist,
    ],
    rows: const <ClothingSizeRow>[
      ClothingSizeRow(
        rowKey: 'm',
        label: 'M',
        ranges: <BodyMeasurement, MeasurementRange>{
          BodyMeasurement.bust: MeasurementRange(
            minMm: LengthMm(880),
            maxMm: LengthMm(940),
          ),
          BodyMeasurement.waist: MeasurementRange(
            minMm: LengthMm(700),
            maxMm: LengthMm(760),
          ),
        },
      ),
      ClothingSizeRow(
        rowKey: 'l',
        label: 'L',
        ranges: <BodyMeasurement, MeasurementRange>{
          BodyMeasurement.bust: MeasurementRange(
            minMm: LengthMm(940),
            maxMm: LengthMm(1000),
          ),
          BodyMeasurement.waist: MeasurementRange(
            minMm: LengthMm(760),
            maxMm: LengthMm(820),
          ),
        },
      ),
    ],
  );

  const ClothingRecommendationEngine clothingEngine =
      ClothingRecommendationEngine();
  final ClothingRecommendation clothingResult = clothingEngine.recommend(
    request: const ClothingRecommendationRequest(
      measurements: <BodyMeasurement, LengthMm>{
        BodyMeasurement.bust: LengthMm(930),
        BodyMeasurement.waist: LengthMm(780),
      },
    ),
    chart: clothingChart,
  );
  assert(
    clothingResult.status == RecommendationStatus.multipleCandidates,
  );
  assert(
    clothingResult.warnings.any(
      (RecommendationWarning warning) =>
          warning.code == 'measurement_conflict',
    ),
  );
}
