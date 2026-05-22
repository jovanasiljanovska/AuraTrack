import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/formatters.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.exerciseName,
    required this.duration,
    required this.calories,
  });

  final String exerciseName;
  final Duration duration;
  final int? calories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Celebration icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Great job!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You finished $exerciseName',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // Stats card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          icon: Icons.access_time,
                          value: Formatters.duration(duration),
                          label: 'Duration',
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _StatColumn(
                          icon: Icons.local_fire_department,
                          value: calories != null ? '$calories' : '--',
                          label: 'Calories',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Actions
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.fitness_center),
                label: const Text('Back to home'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.history),
                label: const Text('View history'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}