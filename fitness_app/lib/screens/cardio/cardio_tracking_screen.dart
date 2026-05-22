import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cardio_activity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../screens/exercises/workout_timer_screen.dart' show WorkoutSummaryArgs;
import '../../utils/formatters.dart';
import '../../widgets/route_map.dart';

class CardioTrackingScreen extends StatefulWidget {
  const CardioTrackingScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<CardioTrackingScreen> createState() => _CardioTrackingScreenState();
}

class _CardioTrackingScreenState extends State<CardioTrackingScreen> {
  bool _initialized = false;
  bool _starting = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_initialized) return;
    final activity = CardioActivity.fromId(widget.activityId);
    if (activity == null) {
      context.pop();
      return;
    }

    final workout = context.read<WorkoutProvider>();
    if (workout.state != WorkoutState.idle) {
      _initialized = true;
      return;
    }

    setState(() => _starting = true);
    try {
      await workout.startCardioWorkout(activity);
      _initialized = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _finish() async {
    final workout = context.read<WorkoutProvider>();
    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;

    final confirmed = await _confirmDialog(
      title: 'Finish workout?',
      message: 'Your route and stats will be saved.',
      confirmLabel: 'Finish',
    );
    if (!confirmed) return;

    final activityName = workout.cardio?.label ?? 'Cardio';
    final duration = workout.elapsed;
    final distance = workout.distanceMeters;
    final weightKg = auth.appUser?.weightKg?.round() ?? 70;
    final met = workout.cardio?.metValue ?? 5.0;
    final calories = (met * weightKg * (duration.inSeconds / 3600)).round();

    final id = await workout.finish(
      userId: uid,
      userWeightKg: weightKg,
    );
    if (!mounted) return;

    if (id != null) {
      final displayName = distance > 0
          ? '$activityName (${Formatters.distance(distance)})'
          : activityName;


      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      context.go(
        '/workout-summary',
        extra: WorkoutSummaryArgs(
          exerciseName: displayName,
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

  Future<void> _cancel() async {
    final confirmed = await _confirmDialog(
      title: 'Discard workout?',
      message: 'Your route will not be saved.',
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

    // Permission error state
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tracking'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64),
                const SizedBox(height: 16),
                Text(_initError!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() => _initError = null);
                    _start();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_starting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activity = workout.cardio;

    return PopScope(
      canPop: workout.state == WorkoutState.idle ||
          workout.state == WorkoutState.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(activity?.label ?? 'Tracking'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: RouteMap(
                routePoints: workout.routePoints,
                followUser: workout.state == WorkoutState.running,
              ),
            ),
            _StatsPanel(workout: workout),
            _ControlBar(
              state: workout.state,
              onPause: workout.pause,
              onResume: workout.resume,
              onFinish: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.workout});

  final WorkoutProvider workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'TIME',
              value: Formatters.duration(workout.elapsed),
            ),
          ),
          Expanded(
            child: _Stat(
              label: 'DISTANCE',
              value: Formatters.distance(workout.distanceMeters),
            ),
          ),
          Expanded(
            child: _Stat(
              label: 'PACE',
              value: Formatters.pace(workout.paceMinPerKm),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isPaused ? onResume : onPause,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Resume' : 'Pause'),
                style: FilledButton.styleFrom(
                  backgroundColor: isPaused ? Colors.green : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onFinish,
                icon: const Icon(Icons.stop),
                label: const Text('Finish'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}