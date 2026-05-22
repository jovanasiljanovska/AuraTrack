import 'package:flutter/foundation.dart';

import '../models/workout_session.dart';
import '../services/firestore_service.dart';

class WeeklyStats {
  final int workoutCount;
  final Duration totalDuration;
  final int totalCalories;
  final double totalDistanceMeters;

  const WeeklyStats({
    this.workoutCount = 0,
    this.totalDuration = Duration.zero,
    this.totalCalories = 0,
    this.totalDistanceMeters = 0,
  });

  static const empty = WeeklyStats();
}

class StatsProvider extends ChangeNotifier {
  StatsProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  WeeklyStats _weekly = WeeklyStats.empty;
  WeeklyStats get weekly => _weekly;

  WorkoutSession? _mostRecent;
  WorkoutSession? get mostRecent => _mostRecent;

  bool _loading = false;
  bool get loading => _loading;

  String? _activeUid;
  Stream<List<WorkoutSession>>? _stream;

  void bindTo(String? uid) {
    if (uid == _activeUid) return;
    _activeUid = uid;

    if (uid == null) {
      _weekly = WeeklyStats.empty;
      _mostRecent = null;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _stream = _firestore.watchWorkouts(uid);
    _stream!.listen(_onWorkouts, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  void _onWorkouts(List<WorkoutSession> sessions) {
    _mostRecent = sessions.isNotEmpty ? sessions.first : null;

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final thisWeek = sessions
        .where((s) => s.startTime.isAfter(startOfWeek))
        .toList();

    final totalDuration = thisWeek.fold<Duration>(
      Duration.zero,
          (sum, s) => sum + s.duration,
    );
    final totalCalories = thisWeek.fold<int>(
      0,
          (sum, s) => sum + (s.caloriesBurned ?? 0),
    );
    final totalDistance = thisWeek.fold<double>(
      0,
          (sum, s) => sum + (s.distanceMeters ?? 0),
    );

    _weekly = WeeklyStats(
      workoutCount: thisWeek.length,
      totalDuration: totalDuration,
      totalCalories: totalCalories,
      totalDistanceMeters: totalDistance,
    );

    _loading = false;
    notifyListeners();
  }
}