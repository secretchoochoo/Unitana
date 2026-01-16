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

  Future<void> pumpUntilGone(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 40,
    Duration step = const Duration(milliseconds: 80),
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isEmpty) return;
    }
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

      // Sun pill exists and contains sunrise/sunset rows.
      expect(find.byKey(const ValueKey('hero_sun_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_sunrise_row')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_sunset_row')), findsOneWidget);

      // Marquee slot exists and is test-safe (still frame).
      expect(find.byKey(const ValueKey('hero_marquee_slot')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_alive_paint')), findsOneWidget);

      final sunrise = tester.widget<RichText>(
        find.byKey(const ValueKey('hero_sunrise_row')),
      );
      final sunset = tester.widget<RichText>(
        find.byKey(const ValueKey('hero_sunset_row')),
      );
      final sunriseText = (sunrise.text as TextSpan).toPlainText();
      final sunsetText = (sunset.text as TextSpan).toPlainText();

      // The detail rows should always render, even if live weather is disabled.
      // In hermetic/demo mode we may show placeholder clocks (`--:--`).
      void expectClocksOrPlaceholder(String text) {
        final clocks = RegExp(r'\b\d{1,2}:\d{2}\b').allMatches(text).toList();
        if (clocks.isEmpty) {
          expect(text, contains('--:--'));
        } else {
          expect(clocks.length, greaterThanOrEqualTo(2));
        }
      }

      // Labels may be word-based or icon-based depending on the active UX.
      expect(sunriseText, anyOf(contains('Sunrise'), contains('☀')));
      expect(sunsetText, anyOf(contains('Sunset'), contains('🌙')));
      expectClocksOrPlaceholder(sunriseText);
      expectClocksOrPlaceholder(sunsetText);
      // Default tiles on a fresh profile are currently: Height, Baking,
      // Liquids, Area. Distance is an enabled tool, but not a default tile.
      expect(find.text('Height'), findsOneWidget);
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
      // Even if tools share a canonical conversion engine, user-facing tools
      // have distinct IDs and history streams.
      expect(find.byKey(const ValueKey('tool_result_baking')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tool_history_baking_0')),
        findsOneWidget,
      );

      // Dismiss the modal sheet. Close button is deterministic and avoids
      // lingering modal barriers that can break hit-testing.
      await tester.tap(find.byKey(const ValueKey('tool_close_baking')));
      await pumpStable(tester);
      await pumpUntilGone(tester, find.byType(BottomSheet));
      await pumpUntilGone(tester, find.byType(ModalBarrier));

      // Liquids is a separate user-facing tool with its own history.
      final liquidsText = find.text('Liquids');
      await tester.ensureVisible(liquidsText);
      // Tap the tile surface (InkWell) instead of the Text node; the text
      // itself is not guaranteed to be hit-testable.
      final liquidsInk = find.ancestor(
        of: liquidsText,
        matching: find.byType(InkWell),
      );
      await tester.tap(
        liquidsInk.evaluate().isNotEmpty ? liquidsInk.first : liquidsText,
      );
      await pumpStable(tester);

      // The modal body is a scrollable ListView; on tight surfaces, the History
      // section may be below the fold.
      final emptyHistory = find.text('No history yet');
      if (emptyHistory.evaluate().isEmpty) {
        final scrollable = find.ancestor(
          of: find.byKey(const ValueKey('tool_input_liquids')),
          matching: find.byType(Scrollable),
        );
        if (scrollable.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            emptyHistory,
            160,
            scrollable: scrollable.first,
          );
          await pumpStable(tester);
        }
      }

      expect(emptyHistory, findsOneWidget);
    },
  );
}
