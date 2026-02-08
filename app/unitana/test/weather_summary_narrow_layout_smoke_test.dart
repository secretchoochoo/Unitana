import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/models/dashboard_copy.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';
import 'package:unitana/theme/dracula_palette.dart';

import 'dashboard_test_helpers.dart';
import 'test_utils/pinned_header_tap.dart';

void main() {
  testWidgets(
    'Weather Summary forecast panel is overflow-safe on narrow phone',
    (WidgetTester tester) async {
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
      await storage.savePlaces(const <Place>[
        Place(
          id: 'home',
          type: PlaceType.living,
          name: 'Home',
          cityName: 'Chicago',
          countryCode: 'US',
          timeZoneId: 'America/Chicago',
          unitSystem: 'imperial',
          use24h: false,
        ),
        Place(
          id: 'dest',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: 'Barcelona',
          countryCode: 'ES',
          timeZoneId: 'Europe/Madrid',
          unitSystem: 'metric',
          use24h: true,
        ),
      ]);
      await storage.saveDefaultPlaceId('home');
      await storage.saveProfileName('Cody');

      final state = UnitanaAppState(storage);
      await state.load();

      await tester.binding.setSurfaceSize(const Size(320, 640));
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
        await tester.pump(const Duration(milliseconds: 220));

        const tileKey = ValueKey('dashboard_item_weather_summary_test');
        await ensureVisibleAligned(tester, find.byKey(tileKey));
        await safeTapPinned(
          tester,
          find.byKey(tileKey),
          obstruction: find.byKey(
            const ValueKey('dashboard_collapsing_header_mini_layer'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));

        final sheetFinder = find.byKey(const ValueKey('weather_summary_sheet'));
        expect(sheetFinder, findsOneWidget);

        final hourlyMode = find.byKey(
          const ValueKey('weather_summary_forecast_mode_dest_hourly'),
        );
        final dailyMode = find.byKey(
          const ValueKey('weather_summary_forecast_mode_dest_daily'),
        );
        expect(hourlyMode, findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('weather_summary_forecast_mode_hourly_tap_dest'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('weather_summary_forecast_mode_daily_tap_dest'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('weather_summary_forecast_swap_dest')),
          findsOneWidget,
        );
        final legend = find.byKey(
          const ValueKey('weather_summary_forecast_legend_dest'),
        );
        expect(legend, findsOneWidget);
        final legendText = tester.widget<Text>(legend);
        expect(
          legendText.style?.color,
          DraculaPalette.foreground.withAlpha(230),
        );
        final hourlyTap = find.byKey(
          const ValueKey('weather_summary_forecast_mode_hourly_tap_dest'),
        );
        final dailyTap = find.byKey(
          const ValueKey('weather_summary_forecast_mode_daily_tap_dest'),
        );
        final hourlySemantics = tester.widget<Semantics>(
          find.ancestor(of: hourlyTap, matching: find.byType(Semantics)).first,
        );
        final dailySemantics = tester.widget<Semantics>(
          find.ancestor(of: dailyTap, matching: find.byType(Semantics)).first,
        );
        expect(hourlySemantics.properties.button, isTrue);
        expect(hourlySemantics.properties.selected, isTrue);
        expect(dailySemantics.properties.button, isTrue);
        expect(dailySemantics.properties.selected, isFalse);
        final swapLabel = DashboardCopy.weatherForecastSwapTooltip(
          tester.element(sheetFinder),
        );
        final swapTooltip = tester.widget<Tooltip>(
          find
              .ancestor(
                of: find.byKey(
                  const ValueKey('weather_summary_forecast_swap_dest'),
                ),
                matching: find.byType(Tooltip),
              )
              .first,
        );
        expect(swapTooltip.message, swapLabel);
        expect(
          find.byKey(
            const ValueKey('weather_summary_forecast_chart_semantics_dest'),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey('weather_summary_forecast_mode_daily_tap_dest'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 220));
        expect(dailyMode, findsOneWidget);
        final dailySemanticsSelected = tester.widget<Semantics>(
          find.ancestor(of: dailyTap, matching: find.byType(Semantics)).first,
        );
        expect(dailySemanticsSelected.properties.selected, isTrue);

        await tester.tap(
          find.byKey(const ValueKey('weather_summary_forecast_swap_dest')),
        );
        await tester.pump(const Duration(milliseconds: 220));
        expect(hourlyMode, findsOneWidget);

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
