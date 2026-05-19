import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // We'll add WorkoutProvider and ExerciseProvider in the next batches.
      ],
      child: MaterialApp(
        title: 'Fitness App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Temporary router — swaps between auth and home based on AuthProvider state.
/// We'll replace this with go_router once the screens exist.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const Scaffold(
          body: Center(child: Text('Not signed in — login screen next')),
        );
      case AuthStatus.authenticated:
        return Scaffold(
          appBar: AppBar(title: const Text('Fitness App')),
          body: Center(child: Text('Hello ${auth.appUser?.displayName ?? "user"} 👋')),
        );
    }
  }
}