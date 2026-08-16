import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once at startup
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Stripe with publishable key
  Stripe.publishableKey =
      'pk_test_51SXBnqAGOuxJcOdihnjLPyYp6si8k4ZttERMpAwUnMagV35bsIaFDQnlS1qjYHJgBLaw9fxwO6KviEUKCZFc2Rse003tXJt409';
  if (!kIsWeb) {
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: WedifyApp()));
}
