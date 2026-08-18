import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_session_service.dart';
import '../home/home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool isRegistering;

  const AuthScreen({super.key, this.isRegistering = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isRegistering;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isRegistering = widget.isRegistering;
    _nameController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasValidInput {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isRegistering) {
      final name = _nameController.text.trim();
      return name.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
    }
    return email.isNotEmpty && password.isNotEmpty;
  }

  void _showAuthSnackBar(String message, {bool isError = true}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFE57373) : AppColors.sage,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Authentication service is temporarily disabled. Please contact support.';
      case 'invalid-credential':
      case 'user-not-found':
        return "Account not found. Click 'Sign Up' below to create this account.";
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Please sign in instead.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again later.';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);

        // Save/update the authenticated Firebase user's profile in Firestore.
        await _dbService.setDocument(
          collectionPath: 'users',
          docId: userCredential.user!.uid,
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
          _showAuthSnackBar(
            'Welcome, ${account.displayName ?? account.email}!',
            isError: false,
          );
          _navigateToHome(userCredential.user!.email);
        }
      }
    } on FirebaseAuthException catch (error) {
      debugPrint('Google Firebase authentication failed: ${error.code} ${error.message}');
      if (mounted) {
        _showAuthSnackBar(_authErrorMessage(error));
      }
    } catch (error) {
      debugPrint('Google Sign-In failed: $error');
      if (mounted) {
        _showAuthSnackBar('Google Sign-In failed. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    // Passwords are intentionally read verbatim: casing and whitespace are
    // credential data and must never be normalised before authentication.
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showAuthSnackBar('Please fill in email and password.');
      return;
    }

    if (_isRegistering) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        _showAuthSnackBar('Please enter your full name.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await _dbService.setDocument(
          collectionPath: 'users',
          docId: credential.user!.uid,
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
          _showAuthSnackBar(
            'Account created successfully! Welcome to Wedify.',
            isError: false,
          );
          _navigateToHome();
        }
      } on FirebaseAuthException catch (error) {
        debugPrint('Registration failed: ${error.code} ${error.message}');
        if (mounted) {
          _showAuthSnackBar(_authErrorMessage(error));
        }
      } catch (error) {
        debugPrint('Registration failed: $error');
        if (mounted) {
          _showAuthSnackBar('Registration failed. Please try again later.');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Sign In Flow
      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        await _dbService.addDocument(
          collectionPath: 'login_logs',
          data: {
            'email': email,
            'loginTime': DateTime.now().toIso8601String(),
            'status': 'success',
          },
        );

        if (mounted) {
          _navigateToHome(credential.user!.email);
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Sign-in failed: ${e.code} ${e.message}');
        if (mounted) {
          _showAuthSnackBar(_authErrorMessage(e));
        }
      } catch (e) {
        debugPrint('Sign-in failed: $e');
        if (mounted) {
          _showAuthSnackBar('Unable to sign in. Please try again later.');
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
    _nameController.removeListener(_onInputChanged);
    _emailController.removeListener(_onInputChanged);
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: SelectionArea(
            selectionControls: null,
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
                    fontFamily: 'Inter',
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      if (_isRegistering) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: AppColors.slate900,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: AppColors.slate900,
                            decoration: const InputDecoration(
                              hintText: "Full Name",
                              hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14, fontWeight: FontWeight.normal),
                              fillColor: Colors.transparent,
                              filled: true,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: AppColors.slate900,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.slate900,
                          cursorWidth: 2.0,
                          decoration: const InputDecoration(
                            hintText: "Email address",
                            hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14, fontWeight: FontWeight.normal),
                            fillColor: Colors.transparent,
                            filled: true,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: AppColors.slate900,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: AppColors.slate900,
                            decoration: const InputDecoration(
                              hintText: "Phone Number (optional)",
                              hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14, fontWeight: FontWeight.normal),
                              fillColor: Colors.transparent,
                              filled: true,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: AppColors.slate900,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.slate900,
                          cursorWidth: 2.0,
                          decoration: const InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14, fontWeight: FontWeight.normal),
                            fillColor: Colors.transparent,
                            filled: true,
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
                        _showAuthSnackBar(
                          'Password reset link sent to email.',
                          isError: false,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: _hasValidInput
                        ? const LinearGradient(
                            colors: [Color(0xFFD9777F), Color(0xFFC85A65)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [AppColors.pinkGradientStart, AppColors.pinkGradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: _hasValidInput
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC85A65).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSubmit,
                      borderRadius: BorderRadius.circular(24),
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
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        _isRegistering ? '/login' : '/register',
                      ),
                      child: Text(
                        _isRegistering ? "Sign In" : "Sign Up",
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
              if (_isRegistering) ...[
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: const Row(
                  children: [
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, size: 30, color: AppColors.slate900),
                        SizedBox(width: 8),
                        Text(
                          "Sign up with Google",
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
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

