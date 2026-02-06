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

    final profilesTile = find.widgetWithText(ListTile, 'Profiles');
    await ensureVisibleAligned(tester, profilesTile);
    await tester.tap(profilesTile);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profiles_board_screen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('profiles_board_wiggle_profile_1')),
      findsOneWidget,
    );

    final editFinder = find.byKey(
      const ValueKey('profiles_board_edit_profile_1'),
    );
    expect(editFinder, findsOneWidget);
    final editButton = tester.widget<IconButton>(editFinder);
    editButton.onPressed?.call();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const Key('first_run_step_welcome'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    // Confirm we landed in the wizard (edit mode currently opens at Step 1).
    expect(find.byKey(const Key('first_run_step_welcome')), findsOneWidget);
    expect(find.byKey(const Key('first_run_cancel_button')), findsOneWidget);

    // Cancel should return to the profiles board.
    await tester.tap(find.byKey(const Key('first_run_cancel_button')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const Key('profiles_board_screen'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('profiles_board_screen')), findsOneWidget);

    // Regression invariant: Step 3 must not show the redundant top preview toggle row.
    expect(
      find.byKey(const ValueKey('first_run_preview_reality_toggle_main')),
      findsNothing,
    );
  });
}
