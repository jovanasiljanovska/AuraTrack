import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_session.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/route_preview.dart';

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
      backgroundColor: const Color(0xFFF5F6F8),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: _firestore.watchWorkouts(uid),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HistoryHero(
                  sessions: snapshot.data ?? const [],
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                )
              else
                ..._buildBodySlivers(snapshot.data ?? const [], uid),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBodySlivers(List<WorkoutSession> sessions, String uid) {
    if (sessions.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(),
        ),
      ];
    }

    final grouped = <String, List<WorkoutSession>>{};
    for (final s in sessions) {
      final key = DateFormat.yMMMMd().format(s.startTime);
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final dateKeys = grouped.keys.toList();

    final slivers = <Widget>[];
    for (int i = 0; i < dateKeys.length; i++) {
      final dateKey = dateKeys[i];
      final daySessions = grouped[dateKey]!;

      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 16 : 24, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionLabel(label: dateKey.toUpperCase()),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, idx) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WorkoutCard(
                  session: daySessions[idx],
                  uid: uid,
                  service: _firestore,
                ),
              ),
              childCount: daySessions.length,
            ),
          ),
        ),
      );
    }

    // Bottom padding
    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 32)));

    return slivers;
  }
}

// ============== Hero with summary stats ==============

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.sessions, required this.onBack});

  final List<WorkoutSession> sessions;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final totalWorkouts = sessions.length;
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
          (sum, s) => sum + s.duration,
    );
    final totalCalories = sessions.fold<int>(
      0,
          (sum, s) => sum + (s.caloriesBurned ?? 0),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALL TIME',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalWorkouts ${totalWorkouts == 1 ? "workout" : "workouts"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroStat(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: _shortDuration(totalDuration),
                      ),
                      const SizedBox(width: 24),
                      _HeroStat(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '$totalCalories kcal',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDuration(Duration d) {
    if (d.inHours > 0) {
      final mins = d.inMinutes.remainder(60);
      return '${d.inHours}h ${mins}m';
    }
    return '${d.inMinutes}m';
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============== Section label ==============

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ============== Workout card ==============

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
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
    final hasRoute = session.routePoints.length >= 2;
    final timeStr = DateFormat.Hm().format(session.startTime);
    final accent = isCardio
        ? const Color(0xFF4A90E2)
        : const Color(0xFFFF6B35);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(context);
        return false;
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () {}, // could go to a detail screen later
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRoute)
                RoutePreview(points: session.routePoints, height: 110),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCardio
                                ? Icons.directions_run
                                : Icons.fitness_center,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.activityName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                      accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCardio ? 'CARDIO' : 'STRENGTH',
                                      style: TextStyle(
                                        fontSize: 9,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _Stat(
                          icon: Icons.access_time,
                          text: Formatters.duration(session.duration),
                        ),
                        if (session.distanceMeters != null &&
                            session.distanceMeters! > 0)
                          _Stat(
                            icon: Icons.straighten,
                            text: Formatters.distance(
                                session.distanceMeters!),
                          ),
                        if (session.caloriesBurned != null)
                          _Stat(
                            icon: Icons.local_fire_department,
                            text: '${session.caloriesBurned} kcal',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

// ============== Empty state ==============

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 48,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No workouts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed sessions will appear here.\nStart your first workout to begin tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}