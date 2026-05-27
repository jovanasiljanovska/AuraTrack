import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../services/exercise_api_service.dart';

enum ExerciseLoadState { initial, loading, loaded, loadingMore, error }

class ExerciseProvider extends ChangeNotifier {
  ExerciseProvider({ExerciseApiService? apiService})
      : _api = apiService ?? ExerciseApiService();

  final ExerciseApiService _api;

  // ----- State -----
  final List<Exercise> _exercises = [];
  List<Exercise> get exercises => List.unmodifiable(_exercises);

  /// Cache by exerciseId so the detail screen can show summary data
  /// instantly while the detail endpoint loads in the background.
  final Map<String, Exercise> _cache = {};
  Exercise? cached(String id) => _cache[id];

  String? _nextCursor;
  bool _hasNextPage = true;
  bool get hasNextPage => _hasNextPage;

  ExerciseLoadState _state = ExerciseLoadState.initial;
  ExerciseLoadState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ----- Filters -----
  String? _bodyPartFilter;
  String? get bodyPartFilter => _bodyPartFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Body parts shown as filter chips. Pulled from the API's known values.
  static const List<String> availableBodyParts = [
    'BACK',
    'CHEST',
    'SHOULDERS',
    'UPPER ARMS',
    'LOWER ARMS',
    'WAIST',
    'UPPER LEGS',
    'LOWER LEGS',
    'NECK',
    'HIPS',
   // 'CARDIO',
  ];

  // ----- Public API -----

  /// Initial load. Call from the screen's initState.
  Future<void> loadInitial() async {
    if (_state == ExerciseLoadState.loading) return;
    _exercises.clear();
    _nextCursor = null;
    _hasNextPage = true;
    _state = ExerciseLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    await _fetchPage();
  }

  /// Called when the user reaches the bottom of the list.
  Future<void> loadMore() async {
    if (!_hasNextPage ||
        _state == ExerciseLoadState.loading ||
        _state == ExerciseLoadState.loadingMore) {
      return;
    }
    _state = ExerciseLoadState.loadingMore;
    notifyListeners();
    await _fetchPage();
  }

  void setBodyPartFilter(String? bodyPart) {
    if (_bodyPartFilter == bodyPart) return;
    _bodyPartFilter = bodyPart;
    loadInitial();
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    loadInitial();
  }

  void clearFilters() {
    _bodyPartFilter = null;
    _searchQuery = '';
    loadInitial();
  }

  /// Fetch full details for a single exercise. Merges the result into the
  /// cache and returns the enriched Exercise. The detail screen calls this.
  Future<Exercise> fetchDetail(String exerciseId) async {
    final summary = _cache[exerciseId];
    try {
      final detail = await _api.fetchExerciseById(exerciseId);
      final merged = summary?.mergeWith(detail) ?? detail;
      _cache[exerciseId] = merged;
      return merged;
    } catch (e) {
      // If detail fails but we have a summary, return what we have
      if (summary != null) return summary;
      rethrow;
    }
  }

  // ----- Internal -----

  Future<void> _fetchPage() async {
    try {
      final page = await _api.fetchExercises(
        bodyPart: _bodyPartFilter,
        name: _searchQuery.isEmpty ? null : _searchQuery,
        cursor: _nextCursor,
        limit: 20,
      );

      //_exercises.addAll(page.exercises);
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final filtered = page.exercises
            .where((ex) => ex.name.toLowerCase().contains(query))
            .toList();
        _exercises.addAll(filtered);
      } else {
        _exercises.addAll(page.exercises);
      }
      for (final ex in page.exercises) {
        _cache[ex.exerciseId] = ex;
      }

      _nextCursor = page.nextCursor;
      _hasNextPage = page.hasNextPage;
      _state = ExerciseLoadState.loaded;
      _errorMessage = null;
    } on ExerciseApiException catch (e) {
      _state = ExerciseLoadState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = ExerciseLoadState.error;
      _errorMessage = 'Unable to load exercises.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}