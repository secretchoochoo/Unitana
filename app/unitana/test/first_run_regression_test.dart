import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app.dart';

/// Regression harness for the new-user wizard.
///
/// Goals:
/// - Step 2: after choosing Home + Destination, the primary controls remain
///   within a common phone viewport without requiring a scroll gesture.
/// - Step 3: the duplicate top preview toggle row stays removed.
///
/// Notes:
/// - City selection uses a bottom-sheet CityPicker with a virtualized list.
///   We search before tapping the ListTile so the selection is deterministic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('First run wizard regressions', () {
    Future<void> bootstrapApp(WidgetTester tester) async {
      await tester.pumpWidget(const UnitanaApp());
      // Allow async bootstrap to complete (mirrors app_smoke_test.dart).
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
    }

    Future<void> pickCity(
      WidgetTester tester, {
      required Finder openButton,
      required String query,
      required String cityName,
    }) async {
      await tester.ensureVisible(openButton);
      await tester.pumpAndSettle();

      // Open the city picker bottom sheet.
      await tester.tap(openButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The picker contains a TextField with a stable hint.
      final searchField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'Search city or country',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, query);
      await tester.pumpAndSettle();

      // Tap the matching city.
      final cityText = find.textContaining(cityName);
      expect(cityText, findsWidgets);
      final tile = find.ancestor(
        of: cityText.first,
        matching: find.byType(ListTile),
      );
      expect(tile, findsWidgets);
      await tester.tap(tile.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('Step 2 fits on a phone without scrolling', (tester) async {
      // Common phone surface.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await bootstrapApp(tester);

      // Move to step 2.
      final next = find.byKey(const Key('first_run_nav_next'));
      expect(next, findsOneWidget);
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();

      final homeBtn = find.byKey(const Key('first_run_home_city_button'));
      final destBtn = find.byKey(const Key('first_run_dest_city_button'));
      expect(homeBtn, findsOneWidget);
      expect(destBtn, findsOneWidget);

      // Pick home + destination using search so we don't depend on list scroll.
      await pickCity(
        tester,
        openButton: homeBtn,
        query: 'denver',
        cityName: 'Denver',
      );
      await pickCity(
        tester,
        openButton: destBtn,
        query: 'porto',
        cityName: 'Porto',
      );

      // Verify key controls are still within the viewport.
      // This approximates "fits on one screen" without brittle scroll metrics.
      final screen = tester.getRect(find.byType(Scaffold));
      final homeRect = tester.getRect(homeBtn);
      final destRect = tester.getRect(destBtn);
      final nextRect = tester.getRect(next);

      expect(homeRect.top, greaterThanOrEqualTo(screen.top));
      expect(destRect.bottom, lessThanOrEqualTo(screen.bottom));
      expect(nextRect.bottom, lessThanOrEqualTo(screen.bottom));
    });

    testWidgets('Initial first-run flow does not expose cancel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await bootstrapApp(tester);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byKey(const Key('first_run_cancel_button')), findsNothing);
    });

    testWidgets('Step 2 preview is stacked under the preview toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await bootstrapApp(tester);

      // Step 1 -> Step 2.
      final next = find.byKey(const Key('first_run_nav_next'));
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();

      final homeBtn = find.byKey(const Key('first_run_home_city_button'));
      final destBtn = find.byKey(const Key('first_run_dest_city_button'));

      await pickCity(
        tester,
        openButton: homeBtn,
        query: 'denver',
        cityName: 'Denver',
      );
      await pickCity(
        tester,
        openButton: destBtn,
        query: 'porto',
        cityName: 'Porto',
      );

      final toggle = find.byKey(
        const ValueKey('first_run_preview_reality_toggle'),
      );
      final preview = find.byKey(
        const ValueKey('first_run_preview_mini_hero_readout'),
      );
      expect(toggle, findsOneWidget);
      expect(preview, findsOneWidget);

      final toggleRect = tester.getRect(toggle);
      final previewRect = tester.getRect(preview);
      expect(previewRect.top, greaterThanOrEqualTo(toggleRect.bottom - 1));
    });

    testWidgets('Step 3 does not show the duplicate preview toggle row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await bootstrapApp(tester);

      // Step 1 -> Step 2.
      final next = find.byKey(const Key('first_run_nav_next'));
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();

      final homeBtn = find.byKey(const Key('first_run_home_city_button'));
      final destBtn = find.byKey(const Key('first_run_dest_city_button'));

      await pickCity(
        tester,
        openButton: homeBtn,
        query: 'denver',
        cityName: 'Denver',
      );
      await pickCity(
        tester,
        openButton: destBtn,
        query: 'porto',
        cityName: 'Porto',
      );

      // Step 2 -> Step 3.
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();

      // We should be on the confirm step.
      expect(find.byKey(const Key('first_run_step_confirm')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('first_run_profile_name_field')),
        findsOneWidget,
      );

      // The duplicate top toggle row must stay removed.
      // (We keep the hero's own internal toggle behavior.)
      expect(
        find.byKey(const ValueKey('first_run_preview_reality_toggle_main')),
        findsNothing,
      );

      // Confirm step should not be showing the "pick cities" placeholder.
      expect(find.textContaining('Go back and pick'), findsNothing);
    });
  });
}
