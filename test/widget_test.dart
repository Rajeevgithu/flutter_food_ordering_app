import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_app/main.dart';
import 'package:e_commerce_app/pages/onboard.dart';

void main() {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build the app with Onboard as initial screen
    await tester.pumpWidget(const MyApp(initialScreen: Onboard()));

    // Verify MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Shows Onboard screen when app starts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialScreen: Onboard()));
    await tester.pumpAndSettle(); // Wait for animations/build

    // Check for a unique element in your Onboard screen
    expect(find.textContaining('Get Started'), findsOneWidget);
  });
}
