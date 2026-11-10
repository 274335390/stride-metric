import 'common.dart';
import 'length.dart';

enum ShoeSelectionPolicy {
  /// Only a source-defined applicable range may resolve.
  rangeOnly,

  /// The source explicitly instructs users between anchors to size up.
  ceilingAnchor,
}

class ShoeChartRow {
  const ShoeChartRow({
    required this.rowKey,
    required this.audience,
    required this.labels,
    this.footLengthAnchorMm,
    this.applicableFootMinMm,
    this.applicableFootMaxMm,
    this.widthLabels = const <String, String>{},
  }) : assert(
          (applicableFootMinMm == null && applicableFootMaxMm == null) ||
              (applicableFootMinMm != null && applicableFootMaxMm != null),
          'An applicable range requires both bounds.',
        );

  final String rowKey;
  final Audience audience;
  final Map<String, String> labels;
  final LengthMm? footLengthAnchorMm;
  final LengthMm? applicableFootMinMm;
  final LengthMm? applicableFootMaxMm;
  final Map<String, String> widthLabels;

  bool contains(LengthMm footLength) {
    final LengthMm? min = applicableFootMinMm;
    final LengthMm? max = applicableFootMaxMm;
    return min != null &&
        max != null &&
        footLength.value >= min.value &&
        footLength.value <= max.value;
  }
}

class ShoeChart {
  const ShoeChart({
    required this.chartId,
    required this.rows,
    required this.provenance,
    required this.confidence,
    this.selectionPolicy = ShoeSelectionPolicy.rangeOnly,
  });

  final String chartId;
  final List<ShoeChartRow> rows;
  final Provenance provenance;
  final Confidence confidence;
  final ShoeSelectionPolicy selectionPolicy;
}

class ShoeRecommendationRequest {
  const ShoeRecommendationRequest({
    required this.footLength,
    required this.audience,
    required this.targetSystems,
  });

  final LengthMm footLength;
  final Audience audience;
  final Set<String> targetSystems;
}

class ShoeSizeCandidate {
  const ShoeSizeCandidate({
    required this.rowKey,
    required this.labels,
    required this.confidence,
  });

  final String rowKey;
  final Map<String, String> labels;
  final Confidence confidence;
}

class ShoeRecommendation {
  const ShoeRecommendation({
    required this.status,
    required this.candidates,
    required this.provenance,
    this.warnings = const <RecommendationWarning>[],
  });

  final RecommendationStatus status;
  final List<ShoeSizeCandidate> candidates;
  final Provenance provenance;
  final List<RecommendationWarning> warnings;
}

class ShoeConversionEngine {
  const ShoeConversionEngine();

  ShoeRecommendation recommendByFootLength({
    required ShoeRecommendationRequest request,
    required ShoeChart chart,
  }) {
    final List<ShoeChartRow> audienceRows = chart.rows
        .where((ShoeChartRow row) => row.audience == request.audience)
        .toList(growable: false);

    if (audienceRows.isEmpty) {
      return ShoeRecommendation(
        status: RecommendationStatus.unsupported,
        candidates: const <ShoeSizeCandidate>[],
        provenance: chart.provenance,
        warnings: const <RecommendationWarning>[
          RecommendationWarning(
            code: 'audience_not_covered',
            messageKey: 'shoe.audienceNotCovered',
          ),
        ],
      );
    }

    List<ShoeChartRow> matchedRows = audienceRows
        .where((ShoeChartRow row) => row.contains(request.footLength))
        .toList(growable: false);

    if (matchedRows.isEmpty &&
        chart.selectionPolicy == ShoeSelectionPolicy.ceilingAnchor) {
      final List<ShoeChartRow> anchored = audienceRows
          .where((ShoeChartRow row) => row.footLengthAnchorMm != null)
          .toList()
        ..sort(
          (ShoeChartRow left, ShoeChartRow right) =>
              left.footLengthAnchorMm!.value.compareTo(
                right.footLengthAnchorMm!.value,
              ),
        );
      matchedRows = anchored
          .where(
            (ShoeChartRow row) =>
                row.footLengthAnchorMm!.value >= request.footLength.value,
          )
          .take(1)
          .toList(growable: false);
    }

    if (matchedRows.isEmpty) {
      return ShoeRecommendation(
        status: RecommendationStatus.outOfRange,
        candidates: const <ShoeSizeCandidate>[],
        provenance: chart.provenance,
      );
    }

    final List<ShoeSizeCandidate> candidates = matchedRows
        .map(
          (ShoeChartRow row) => ShoeSizeCandidate(
            rowKey: row.rowKey,
            labels: <String, String>{
              for (final String system in request.targetSystems)
                if (row.labels[system] case final String value) system: value,
            },
            confidence: chart.confidence,
          ),
        )
        .toList(growable: false);

    return ShoeRecommendation(
      status: candidates.length == 1
          ? RecommendationStatus.resolved
          : RecommendationStatus.multipleCandidates,
      candidates: candidates,
      provenance: chart.provenance,
      warnings: candidates.length == 1
          ? const <RecommendationWarning>[]
          : const <RecommendationWarning>[
              RecommendationWarning(
                code: 'shared_boundary',
                messageKey: 'shoe.multipleCandidatesAtBoundary',
              ),
            ],
    );
  }
}
