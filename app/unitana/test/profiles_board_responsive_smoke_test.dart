import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _openProfilesBoard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dashboard_menu_button')));
  final profilesTile = find.widgetWithText(ListTile, 'Profiles');
  await pumpUntilFound(tester, profilesTile);
  await ensureVisibleAligned(tester, profilesTile);
  await tester.tap(profilesTile);
  await pumpUntilFound(tester, find.byKey(const Key('profiles_board_screen')));
}

void main() {
  testWidgets(
    'Profiles board renders on a small phone without layout exceptions',
    (tester) async {
      await pumpDashboardForTest(tester, surfaceSize: const Size(320, 568));
      await _openProfilesBoard(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final thrown = <Object>[];
      Object? exception;
      while ((exception = tester.takeException()) != null) {
        thrown.add(exception!);
      }

      expect(
        thrown,
        isEmpty,
        reason: thrown.map((e) => e.toString()).join('\n\n'),
      );
      expect(find.byKey(const Key('profiles_board_screen')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profiles_board_more_profile_1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Profiles board renders on a tablet and keeps tile actions visible',
    (tester) async {
      await pumpDashboardForTest(tester, surfaceSize: const Size(900, 844));
      await _openProfilesBoard(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final thrown = <Object>[];
      Object? exception;
      while ((exception = tester.takeException()) != null) {
        thrown.add(exception!);
      }

      expect(
        thrown,
        isEmpty,
        reason: thrown.map((e) => e.toString()).join('\n\n'),
      );
      expect(find.byKey(const Key('profiles_board_grid')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profiles_board_more_profile_1')),
        findsOneWidget,
      );

      final grid = tester.widget<GridView>(
        find.byKey(const Key('profiles_board_grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    },
  );
}
