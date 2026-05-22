import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/exercise_provider.dart';
import '../../widgets/exercise_card.dart';

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
    // Kick off the first load after the frame so we can use context.read.
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
      appBar: AppBar(
        title: const Text('Exercises'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search exercises',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.setSearchQuery('');
                        setState(() {});
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: provider.setSearchQuery,
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _filterChip(context, label: 'All', value: null),
                    ...ExerciseProvider.availableBodyParts.map(
                          (bp) => _filterChip(context, label: bp, value: bp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label, required String? value}) {
    final provider = context.read<ExerciseProvider>();
    final selected = provider.bodyPartFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => provider.setBodyPartFilter(value),
      ),
    );
  }

  Widget _buildBody(ExerciseProvider provider) {
    if (provider.state == ExerciseLoadState.loading &&
        provider.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == ExerciseLoadState.error &&
        provider.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: provider.loadInitial,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.exercises.isEmpty) {
      return const Center(child: Text('No exercises found'));
    }

    return RefreshIndicator(
      onRefresh: provider.loadInitial,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.exercises.length) {
            return _buildFooter(provider);
          }
          final ex = provider.exercises[index];
          return ExerciseCard(
            exercise: ex,
            onTap: () => context.push('/exercises/${ex.exerciseId}'),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ExerciseProvider provider) {
    if (provider.state == ExerciseLoadState.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!provider.hasNextPage) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('You\'ve reached the end',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}