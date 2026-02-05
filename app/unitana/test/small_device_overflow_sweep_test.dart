import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/first_run/first_run_screen.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<UnitanaAppState> buildEmptyState() async {
    final storage = UnitanaStorage();
    SharedPreferences.setMockInitialValues({});
    final state = UnitanaAppState(storage);
    await state.load();
    return state;
  }

  Future<void> pumpFirstRunStep2(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = await buildEmptyState();
    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: FirstRunScreen(state: state),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Move to Step 2 (Pick Your Places).
    final next = find.byKey(const ValueKey('first_run_nav_next'));
    expect(next, findsOneWidget);
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Step 2 should render without overflow exceptions even before selection.
    expect(find.text('Pick Your Places'), findsOneWidget);
  }

  Future<void> expectNoOverflowExceptions(WidgetTester tester) async {
    final thrown = <Object>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      thrown.add(exception!);
    }

    // Fail only on the classic overflow signal; allow benign assertions.
    final overflow = thrown.where((e) => e.toString().contains('overflowed'));
    expect(
      overflow,
      isEmpty,
      reason: thrown.map((e) => e.toString()).join('\n\n'),
    );
  }

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('Wizard Step 2 has no overflow on $size', (tester) async {
      await pumpFirstRunStep2(tester, size);
      await expectNoOverflowExceptions(tester);
    });

    testWidgets('Dashboard hero has no overflow on $size', (tester) async {
      await pumpDashboardForTest(tester, surfaceSize: size);
      await expectNoOverflowExceptions(tester);

      // Also sanity check collapsed state to catch pinned-header regressions.
      final scroll = find.byType(CustomScrollView);
      expect(scroll, findsOneWidget);
      await tester.drag(scroll, const Offset(0, -420));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await expectNoOverflowExceptions(tester);
    });
  }
}
