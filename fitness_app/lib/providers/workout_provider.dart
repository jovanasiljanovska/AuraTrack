import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cardio_activity.dart';
import '../models/exercise.dart';
import '../models/route_point.dart';
import '../models/workout_session.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

enum WorkoutState { idle, running, paused, finished }

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider({
    FirestoreService? firestoreService,
    LocationService? locationService,
  })  : _firestore = firestoreService ?? FirestoreService(),
        _location = locationService ?? LocationService();

  final FirestoreService _firestore;
  final LocationService _location;


  WorkoutState _state = WorkoutState.idle;
  WorkoutState get state => _state;

  WorkoutType? _workoutType;
  WorkoutType? get workoutType => _workoutType;


  Exercise? _exercise;
  Exercise? get exercise => _exercise;

  CardioActivity? _cardio;
  CardioActivity? get cardio => _cardio;

  DateTime? _startTime;
  DateTime? get startTime => _startTime;


  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;
  Timer? _ticker;
  DateTime? _lastTickTime;


  final List<RoutePoint> _routePoints = [];
  List<RoutePoint> get routePoints => List.unmodifiable(_routePoints);
  StreamSubscription<RoutePoint>? _locationSub;

  double get distanceMeters =>
      LocationService.calculateDistanceMeters(_routePoints);


  double? get paceMinPerKm {
    final km = distanceMeters / 1000;
    if (km < 0.01) return null;
    return _elapsed.inSeconds / 60 / km;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;




  void startExerciseWorkout(Exercise exercise) {
    _reset();
    _workoutType = WorkoutType.exercise;
    _exercise = exercise;
    _startTime = DateTime.now();
    _state = WorkoutState.running;
    _startTicker();
    notifyListeners();
  }


  Future<void> startCardioWorkout(CardioActivity activity) async {
    _reset();
    _workoutType = WorkoutType.cardio;
    _cardio = activity;

    try {
      await _location.ensurePermission();
    } on LocationPermissionDeniedException catch (e) {
      _errorMessage = e.message;
      _state = WorkoutState.idle;
      notifyListeners();
      rethrow;
    }

    _startTime = DateTime.now();
    _state = WorkoutState.running;
    _startTicker();
    _startLocationStream();
    notifyListeners();
  }

  void pause() {
    if (_state != WorkoutState.running) return;
    _state = WorkoutState.paused;
    _ticker?.cancel();
    _locationSub?.pause();
    notifyListeners();
  }

  void resume() {
    if (_state != WorkoutState.paused) return;
    _state = WorkoutState.running;
    _lastTickTime = DateTime.now();
    _startTicker();
    _locationSub?.resume();
    notifyListeners();
  }


  Future<String?> finish({
    required String userId,
    int? userWeightKg,
    String? notes,
  }) async {
    if (_state == WorkoutState.idle) return null;


    _ticker?.cancel();
    _ticker = null;


    try {
      await _locationSub?.cancel();
    } catch (_) {

    }
    _locationSub = null;

    _state = WorkoutState.finished;

    final endTime = DateTime.now();
    final session = WorkoutSession(
      id: '',
      userId: userId,
      workoutType: _workoutType!,
      activityId: _workoutType == WorkoutType.exercise
          ? _exercise!.exerciseId
          : _cardio!.id,
      activityName: _workoutType == WorkoutType.exercise
          ? _exercise!.name
          : _cardio!.label,
      startTime: _startTime!,
      endTime: endTime,
      duration: _elapsed,
      routePoints: List.of(_routePoints),
      distanceMeters:
      _workoutType == WorkoutType.cardio ? distanceMeters : null,
      caloriesBurned: _estimateCalories(userWeightKg ?? 70),
      notes: notes,
    );

    try {
      final id = await _firestore.saveWorkout(session);
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = 'Could not save workout.';
      notifyListeners();
      return null;
    }
  }


  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    try {
      _locationSub?.cancel();
    } catch (_) {

    }
    _locationSub = null;
    _reset();
    notifyListeners();
  }



  void _reset() {
    _state = WorkoutState.idle;
    _workoutType = null;
    _exercise = null;
    _cardio = null;
    _startTime = null;
    _elapsed = Duration.zero;
    _routePoints.clear();
    _errorMessage = null;
    _lastTickTime = null;
    _ticker?.cancel();
    _ticker = null;
    _locationSub?.cancel();
    _locationSub = null;
  }

  void _startTicker() {
    _lastTickTime = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastTickTime!);
      _lastTickTime = now;
      _elapsed += delta;
      notifyListeners();
    });
  }

  void _startLocationStream() {
    _locationSub = _location.trackPosition().listen(
          (point) {
        _routePoints.add(point);
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Location error: $e';
        notifyListeners();
      },
    );
  }


  int? _estimateCalories(int weightKg) {
    final hours = _elapsed.inSeconds / 3600;
    if (hours <= 0) return null;

    double met;
    if (_workoutType == WorkoutType.cardio) {
      met = _cardio!.metValue;
    } else {

      met = 5.0;
    }
    return (met * weightKg * hours).round();
  }


  @override
  void dispose() {
    _ticker?.cancel();
    try {
      _locationSub?.cancel();
    } catch (_) {
      // Ignore.
    }
    super.dispose();
  }
}