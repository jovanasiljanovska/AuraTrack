import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_session.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.firebaseUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: _firestore.watchWorkouts(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No workouts yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start an exercise to see your sessions here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildList(sessions, uid);
        },
      ),
    );
  }

  Widget _buildList(List<WorkoutSession> sessions, String uid) {
    // Group sessions by date for nicer presentation.
    final grouped = <String, List<WorkoutSession>>{};
    for (final s in sessions) {
      final key = DateFormat.yMMMMd().format(s.startTime);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final daySessions = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...daySessions
                .map((s) => _WorkoutTile(session: s, uid: uid, service: _firestore)),
          ],
        );
      },
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({
    required this.session,
    required this.uid,
    required this.service,
  });

  final WorkoutSession session;
  final String uid;
  final FirestoreService service;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.deleteWorkout(uid: uid, workoutId: session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCardio = session.workoutType == WorkoutType.cardio;
    final timeStr = DateFormat.Hm().format(session.startTime);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(context);
        return false; // we delete via the service, not by removing from list
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCardio
                ? Colors.blue.shade100
                : Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              isCardio ? Icons.directions_run : Icons.fitness_center,
              color: isCardio
                  ? Colors.blue
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            session.activityName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 12,
              children: [
                _MetaItem(
                  icon: Icons.access_time,
                  text: Formatters.duration(session.duration),
                ),
                if (session.distanceMeters != null)
                  _MetaItem(
                    icon: Icons.straighten,
                    text: Formatters.distance(session.distanceMeters!),
                  ),
                if (session.caloriesBurned != null)
                  _MetaItem(
                    icon: Icons.local_fire_department,
                    text: Formatters.calories(session.caloriesBurned),
                  ),
              ],
            ),
          ),
          trailing: Text(
            timeStr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}