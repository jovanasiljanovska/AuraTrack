import 'package:flutter/material.dart';

/// Cardio activities that use GPS path tracking (Strava-style).
/// Not fetched from any API — these are the few activity types
/// where we record a route on the map instead of a timer-only workout.
enum CardioActivity {
  walking(
    id: 'walking',
    label: 'Walking',
    icon: Icons.directions_walk,
    metValue: 3.5,
  ),
  running(
    id: 'running',
    label: 'Running',
    icon: Icons.directions_run,
    metValue: 9.8,
  ),
  hiking(
    id: 'hiking',
    label: 'Hiking',
    icon: Icons.terrain,
    metValue: 6.0,
  ),
  cycling(
    id: 'cycling',
    label: 'Cycling',
    icon: Icons.directions_bike,
    metValue: 7.5,
  );

  const CardioActivity({
    required this.id,
    required this.label,
    required this.icon,
    required this.metValue,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Metabolic Equivalent of Task — used for rough calorie estimates.
  /// kcal/hour ≈ MET × bodyWeightKg
  final double metValue;

  static CardioActivity? fromId(String id) {
    for (final a in CardioActivity.values) {
      if (a.id == id) return a;
    }
    return null;
  }
}