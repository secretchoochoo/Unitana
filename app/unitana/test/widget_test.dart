// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
//
// NOTE:
// This test has been adapted from the default Flutter counter example.
// Unitana does not use a counter or a MyApp widget, so this is now a simple
// smoke test that verifies the app builds and renders without errors.

import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/app/app.dart';

void main() {
  testWidgets('Unitana app builds smoke test', (WidgetTester tester) async {
    // Build the Unitana app and trigger the initial frame.
    await tester.pumpWidget(const UnitanaApp());

    // Allow async initialization (storage load, etc.) to settle.
    await tester.pump();

    // Verify that the root app widget is present.
    expect(find.byType(UnitanaApp), findsOneWidget);
  });
}
