import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Insert your API key here (Google Maps, Google Auth, ToyyibPay)
  
  runApp(
    const ProviderScope(
      child: WedifyApp(),
    ),
  );
}
