import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/exercise_provider.dart';

class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});

  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExerciseProvider>();
      if (provider.exercises.isEmpty) provider.loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ExerciseProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: RefreshIndicator(
        onRefresh: provider.loadInitial,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(
                resultCount: provider.exercises.length,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                onSubmitted: provider.setSearchQuery,
                onClear: () {
                  _searchCtrl.clear();
                  provider.setSearchQuery('');
                  setState(() {});
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterChipsRow(
                selectedBodyPart: provider.bodyPartFilter,
                onSelected: provider.setBodyPartFilter,
              ),
            ),
            ..._buildBody(provider),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(ExerciseProvider provider) {
    if (provider.state == ExerciseLoadState.loading &&
        provider.exercises.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.state == ExerciseLoadState.error &&
        provider.exercises.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: provider.errorMessage ?? 'Something went wrong',
            onRetry: provider.loadInitial,
          ),
        ),
      ];
    }

    if (provider.exercises.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _NoResultsState(),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index >= provider.exercises.length) {
                return _ListFooter(provider: provider);
              }
              final ex = provider.exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExerciseCard(
                  exercise: ex,
                  onTap: () =>
                      context.push('/exercises/${ex.exerciseId}'),
                ),
              );
            },
            childCount: provider.exercises.length + 1,
          ),
        ),
      ),
    ];
  }
}

// ============== Hero ==============

class _Hero extends StatelessWidget {
  const _Hero({required this.resultCount, required this.onBack});

  final int resultCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
                      'Exercises',
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
                    'LIBRARY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find your\nnext workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resultCount == 0
                          ? 'Browse the catalog'
                          : '$resultCount loaded',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== Search bar ==============

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search exercises…',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade600),
              onPressed: onClear,
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}

// ============== Filter chips ==============

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedBodyPart,
    required this.onSelected,
  });

  final String? selectedBodyPart;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'All',
            selected: selectedBodyPart == null,
            onTap: () => onSelected(null),
          ),
          ...ExerciseProvider.availableBodyParts.map(
                (bp) => _Chip(
              label: bp,
              selected: selectedBodyPart == bp,
              onTap: () => onSelected(bp),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== Exercise card ==============

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final dynamic exercise; // Exercise
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise.bestImageFor(targetHeight: 360);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _ExerciseThumbnail(imageUrl: imageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.accessibility_new,
                          label: exercise.primaryBodyPart,
                          color: const Color(0xFFFF6B35),
                        ),
                        _MetaChip(
                          icon: Icons.fitness_center,
                          label: exercise.primaryEquipment,
                          color: const Color(0xFF7B61FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: imageUrl == null
          ? _placeholder(context)
          : Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.fitness_center,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Footer / states ==============

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});
  final ExerciseProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.state == ExerciseLoadState.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!provider.hasNextPage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: Center(
          child: Text(
            "You've reached the end",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off,
                  size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

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
                Icons.search_off,
                size: 40,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No exercises found',
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search or filter.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}