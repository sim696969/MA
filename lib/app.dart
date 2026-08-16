import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/auth_session_service.dart';
import 'widgets/top_right_toast.dart';

class WedifyApp extends ConsumerWidget {
  const WedifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return TopRightToastWrapper(
      child: MaterialApp(
        title: 'Wedify',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routes: {
          '/login': (_) => const AuthScreen(),
          '/register': (_) => const AuthScreen(isRegistering: true),
        },
        home: authState.isInitializing
            ? const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.slate900),
                ),
              )
            : (authState.isLoggedIn
                ? const HomeScreen()
                : const OnboardingScreen()),
      ),
    );
  }
}
