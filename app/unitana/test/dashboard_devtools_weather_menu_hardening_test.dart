import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';

Future<void> _scrollDownUntilFound(
  WidgetTester tester,
  Finder sheet,
  Finder target, {
  int maxScrolls = 8,
  double scrollDelta = 220,
}) async {
  for (var i = 0; i < maxScrolls && target.evaluate().isEmpty; i++) {
    // Drag up to scroll down.
    await tester.drag(sheet, Offset(0, -scrollDelta));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'Developer Tools -> Weather chooser does not overflow on a small phone',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final storage = UnitanaStorage();
      final seededPlaces = <Place>[
        const Place(
          id: 'home',
          type: PlaceType.living,
          name: 'Home',
          cityName: 'Denver',
          countryCode: 'US',
          timeZoneId: 'America/Denver',
          unitSystem: 'imperial',
          use24h: false,
        ),
        const Place(
          id: 'dest',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: 'Lisbon',
          countryCode: 'PT',
          timeZoneId: 'Europe/Lisbon',
          unitSystem: 'metric',
          use24h: true,
        ),
      ];

      await storage.savePlaces(seededPlaces);
      await storage.saveDefaultPlaceId('home');
      await storage.saveProfileName('Cody');

      final state = UnitanaAppState(storage);
      await state.load();

      await tester.binding.setSurfaceSize(const Size(320, 568));

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: UnitanaTheme.dark(),
            darkTheme: UnitanaTheme.dark(),
            themeMode: ThemeMode.dark,
            home: DashboardScreen(state: state),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        // Open the dashboard menu.
        final menuButton = find.byKey(const Key('dashboard_menu_button'));

        expect(menuButton, findsOneWidget);
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        final menuSheet = find.byType(BottomSheet).last;

        // Sanity: sheet is actually open.
        expect(
          find.descendant(of: menuSheet, matching: find.text('Edit Widgets')),
          findsOneWidget,
        );

        // Open Developer Tools. On small surfaces, this entry can be below the
        // fold, and ListView may not build it until scrolled.
        final developerToolsTile = find.descendant(
          of: menuSheet,
          matching: find.byKey(
            const ValueKey('dashboard_menu_developer_tools'),
            skipOffstage: false,
          ),
        );

        await _scrollDownUntilFound(tester, menuSheet, developerToolsTile);
        expect(developerToolsTile, findsOneWidget);
        await ensureVisibleAligned(tester, developerToolsTile);
        await tester.pump();
        await tester.tap(developerToolsTile);
        await tester.pumpAndSettle();

        // Developer Tools sheet.
        final devToolsSheet = find.byType(BottomSheet).last;

        // Open Weather chooser.
        final weatherMenuTile = find.descendant(
          of: devToolsSheet,
          matching: find.byKey(
            const ValueKey('devtools_weather_menu'),
            skipOffstage: false,
          ),
        );

        await _scrollDownUntilFound(tester, devToolsSheet, weatherMenuTile);
        expect(weatherMenuTile, findsOneWidget);
        await ensureVisibleAligned(tester, weatherMenuTile);
        await tester.pump();
        await tester.tap(weatherMenuTile);
        await tester.pumpAndSettle();

        // Chooser title should be visible.
        final chooserTitle = find.byKey(
          const ValueKey('devtools_weather_title'),
        );
        expect(chooserTitle, findsOneWidget);

        // Default should exist (pinned at the top).
        final defaultChoice = find.byKey(
          const ValueKey('devtools_weather_default'),
          skipOffstage: false,
        );
        expect(defaultChoice, findsOneWidget);

        // The chooser must be scrollable on small phones to avoid overflow.
        // Avoid depending on a specific modal type (BottomSheet vs route) or a
        // specific scroll-view type (ListView vs slivers).
        final chooserScrollable = find.ancestor(
          of: defaultChoice,
          matching: find.byType(Scrollable),
        );
        expect(chooserScrollable, findsWidgets);

        // Allow one more frame to flush any late layout.
        await tester.pump();

        // Drain any exceptions (including RenderFlex overflow) thrown during the
        // layout / paint for these sheets.
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
      } finally {
        await tester.binding.setSurfaceSize(null);
      }
    },
  );
}
