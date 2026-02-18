// This is a basic Flutter widget test for the Login Page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahara_fuel_app/main.dart';

void main() {
  testWidgets('MyApp initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify app built successfully (no exception thrown)
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('LoginPage is rendered', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the LoginPage widget is present
    expect(find.byType(LoginPage), findsOneWidget);
  });
  
  testWidgets('Log In text is visible', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the Log In text is present
    expect(find.text('Log In'), findsWidgets);
  });

  testWidgets('Email icon is present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the email icon is present
    expect(find.byIcon(Icons.person_outline), findsWidgets);
  });

  testWidgets('Password icon is present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the password icon is present
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
  });

  testWidgets('Login button is present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Scroll down to find the button if needed
    await tester.pumpAndSettle();
    
    // Verify that the LOG IN button is present
    expect(find.text('LOG IN'), findsWidgets);
  });

  testWidgets('Checkbox widget exists', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify checkbox is present
    expect(find.byType(Checkbox), findsWidgets);
  });
}
