import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets(
    'Dashboard tiles expose richer semantics and visible action buttons',
    (tester) async {
      final handle = tester.ensureSemantics();

      await pumpDashboardForTest(tester);

      final tileFinder = find.byKey(const ValueKey('dashboard_item_baking'));
      final moreButton = find.byKey(
        const ValueKey('dashboard_tile_more_baking'),
      );

      await pumpUntilFound(tester, tileFinder);
      await ensureVisibleAligned(tester, tileFinder);

      final tileSemantics = tester.getSemantics(tileFinder).getSemanticsData();
      final moreSemantics = tester.getSemantics(moreButton).getSemanticsData();

      expect(tileSemantics.flagsCollection.isButton, isTrue);
      expect(tileSemantics.label, contains('Baking'));
      expect(
        tileSemantics.hint,
        'Double tap to open. More actions button available.',
      );
      expect(moreSemantics.flagsCollection.isButton, isTrue);
      expect(moreSemantics.label, 'More tile actions');

      handle.dispose();
    },
  );

  testWidgets(
    'Profile tiles expose selected semantics and a visible actions button',
    (tester) async {
      final handle = tester.ensureSemantics();

      await pumpDashboardForTest(tester);

      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      final profilesTile = find.widgetWithText(ListTile, 'Profiles');
      await pumpUntilFound(tester, profilesTile);
      await ensureVisibleAligned(tester, profilesTile);
      await tester.tap(profilesTile);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profiles_board_screen')),
      );

      final tileFinder = find.byKey(
        const ValueKey('profiles_board_tile_profile_1'),
      );
      final moreButton = find.byKey(
        const ValueKey('profiles_board_more_profile_1'),
      );

      final tileSemantics = tester.getSemantics(tileFinder).getSemanticsData();
      final moreSemantics = tester.getSemantics(moreButton).getSemanticsData();

      expect(tileSemantics.flagsCollection.isButton, isTrue);
      expect(tileSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(tileSemantics.label, contains('Denver'));
      expect(tileSemantics.label, contains('Porto'));
      expect(tileSemantics.hint, contains('More actions button available'));
      expect(moreSemantics.flagsCollection.isButton, isTrue);
      expect(moreSemantics.label, 'More profile actions');

      handle.dispose();
    },
  );
}
