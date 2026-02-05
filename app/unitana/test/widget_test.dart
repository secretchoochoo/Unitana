import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/first_run/first_run_screen.dart';

void main() {
  testWidgets('First run welcome stays until user navigates forward', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final state = UnitanaAppState(UnitanaStorage());
    await state.load();

    await tester.pumpWidget(MaterialApp(home: FirstRunScreen(state: state)));
    await tester.pumpAndSettle();

    // We key the steps so this test survives copy and layout changes.
    expect(
      find.byKey(const ValueKey('first_run_step_welcome')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('first_run_nav_next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('first_run_step_places')), findsOneWidget);
    expect(find.byKey(const ValueKey('first_run_step_welcome')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('first_run_nav_prev')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('first_run_step_welcome')),
      findsOneWidget,
    );
  });
}
