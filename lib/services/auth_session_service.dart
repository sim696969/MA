import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final isLoggedIn = prefs.getBool(_kIsLoggedInKey) ?? false;
      final email = prefs.getString(_kUserEmailKey);

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedInKey, true);
    await prefs.setString(_kUserEmailKey, userEmail);

    state = AuthState(
      isLoggedIn: true,
      email: userEmail,
      isInitializing: false,
    );
  }

  Future<void> logout() async {
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
