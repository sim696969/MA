import 'package:flutter/material.dart';
import '../../widgets/wedify_button.dart';
import '../home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "WEDIFY",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Plan your perfect day with ease.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).colorScheme.onBackground,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Login"),
                  Tab(text: "Sign Up"),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(),
                    _buildSignUpForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(hintText: "Email"),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "Password"),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: WedifyButton(
              text: "Log In",
              onPressed: () => _navigateToHome(),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: WedifyButton(
              text: "Continue with Google",
              style: WedifyButtonStyle.outline,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              onPressed: () {
                // TODO: Insert your Google Auth API key here
                // GOOGLE_CLIENT_ID_ANDROID, GOOGLE_CLIENT_ID_IOS, GOOGLE_CLIENT_ID_WEB
                _navigateToHome();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(hintText: "Full Name"),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(hintText: "Email"),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "Password"),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: WedifyButton(
              text: "Create Account",
              onPressed: () => _navigateToHome(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}
