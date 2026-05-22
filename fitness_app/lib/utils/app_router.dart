import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/exercises/exercises_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/exercises/exercise_detail_screen.dart';
import '../screens/history_screen.dart';
import '../screens/exercises/workout_summary_screen.dart';
import '../screens/exercises/workout_timer_screen.dart';
import '../screens/exercises/workout_timer_screen.dart' show WorkoutSummaryArgs;
import '../screens/cardio/cardio_picker_screen.dart';
import '../screens/cardio/cardio_tracking_screen.dart';

class AppRouter {
  AppRouter(this.authProvider);

  final AuthProvider authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/exercises',
        name: 'exercises',
        builder: (_, __) => const ExercisesListScreen(),
      ),
      GoRoute(
        path: '/exercises/:id',
        name: 'exerciseDetail',
        builder: (_, state) => ExerciseDetailScreen(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/exercises/:id/timer',
        name: 'workoutTimer',
        builder: (_, state) => WorkoutTimerScreen(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/workout-summary',
        name: 'workoutSummary',
        builder: (_, state) {
          final args = state.extra as WorkoutSummaryArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('No workout data')),
            );
          }
          return WorkoutSummaryScreen(
            exerciseName: args.exerciseName,
            duration: args.duration,
            calories: args.calories,
          );
        },
      ),
      GoRoute(
        path: '/cardio',
        name: 'cardioPicker',
        builder: (_, __) => const CardioPickerScreen(),
      ),
      GoRoute(
        path: '/cardio/track/:id',
        name: 'cardioTracking',
        builder: (_, state) => CardioTrackingScreen(
          activityId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  /// Drives auth-aware navigation: unauthenticated users get bounced to /login,
  /// authenticated users can't visit /login or /register.
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final status = authProvider.status;
    final location = state.matchedLocation;

    // Wait for the initial auth check before deciding where to send the user.
    if (status == AuthStatus.unknown) return null;

    final isOnAuthPage = location == '/login' || location == '/register';

    if (status == AuthStatus.unauthenticated && !isOnAuthPage) {
      return '/login';
    }

    if (status == AuthStatus.authenticated && isOnAuthPage) {
      return '/home';
    }

    return null;
  }
}