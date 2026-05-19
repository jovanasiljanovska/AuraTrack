/// Exercise from the ExerciseDB RapidAPI.
///
/// The /exercises endpoint returns the core fields (id, name, image, body parts,
/// equipment, muscles, keywords). The /exercises/{id} detail endpoint adds the
/// rich content fields (video, overview, instructions, tips, variations,
/// related exercises, multi-resolution images).
///
/// Both shapes parse into this single class — the detail-only fields are
/// nullable and just stay null when the model came from the list endpoint.
class Exercise {
  // ----- Core (both endpoints) -----
  final String exerciseId;
  final String name;
  final String? imageUrl;
  final List<String> bodyParts;
  final List<String> equipments;
  final String exerciseType;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> keywords;

  // ----- Detail endpoint only -----
  final ExerciseImageUrls? imageUrls;
  final String? videoUrl;
  final String? overview;
  final List<String> instructions;
  final List<String> exerciseTips;
  final List<String> variations;
  final List<String> relatedExerciseIds;

  Exercise({
    required this.exerciseId,
    required this.name,
    this.imageUrl,
    this.bodyParts = const [],
    this.equipments = const [],
    required this.exerciseType,
    this.targetMuscles = const [],
    this.secondaryMuscles = const [],
    this.keywords = const [],
    this.imageUrls,
    this.videoUrl,
    this.overview,
    this.instructions = const [],
    this.exerciseTips = const [],
    this.variations = const [],
    this.relatedExerciseIds = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      bodyParts: _stringList(json['bodyParts']),
      equipments: _stringList(json['equipments']),
      exerciseType: json['exerciseType'] ?? 'STRENGTH',
      targetMuscles: _stringList(json['targetMuscles']),
      secondaryMuscles: _stringList(json['secondaryMuscles']),
      keywords: _stringList(json['keywords']),
      imageUrls: json['imageUrls'] is Map
          ? ExerciseImageUrls.fromJson(
          Map<String, dynamic>.from(json['imageUrls']))
          : null,
      videoUrl: json['videoUrl'],
      overview: json['overview'],
      instructions: _stringList(json['instructions']),
      exerciseTips: _stringList(json['exerciseTips']),
      variations: _stringList(json['variations']),
      relatedExerciseIds: _stringList(json['relatedExerciseIds']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  // ----- Convenience getters for the UI -----

  String get primaryBodyPart =>
      bodyParts.isNotEmpty ? bodyParts.first : 'GENERAL';

  String get primaryEquipment =>
      equipments.isNotEmpty ? equipments.first : 'BODY WEIGHT';

  /// True when we've loaded the detail endpoint, false for list-only data.
  /// Useful in the detail screen to decide whether to show a spinner or
  /// just render the existing object.
  bool get hasDetail => overview != null || instructions.isNotEmpty;

  /// Returns the best image URL for a given pixel height, falling back to
  /// the basic [imageUrl] if the detail endpoint hasn't been fetched yet.
  String? bestImageFor({int targetHeight = 480}) {
    if (imageUrls != null) {
      return imageUrls!.pickClosest(targetHeight);
    }
    return imageUrl;
  }

  /// Merge a freshly-fetched detail object into this one. Used when the user
  /// taps an exercise in the list — we keep all existing fields and overlay
  /// the rich detail fields on top so nothing is lost.
  Exercise mergeWith(Exercise detail) {
    return Exercise(
      exerciseId: detail.exerciseId,
      name: detail.name,
      imageUrl: detail.imageUrl ?? imageUrl,
      bodyParts: detail.bodyParts.isNotEmpty ? detail.bodyParts : bodyParts,
      equipments: detail.equipments.isNotEmpty ? detail.equipments : equipments,
      exerciseType: detail.exerciseType,
      targetMuscles:
      detail.targetMuscles.isNotEmpty ? detail.targetMuscles : targetMuscles,
      secondaryMuscles: detail.secondaryMuscles.isNotEmpty
          ? detail.secondaryMuscles
          : secondaryMuscles,
      keywords: detail.keywords.isNotEmpty ? detail.keywords : keywords,
      imageUrls: detail.imageUrls ?? imageUrls,
      videoUrl: detail.videoUrl ?? videoUrl,
      overview: detail.overview ?? overview,
      instructions:
      detail.instructions.isNotEmpty ? detail.instructions : instructions,
      exerciseTips:
      detail.exerciseTips.isNotEmpty ? detail.exerciseTips : exerciseTips,
      variations: detail.variations.isNotEmpty ? detail.variations : variations,
      relatedExerciseIds: detail.relatedExerciseIds.isNotEmpty
          ? detail.relatedExerciseIds
          : relatedExerciseIds,
    );
  }
}

/// Multi-resolution image URLs from the detail endpoint.
class ExerciseImageUrls {
  final String? p360;
  final String? p480;
  final String? p720;
  final String? p1080;

  ExerciseImageUrls({this.p360, this.p480, this.p720, this.p1080});

  factory ExerciseImageUrls.fromJson(Map<String, dynamic> json) {
    return ExerciseImageUrls(
      p360: json['360p'],
      p480: json['480p'],
      p720: json['720p'],
      p1080: json['1080p'],
    );
  }

  /// Pick the resolution closest to (but not below) [targetHeight].
  /// Falls back to whatever is available if the ideal size is missing.
  String? pickClosest(int targetHeight) {
    final byHeight = <int, String?>{
      360: p360,
      480: p480,
      720: p720,
      1080: p1080,
    }..removeWhere((_, v) => v == null);

    if (byHeight.isEmpty) return null;

    // Find smallest height >= target, else the largest available.
    final sortedHeights = byHeight.keys.toList()..sort();
    final ideal = sortedHeights.firstWhere(
          (h) => h >= targetHeight,
      orElse: () => sortedHeights.last,
    );
    return byHeight[ideal];
  }
}