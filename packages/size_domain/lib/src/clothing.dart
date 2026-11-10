import 'common.dart';
import 'length.dart';

enum BodyMeasurement {
  height,
  chest,
  bust,
  waist,
  hip,
  insideLeg,
  neck,
}

class MeasurementRange {
  const MeasurementRange({
    required this.minMm,
    required this.maxMm,
  }) : assert(minMm <= maxMm);

  final LengthMm minMm;
  final LengthMm maxMm;

  bool contains(LengthMm value) =>
      value.value >= minMm.value && value.value <= maxMm.value;
}

class ClothingSizeRow {
  const ClothingSizeRow({
    required this.rowKey,
    required this.label,
    required this.ranges,
    this.fitFamily = 'standard',
  });

  final String rowKey;
  final String label;
  final Map<BodyMeasurement, MeasurementRange> ranges;
  final String fitFamily;
}

class ClothingChart {
  const ClothingChart({
    required this.chartId,
    required this.rows,
    required this.provenance,
    required this.measurementPriority,
    required this.confidence,
  });

  final String chartId;
  final List<ClothingSizeRow> rows;
  final Provenance provenance;
  final List<BodyMeasurement> measurementPriority;
  final Confidence confidence;
}

class ClothingRecommendationRequest {
  const ClothingRecommendationRequest({
    required this.measurements,
    this.fitPreference = FitPreference.regular,
    this.fitFamily = 'standard',
  });

  final Map<BodyMeasurement, LengthMm> measurements;
  final FitPreference fitPreference;
  final String fitFamily;
}

class ClothingSizeCandidate {
  const ClothingSizeCandidate({
    required this.rowKey,
    required this.label,
    required this.matchedMeasurements,
    required this.unmatchedMeasurements,
    required this.confidence,
  });

  final String rowKey;
  final String label;
  final Set<BodyMeasurement> matchedMeasurements;
  final Set<BodyMeasurement> unmatchedMeasurements;
  final Confidence confidence;
}

class ClothingRecommendation {
  const ClothingRecommendation({
    required this.status,
    required this.candidates,
    required this.provenance,
    this.warnings = const <RecommendationWarning>[],
  });

  final RecommendationStatus status;
  final List<ClothingSizeCandidate> candidates;
  final Provenance provenance;
  final List<RecommendationWarning> warnings;
}

class ClothingRecommendationEngine {
  const ClothingRecommendationEngine();

  ClothingRecommendation recommend({
    required ClothingRecommendationRequest request,
    required ClothingChart chart,
  }) {
    final List<ClothingSizeRow> familyRows = chart.rows
        .where(
          (ClothingSizeRow row) => row.fitFamily == request.fitFamily,
        )
        .toList(growable: false);

    if (familyRows.isEmpty || request.measurements.isEmpty) {
      return ClothingRecommendation(
        status: RecommendationStatus.unsupported,
        candidates: const <ClothingSizeCandidate>[],
        provenance: chart.provenance,
      );
    }

    final List<ClothingSizeCandidate> scored = familyRows.map(
      (ClothingSizeRow row) {
        final Set<BodyMeasurement> matched = <BodyMeasurement>{};
        final Set<BodyMeasurement> unmatched = <BodyMeasurement>{};
        for (final MapEntry<BodyMeasurement, LengthMm> entry
            in request.measurements.entries) {
          final MeasurementRange? range = row.ranges[entry.key];
          if (range == null) {
            continue;
          }
          if (range.contains(entry.value)) {
            matched.add(entry.key);
          } else {
            unmatched.add(entry.key);
          }
        }
        return ClothingSizeCandidate(
          rowKey: row.rowKey,
          label: row.label,
          matchedMeasurements: matched,
          unmatchedMeasurements: unmatched,
          confidence: chart.confidence,
        );
      },
    ).toList(growable: false)
      ..sort(
        (ClothingSizeCandidate left, ClothingSizeCandidate right) {
          final int matchComparison = right.matchedMeasurements.length
              .compareTo(left.matchedMeasurements.length);
          if (matchComparison != 0) return matchComparison;
          return left.unmatchedMeasurements.length.compareTo(
            right.unmatchedMeasurements.length,
          );
        },
      );

    final int bestMatchCount = scored.first.matchedMeasurements.length;
    if (bestMatchCount == 0) {
      return ClothingRecommendation(
        status: RecommendationStatus.outOfRange,
        candidates: const <ClothingSizeCandidate>[],
        provenance: chart.provenance,
      );
    }

    final int fewestConflicts = scored
        .where(
          (ClothingSizeCandidate candidate) =>
              candidate.matchedMeasurements.length == bestMatchCount,
        )
        .map(
          (ClothingSizeCandidate candidate) =>
              candidate.unmatchedMeasurements.length,
        )
        .reduce((int left, int right) => left < right ? left : right);

    final List<ClothingSizeCandidate> best = scored
        .where(
          (ClothingSizeCandidate candidate) =>
              candidate.matchedMeasurements.length == bestMatchCount &&
              candidate.unmatchedMeasurements.length == fewestConflicts,
        )
        .toList(growable: false);

    final bool hasConflict = best.any(
      (ClothingSizeCandidate candidate) =>
          candidate.unmatchedMeasurements.isNotEmpty,
    );
    return ClothingRecommendation(
      status: best.length == 1 && !hasConflict
          ? RecommendationStatus.resolved
          : RecommendationStatus.multipleCandidates,
      candidates: best,
      provenance: chart.provenance,
      warnings: hasConflict
          ? const <RecommendationWarning>[
              RecommendationWarning(
                code: 'measurement_conflict',
                messageKey: 'clothing.measurementsMapToDifferentSizes',
              ),
            ]
          : const <RecommendationWarning>[],
    );
  }
}
