import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_point.dart';

enum WorkoutType { exercise, cardio }

class WorkoutSession {
  final String id;
  final String userId;

  /// What kind of workout this was — drives which detail fields are populated.
  final WorkoutType workoutType;

  /// For `exercise` → the Exercise.exerciseId from the API.
  /// For `cardio`   → the CardioActivity.id (e.g. "running").
  final String activityId;

  /// Human-readable name, denormalized so we don't have to re-fetch
  /// the exercise from the API to show history.
  final String activityName;

  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  /// Only populated for cardio workouts.
  final List<RoutePoint> routePoints;
  final double? distanceMeters;

  final int? caloriesBurned;
  final String? notes;
  final String? photoBase64;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutType,
    required this.activityId,
    required this.activityName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.routePoints = const [],
    this.distanceMeters,
    this.caloriesBurned,
    this.notes,
    this.photoBase64,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'workoutType': workoutType.name, // 'exercise' or 'cardio'
    'activityId': activityId,
    'activityName': activityName,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'durationSeconds': duration.inSeconds,
    'routePoints': routePoints.map((p) => p.toMap()).toList(),
    'distanceMeters': distanceMeters,
    'caloriesBurned': caloriesBurned,
    'notes': notes,
    'photoBase64': photoBase64,
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutSession(
      id: id,
      userId: map['userId'] ?? '',
      workoutType: WorkoutType.values.firstWhere(
            (t) => t.name == map['workoutType'],
        orElse: () => WorkoutType.exercise,
      ),
      activityId: map['activityId'] ?? '',
      activityName: map['activityName'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      duration: Duration(seconds: (map['durationSeconds'] ?? 0) as int),
      routePoints: ((map['routePoints'] as List?) ?? [])
          .map((e) => RoutePoint.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
      caloriesBurned: map['caloriesBurned'] as int?,
      notes: map['notes'] as String?,
      photoBase64: map['photoBase64'] as String?,
    );
  }

  bool get hasRoute => routePoints.isNotEmpty;
}