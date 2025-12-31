import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    // The dashboard contains live UI elements (eg, time displays) that may
    // schedule frames continuously. `pumpAndSettle` can time out in tests.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets(
    'Places Hero V2 toggles realities and tool modal defaults to active units',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final state = UnitanaAppState(UnitanaStorage());
      await state.load();

      state.profileName = 'Lisbon';
      state.places = <Place>[
        Place(
          id: 'dest',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: 'Lisbon',
          countryCode: 'PT',
          timeZoneId: 'Europe/Lisbon',
          unitSystem: 'metric',
          use24h: false,
        ),
        Place(
          id: 'home',
          type: PlaceType.living,
          name: 'Home',
          cityName: 'Denver',
          countryCode: 'US',
          timeZoneId: 'America/Denver',
          unitSystem: 'imperial',
          use24h: false,
        ),
      ];

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(state: state)));
      await pumpStable(tester);

      expect(find.byKey(const ValueKey('places_hero_v2')), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Baking'), findsOneWidget);
      expect(find.text('Liquids'), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);

      // Destination is selected by default (metric).
      final primaryTempBefore = tester.widget<Text>(
        find.byKey(const ValueKey('hero_primary_temp')),
      );
      expect(primaryTempBefore.data, contains('C'));

      // Baking should default to metric input when destination is active.
      await tester.tap(find.text('Baking'));
      await pumpStable(tester);

      expect(find.text('History'), findsOneWidget);
      expect(find.text('ml → cup'), findsOneWidget);

      // The tools open as a modal bottom sheet, not a pushed route.
      // Dismiss by tapping the scrim (top-left is outside the sheet).
      await tester.tapAt(const Offset(10, 10));
      await pumpStable(tester);
      expect(find.text('History'), findsNothing);

      // Toggle to home (imperial).
      await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
      await pumpStable(tester);

      final primaryTempAfter = tester.widget<Text>(
        find.byKey(const ValueKey('hero_primary_temp')),
      );
      expect(primaryTempAfter.data, contains('F'));

      // Baking should now default to imperial input.
      await tester.tap(find.text('Baking'));
      await pumpStable(tester);

      expect(find.text('cup → ml'), findsOneWidget);

      // Run a conversion.
      await tester.enterText(
        find.byKey(const ValueKey('tool_input_baking')),
        '1',
      );
      await tester.tap(find.byKey(const ValueKey('tool_run_baking')));
      await pumpStable(tester);

      // Inline result and first history entry.
      // Baking is a lens on the canonical Liquids tool, so result/history keys use the canonical toolId.
      expect(find.byKey(const ValueKey('tool_result_liquids')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tool_history_liquids_0')),
        findsOneWidget,
      );

      // Dismiss the modal sheet.
      await tester.drag(find.byType(BottomSheet), const Offset(0, 600));
      await pumpStable(tester);

      // Liquids shares the same canonical history stream as Baking (both are liquids).
      await tester.tap(find.text('Liquids'));
      await pumpStable(tester);

      expect(
        find.byKey(const ValueKey('tool_history_liquids_0')),
        findsOneWidget,
      );
      // Multiple widgets may include the substring (chips, inputs, result). Assert the history row contains it.
      final historyRow = find.byKey(const ValueKey('tool_history_liquids_0'));
      expect(
        find.descendant(of: historyRow, matching: find.textContaining('cup')),
        findsAtLeastNWidgets(1),
      );
    },
  );
}
