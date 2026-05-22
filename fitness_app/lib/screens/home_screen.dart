import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.appUser?.displayName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Welcome, $name 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center, size: 32),
                title: const Text('Exercises'),
                subtitle: const Text('Browse and start a workout'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/exercises'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_run, size: 32),
                title: const Text('Cardio'),
                subtitle: const Text('Track running, walking, hiking, cycling'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cardio'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, size: 32),
                title: const Text('History'),
                subtitle: const Text('Review your past workouts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/history'),
              ),
            ),

          ],
        ),
      ),
      );
  }
}