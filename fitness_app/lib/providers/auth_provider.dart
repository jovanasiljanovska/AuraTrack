import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    _init();
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _init() {
    _authService.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user == null) {
      _appUser = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _appUser = await _firestoreService.getUser(user.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    }
  }

  /// Refresh the AppUser profile after edits.
  Future<void> refreshProfile() async {
    if (_firebaseUser == null) return;
    _appUser = await _firestoreService.getUser(_firebaseUser!.uid);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}