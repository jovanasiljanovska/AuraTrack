import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/exercise_video_player.dart';


class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfNeeded());
  }

  void _startIfNeeded() {
    if (_initialized) return;
    final workout = context.read<WorkoutProvider>();
    if (workout.state != WorkoutState.idle) {
      _initialized = true;
      return;
    }
    final exercise =
    context.read<ExerciseProvider>().cached(widget.exerciseId);
    if (exercise == null) {
      context.pop();
      return;
    }
    workout.startExerciseWorkout(exercise);
    _initialized = true;
  }

  Future<void> _finish() async {
    final workout = context.read<WorkoutProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.firebaseUser?.uid;
    if (userId == null) return;

    final confirmed = await _confirmDialog(
      title: 'Finish workout?',
      message: 'Your session will be saved to your history.',
      confirmLabel: 'Finish',
    );
    if (!confirmed) return;

    // Capture values BEFORE finishing — finish() resets the provider state
    // depending on your flow, so snapshot what we need for the summary screen.
    final exerciseName = workout.exercise?.name ?? 'Workout';
    final duration = workout.elapsed;

    final id = await workout.finish(
      userId: userId,
      userWeightKg: auth.appUser?.weightKg?.round(),
    );
    if (!mounted) return;

    if (id != null) {
      // Read calories after finish so the MET estimate is final.
      // Note: we re-read from provider in case it was just calculated.
      final calories = _estimateClientSideCalories(
        durationSeconds: duration.inSeconds,
        weightKg: auth.appUser?.weightKg?.round() ?? 70,
      );

      // Navigate to summary, replacing the timer in the stack so back
      // doesn't return to a finished timer screen.
      context.go(
        '/workout-summary',
        extra: WorkoutSummaryArgs(
          exerciseName: exerciseName,
          duration: duration,
          calories: calories,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.errorMessage ?? 'Could not save')),
      );
    }
  }

  /// Mirror of the provider's strength-MET estimate so we don't have to
  /// expose internal fields. MET 5.0 × weight × hours.
  int _estimateClientSideCalories({
    required int durationSeconds,
    required int weightKg,
  }) {
    final hours = durationSeconds / 3600;
    return (5.0 * weightKg * hours).round();
  }

  Future<void> _cancel() async {
    final confirmed = await _confirmDialog(
      title: 'Discard workout?',
      message: 'This session will not be saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!confirmed) return;
    context.read<WorkoutProvider>().cancel();
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final exercise = workout.exercise;
    final videoUrl = exercise?.videoUrl;

    return PopScope(
      canPop: workout.state == WorkoutState.idle ||
          workout.state == WorkoutState.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(exercise?.name ?? 'Workout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Video at the top — autoplay muted, loops
              if (videoUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  child: ExerciseVideoPlayer(
                    videoUrl: videoUrl,
                    autoPlay: true,
                    muted: true,
                  ),
                ),

              // Timer section fills remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      _StatusBadge(state: workout.state),
                      const SizedBox(height: 20),
                      Text(
                        Formatters.duration(workout.elapsed),
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'elapsed time',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(flex: 2),
                      _Controls(
                        state: workout.state,
                        onPause: workout.pause,
                        onResume: workout.resume,
                        onFinish: _finish,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Args passed to the summary screen via go_router's `extra`.
class WorkoutSummaryArgs {
  WorkoutSummaryArgs({
    required this.exerciseName,
    required this.duration,
    required this.calories,
  });

  final String exerciseName;
  final Duration duration;
  final int? calories;
}

// ---------- Reused sub-widgets ----------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});
  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (state) {
      case WorkoutState.running:
        label = 'IN PROGRESS';
        color = Colors.green;
        break;
      case WorkoutState.paused:
        label = 'PAUSED';
        color = Colors.orange;
        break;
      case WorkoutState.finished:
        label = 'FINISHED';
        color = Colors.blue;
        break;
      case WorkoutState.idle:
        label = 'IDLE';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final WorkoutState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final isPaused = state == WorkoutState.paused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: isPaused ? Colors.green : Colors.orange,
          onPressed: isPaused ? onResume : onPause,
        ),
        _CircleButton(
          icon: Icons.stop,
          label: 'Finish',
          color: Colors.red,
          onPressed: onFinish,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}