/// Exercise fetched from the ExerciseDB RapidAPI.
/// Used for strength / flexibility / stretching workouts.
/// User starts a timer for these — no GPS tracking.
class Exercise {
  final String exerciseId;
  final String name;
  final String? imageUrl;
  final List<String> bodyParts;
  final List<String> equipments;
  final String exerciseType;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> keywords;

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
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// Convenience getters for UI
  String get primaryBodyPart =>
      bodyParts.isNotEmpty ? bodyParts.first : 'GENERAL';
  String get primaryEquipment =>
      equipments.isNotEmpty ? equipments.first : 'BODY WEIGHT';
}