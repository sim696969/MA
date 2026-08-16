import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kIsLoggedInKey = 'wedify_is_logged_in_persist';
const String _kUserEmailKey = 'wedify_user_email_persist';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final bool isInitializing;

  const AuthState({
    required this.isLoggedIn,
    this.email,
    this.isInitializing = true,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    bool? isInitializing,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState(isLoggedIn: false, isInitializing: true)) {
    _loadAuthSession();
  }

  Future<void> _loadAuthSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      // Firebase Auth is the source of truth. A legacy local preference must
      // never restore a session for an account that is no longer authenticated.
      final isLoggedIn = firebaseUser != null;
      final email = firebaseUser?.email;

      if (firebaseUser == null) {
        await prefs.remove(_kIsLoggedInKey);
        await prefs.remove(_kUserEmailKey);
      } else {
        await prefs.setBool(_kIsLoggedInKey, true);
        if (email != null) {
          await prefs.setString(_kUserEmailKey, email);
        }
      }

      state = AuthState(
        isLoggedIn: isLoggedIn,
        email: email,
        isInitializing: false,
      );
    } catch (e) {
      state = const AuthState(isLoggedIn: false, isInitializing: false);
    }
  }

  Future<void> login(String userEmail) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      state = const AuthState(isLoggedIn: false, isInitializing: false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedInKey, true);
    await prefs.setString(_kUserEmailKey, firebaseUser.email ?? userEmail);

    state = AuthState(
      isLoggedIn: true,
      email: firebaseUser.email ?? userEmail,
      isInitializing: false,
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedInKey, false);
    await prefs.remove(_kUserEmailKey);

    state = const AuthState(
      isLoggedIn: false,
      email: null,
      isInitializing: false,
    );
  }
}
