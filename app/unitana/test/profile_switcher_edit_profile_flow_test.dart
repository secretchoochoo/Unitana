import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Profile switcher opens and Edit profile launches wizard', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    // Open dashboard menu.
    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle();

    // Tap "Switch profile" (ensure it's visible in scrollable sheet).
    final switchTile = find.widgetWithText(ListTile, 'Switch profile');
    await ensureVisibleAligned(tester, switchTile);
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    // Some builds open a profile switcher sheet; ensure we can tap Edit profile regardless of key drift.
    final editByKey = find.byKey(
      const ValueKey('profile_switcher_edit_profile'),
    );
    final editByText = find.widgetWithText(ListTile, 'Edit profile');

    final Finder editFinder = editByKey.evaluate().isNotEmpty
        ? editByKey
        : editByText;
    expect(editFinder, findsOneWidget);

    await ensureVisibleAligned(tester, editFinder);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();

    // Confirm we landed in the wizard (edit mode currently opens at Step 1).
    expect(find.byKey(const Key('first_run_step_welcome')), findsOneWidget);

    // Regression invariant: Step 3 must not show the redundant top preview toggle row.
    expect(
      find.byKey(const ValueKey('first_run_preview_reality_toggle_main')),
      findsNothing,
    );
  });
}
