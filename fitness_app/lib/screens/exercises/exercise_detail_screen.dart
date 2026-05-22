import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../widgets/exercise_video_player.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Exercise? _exercise;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with cached summary if we have it, then fetch full detail.
    final provider = context.read<ExerciseProvider>();
    _exercise = provider.cached(widget.exerciseId);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });
    try {
      final full = await context
          .read<ExerciseProvider>()
          .fetchDetail(widget.exerciseId);
      if (!mounted) return;
      setState(() => _exercise = full);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not load exercise details');
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  void _startWorkout() {
    final ex = _exercise;
    if (ex == null) return;
    context.push('/exercises/${ex.exerciseId}/timer');
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exercise;


    if (ex == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _isLoadingDetail
            ? const Center(child: CircularProgressIndicator())
            : _ErrorView(
          message: _errorMessage ?? 'Exercise not found',
          onRetry: _loadDetail,
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                ex.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: _HeaderImage(exercise: ex),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final bp in ex.bodyParts)
                        Chip(
                          label: Text(bp),
                          avatar: const Icon(Icons.accessibility_new, size: 16),
                        ),
                      for (final eq in ex.equipments)
                        Chip(
                          label: Text(eq),
                          avatar: const Icon(Icons.fitness_center, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Loading indicator if still fetching detail
                  if (_isLoadingDetail && !ex.hasDetail)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // Video
                  if (ex.videoUrl != null) ...[
                    const _SectionTitle(icon: Icons.play_circle, label: 'Demo'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ExerciseVideoPlayer(videoUrl: ex.videoUrl!),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Overview
                  if (ex.overview != null && ex.overview!.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.info_outline, label: 'Overview'),
                    Text(ex.overview!,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                  ],

                  // Target muscles
                  if (ex.targetMuscles.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.center_focus_strong, label: 'Target muscles'),
                    _MuscleList(muscles: ex.targetMuscles, isPrimary: true),
                    const SizedBox(height: 12),
                  ],

                  // Secondary muscles
                  if (ex.secondaryMuscles.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.group, label: 'Secondary muscles'),
                    _MuscleList(muscles: ex.secondaryMuscles, isPrimary: false),
                    const SizedBox(height: 20),
                  ],

                  // Instructions
                  if (ex.instructions.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.list_alt, label: 'How to do it'),
                    _NumberedList(items: ex.instructions),
                    const SizedBox(height: 20),
                  ],

                  // Tips
                  if (ex.exerciseTips.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.lightbulb_outline, label: 'Tips'),
                    _BulletList(items: ex.exerciseTips),
                    const SizedBox(height: 20),
                  ],

                  // Variations
                  if (ex.variations.isNotEmpty) ...[
                    const _SectionTitle(
                        icon: Icons.shuffle, label: 'Variations'),
                    _BulletList(items: ex.variations),
                    const SizedBox(height: 20),
                  ],

                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  const SizedBox(height: 80), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingDetail ? null : _startWorkout,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start workout'),
      ),
    );
  }
}



class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final url = exercise.bestImageFor(targetHeight: 720);
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.fitness_center, size: 64)),
    );

    if (url == null) return placeholder;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder),
        // Gradient so title text stays legible.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleList extends StatelessWidget {
  const _MuscleList({required this.muscles, required this.isPrimary});
  final List<String> muscles;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: muscles
          .map(
            (m) => Chip(
          label: Text(m, style: const TextStyle(fontSize: 12)),
          backgroundColor:
          isPrimary ? scheme.primaryContainer : scheme.surfaceContainer,
          side: BorderSide.none,
        ),
      )
          .toList(),
    );
  }
}

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(items[i],
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(item,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}