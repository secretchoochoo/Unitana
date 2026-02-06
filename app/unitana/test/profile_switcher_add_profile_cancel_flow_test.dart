import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets(
    'Add profile wizard can cancel back to switcher and discards draft profile',
    (tester) async {
      await pumpDashboardForTest(tester);

      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      await tester.pumpAndSettle();

      final profilesTile = find.widgetWithText(ListTile, 'Profiles');
      await ensureVisibleAligned(tester, profilesTile);
      await tester.tap(profilesTile);
      await tester.pumpAndSettle();

      final addTile = find.byKey(const Key('profiles_board_add_profile'));
      await ensureVisibleAligned(tester, addTile);
      await tester.tap(addTile);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first_run_cancel_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('first_run_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profiles_board_screen')), findsOneWidget);

      // Draft profile should be removed on cancel, so only active profile row remains.
      expect(
        find.byKey(const ValueKey('profiles_board_tile_profile_2')),
        findsNothing,
      );
    },
  );
}
