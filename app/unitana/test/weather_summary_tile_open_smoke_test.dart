import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';
import 'test_utils/pinned_header_tap.dart';

void main() {
  testWidgets(
    'Weather Summary tile opens its read-only sheet and renders core labels',
    (WidgetTester tester) async {
      // Seed a deterministic user-added weather summary tile so tests can tap a
      // stable key without relying on a generated item id.
      SharedPreferences.setMockInitialValues({
        'dashboard_layout_v1': jsonEncode([
          {
            'id': 'weather_summary_test',
            'kind': 'tool',
            'toolId': 'weather_summary',
            'colSpan': 1,
            'rowSpan': 1,
            'anchorIndex': null,
            'userAdded': true,
          },
        ]),
      });

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

      await tester.binding.setSurfaceSize(const Size(390, 844));

      Finder textInSheetWhere(bool Function(String) predicate, Finder sheet) {
        return find.descendant(
          of: sheet,
          matching: find.byWidgetPredicate((w) {
            if (w is! Text) return false;
            final t = w.data;
            if (t == null) return false;
            return predicate(t);
          }),
        );
      }

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: UnitanaTheme.dark(),
            darkTheme: UnitanaTheme.dark(),
            themeMode: ThemeMode.dark,
            home: DashboardScreen(state: state),
          ),
        );

        // Avoid pumpAndSettle: periodic work/animations may keep the frame
        // scheduler "unsettled".
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final tileKey = const ValueKey('dashboard_item_weather_summary_test');
        expect(find.byKey(tileKey), findsOneWidget);

        await ensureVisibleAligned(tester, find.byKey(tileKey));
        await safeTapPinned(
          tester,
          find.byKey(tileKey),
          obstruction: find.byKey(
            const ValueKey('dashboard_collapsing_header_mini_layer'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));

        final sheetKey = const ValueKey('weather_summary_sheet');
        final sheetFinder = find.byKey(sheetKey);
        expect(sheetFinder, findsOneWidget);

        // Core contract labels.
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Weather')),
          findsOneWidget,
        );

        // Refresh label can be either "Not updated" (hermetic) or
        // "Updated X ago" (if Dashboard triggers an auto-refresh on open).
        final refreshText = textInSheetWhere(
          (t) => t.startsWith('Updated ') || t.contains('Not updated'),
          sheetFinder,
        );
        expect(refreshText.evaluate().isNotEmpty, isTrue);
        // Place header rows: avoid brittle spacing around the middle dot.
        final destinationHeader = textInSheetWhere(
          (t) => t.contains('Destination') && t.contains('Lisbon'),
          sheetFinder,
        );
        expect(destinationHeader.evaluate().isNotEmpty, isTrue);

        final homeHeader = textInSheetWhere(
          (t) => t.contains('Home') && t.contains('Denver'),
          sheetFinder,
        );
        expect(homeHeader.evaluate().isNotEmpty, isTrue);
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.byKey(
              const ValueKey('weather_summary_bridge_split'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.byKey(
              const ValueKey('weather_summary_bridge_city_dest'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.byKey(
              const ValueKey('weather_summary_bridge_city_home'),
            ),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('weather_summary_refresh')),
          findsOneWidget,
        );

        // Sunrise/sunset and wind/gust headers should render for both cards.
        expect(
          find
              .descendant(of: sheetFinder, matching: find.textContaining('☀️'))
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(
          find
              .descendant(of: sheetFinder, matching: find.textContaining('🌙'))
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(
          find
              .descendant(of: sheetFinder, matching: find.textContaining('🌬️'))
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(
          find
              .descendant(of: sheetFinder, matching: find.textContaining('💨'))
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(
          find
              .descendant(of: sheetFinder, matching: find.text('🌫️ AQI (US)'))
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(
          find
              .descendant(
                of: sheetFinder,
                matching: find.text('🌼 Pollen (0-5)'),
              )
              .evaluate()
              .length,
          greaterThanOrEqualTo(2),
        );

        // Drain any exceptions thrown during open/render.
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
