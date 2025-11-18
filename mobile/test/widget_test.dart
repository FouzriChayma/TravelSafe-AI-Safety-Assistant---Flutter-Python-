// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('TravelSafe app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TravelSafeApp());

    // Verify that the app loads (check for TravelSafe text or login screen)
    await tester.pumpAndSettle();
    
    // The app should show either login screen or main screen
    // This is a basic smoke test to ensure the app doesn't crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
