import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/exercises/exercises_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

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