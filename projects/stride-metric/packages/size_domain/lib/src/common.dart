enum RecommendationStatus {
  resolved,
  multipleCandidates,
  outOfRange,
  unsupported,
  sourceConflict,
}

enum Confidence {
  brandProductExact,
  brandExact,
  brandReference,
  standardReference,
  marketApproximation,
  insufficientData,
}

enum Audience {
  adultMen,
  adultWomen,
  unisexAdult,
  infantToddler,
  littleKids,
  bigKidsYouth,
  kidsUnspecified,
}

enum FitPreference {
  slim,
  regular,
  relaxed,
}

class Provenance {
  const Provenance({
    required this.datasetId,
    required this.sourceIds,
    required this.retrievedAt,
    required this.market,
    this.brandId,
    this.productFamilyId,
  });

  final String datasetId;
  final List<String> sourceIds;
  final DateTime retrievedAt;
  final String market;
  final String? brandId;
  final String? productFamilyId;
}

class RecommendationWarning {
  const RecommendationWarning({
    required this.code,
    required this.messageKey,
    this.fields = const <String>[],
  });

  final String code;
  final String messageKey;
  final List<String> fields;
}
