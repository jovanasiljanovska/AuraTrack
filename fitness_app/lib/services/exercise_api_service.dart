import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';


class ExercisesPage {
  final List<Exercise> exercises;
  final String? nextCursor;
  final bool hasNextPage;
  final int total;

  ExercisesPage({
    required this.exercises,
    required this.nextCursor,
    required this.hasNextPage,
    required this.total,
  });
}


class ExerciseApiException implements Exception {
  final String message;
  final int? statusCode;
  ExerciseApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ExerciseApiException($statusCode): $message';
}

class ExerciseApiService {
  ExerciseApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _host => dotenv.env['RAPIDAPI_HOST'] ?? '';
  String get _key => dotenv.env['RAPIDAPI_KEY'] ?? '';
  String get _basePath => '/api/v1/exercises';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-rapidapi-host': _host,
    'x-rapidapi-key': _key,
  };


  Future<ExercisesPage> fetchExercises({
    String? bodyPart,
    String? name,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'limit': '$limit',
      if (bodyPart != null && bodyPart.isNotEmpty) 'bodyParts': bodyPart,
      if (name != null && name.isNotEmpty) 'name': name,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    final uri = Uri.https(_host, _basePath, queryParams);

    final response = await _client.get(uri, headers: _headers);
    final body = _decode(response);

    if (body['success'] != true) {
      throw ExerciseApiException(
        body['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    final meta = (body['meta'] as Map?) ?? {};
    final data = (body['data'] as List?) ?? [];

    return ExercisesPage(
      exercises: data
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nextCursor: meta['nextCursor'] as String?,
      hasNextPage: meta['hasNextPage'] == true,
      total: (meta['total'] as int?) ?? data.length,
    );
  }


  Future<Exercise> fetchExerciseById(String exerciseId) async {
    final uri = Uri.https(_host, '$_basePath/$exerciseId');
    final response = await _client.get(uri, headers: _headers);
    final body = _decode(response);

    if (body['success'] != true) {
      throw ExerciseApiException(
        body['message']?.toString() ?? 'Exercise not found',
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    if (data == null) {
      throw ExerciseApiException('Empty response', statusCode: response.statusCode);
    }

    return Exercise.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExerciseApiException(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (e) {
      throw ExerciseApiException('Invalid JSON: $e',
          statusCode: response.statusCode);
    }
  }

  void dispose() => _client.close();
}