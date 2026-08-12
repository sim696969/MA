import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/auth_session_service.dart';

class WedifyApp extends ConsumerWidget {
  const WedifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Wedify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.isInitializing
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E8E)),
              ),
            )
          : (authState.isLoggedIn ? const HomeScreen() : const OnboardingScreen()),
    );
  }
}
