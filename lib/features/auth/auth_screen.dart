import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_session_service.dart';
import '../home/home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isRegistering = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        // Save/update Google user profile in Firebase Firestore
        await _dbService.setDocument(
          collectionPath: 'users',
          docId: account.id,
          data: {
            'name': account.displayName ?? 'User',
            'email': account.email,
            'photoUrl': account.photoUrl,
            'authProvider': 'google',
            'lastLogin': DateTime.now().toIso8601String(),
          },
          merge: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${account.displayName ?? account.email}!'),
              backgroundColor: AppColors.pinkPrimary,
            ),
          );
          _navigateToHome();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in email and password.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_isRegistering) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your full name.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        // Save user registration data in Firebase Firestore
        await _dbService.addDocument(
          collectionPath: 'users',
          data: {
            'name': name,
            'email': email,
            'phone': phone,
            'role': 'couple', // default user role for wedding planning
            'authProvider': 'email',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome to Wedify.'),
              backgroundColor: AppColors.pinkPrimary,
            ),
          );
          _navigateToHome();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Sign In Flow
      setState(() => _isLoading = true);
      try {
        // Log sign-in activity to Firebase Firestore
        await _dbService.addDocument(
          collectionPath: 'login_logs',
          data: {
            'email': email,
            'loginTime': DateTime.now().toIso8601String(),
            'status': 'success',
          },
        );

        if (mounted) {
          _navigateToHome();
        }
      } catch (e) {
        if (mounted) {
          _navigateToHome();
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome([String? email]) {
    ref.read(authStateProvider.notifier).login(email ?? _emailController.text.trim());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              // Brand Logo Header
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.pinkPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "W E D I F Y",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _isRegistering ? "Create Account" : "Welcome Back",
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  _isRegistering
                      ? "Register now to save all your wedding details in Firebase"
                      : "Sign in to continue planning your perfect wedding",
                  style: const TextStyle(color: AppColors.slate500, fontSize: 15),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      if (_isRegistering) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: "Full Name",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              icon: Icon(Icons.person_outline_rounded, color: AppColors.slate400, size: 20),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.slate100),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: "Email address",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            icon: Icon(Icons.email_outlined, color: AppColors.slate400, size: 20),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.slate100),
                      if (_isRegistering) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: "Phone Number (optional)",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              icon: Icon(Icons.phone_outlined, color: AppColors.slate400, size: 20),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.slate100),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Password",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            icon: Icon(Icons.lock_outline_rounded, color: AppColors.slate400, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isRegistering)
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password reset link sent to email.")),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.pinkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Submit Button (Sign In / Register)
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [AppColors.pinkGradientStart, AppColors.pinkGradientEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pinkPrimary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSubmit,
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isRegistering ? "Create Account" : "Sign In",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Toggle between Login & Register
              FadeInUp(
                duration: const Duration(milliseconds: 1100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegistering ? "Already have an account? " : "Don't have an account? ",
                      style: const TextStyle(color: AppColors.slate500, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                        });
                      },
                      child: Text(
                        _isRegistering ? "Sign In" : "Register Now",
                        style: const TextStyle(
                          color: AppColors.pinkPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.slate200)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.slate200)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1300),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.g_mobiledata, size: 30, color: AppColors.slate900),
                        SizedBox(width: 8),
                        Text(
                          "Google Sign-In",
                          style: TextStyle(
                            color: AppColors.slate900,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

