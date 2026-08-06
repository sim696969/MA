import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedify/app.dart';

void main() {
  testWidgets('Splash/Onboarding smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WedifyApp());

    // Verify that onboarding starts with automated tools
    expect(find.text('Automated Tools'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
