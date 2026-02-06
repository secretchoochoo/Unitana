import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/tool_definitions.dart';
import 'package:unitana/features/dashboard/widgets/tool_modal_bottom_sheet.dart';
import 'package:unitana/features/dashboard/widgets/weather_summary_bottom_sheet.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

import 'goldens_test_utils.dart';

void main() {
  final shouldRunGoldens = goldensEnabled();

  const home = Place(
    id: 'home',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    unitSystem: 'imperial',
    use24h: false,
  );
  const destination = Place(
    id: 'dest',
    type: PlaceType.visiting,
    name: 'Destination',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    unitSystem: 'metric',
    use24h: true,
  );

  Future<void> pumpToolSurface(
    WidgetTester tester, {
    required ToolDefinition tool,
  }) async {
    if (!shouldRunGoldens) return;

    final session = DashboardSessionController();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: Scaffold(
          body: ToolModalBottomSheet(
            tool: tool,
            session: session,
            preferMetric: false,
            prefer24h: false,
            home: home,
            destination: destination,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Tool surface contract goldens', () {
    testWidgets('Time base zone selectors', (tester) async {
      await pumpToolSurface(tester, tool: ToolDefinitions.time);
      if (!shouldRunGoldens) return;

      await expectLater(
        find.byKey(const ValueKey('tool_time_from_zone')),
        matchesGoldenFile('goldens/tool_time_from_zone_tile.png'),
      );
      await expectLater(
        find.byKey(const ValueKey('tool_time_to_zone')),
        matchesGoldenFile('goldens/tool_time_to_zone_tile.png'),
      );
    });

    testWidgets('Time Zone Converter card', (tester) async {
      await pumpToolSurface(tester, tool: ToolDefinitions.timeZoneConverter);
      if (!shouldRunGoldens) return;

      await tester.enterText(
        find.byKey(const ValueKey('tool_time_convert_input')),
        '2026-06-01 12:00',
      );
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 120));

      await expectLater(
        find.byKey(const ValueKey('tool_time_converter_card')),
        matchesGoldenFile('goldens/tool_time_zone_converter_card.png'),
      );
    });

    testWidgets('Tool title wraps to two lines with ellipsis', (tester) async {
      const longTitleTool = ToolDefinition(
        id: 'golden_long_title_overflow',
        canonicalToolId: 'length',
        title:
            'Extremely Long Tool Name For Overflow Validation Across Compact Modal Header',
        icon: Icons.straighten_rounded,
        defaultPrimary: '1 m',
        defaultSecondary: '3.28 ft',
      );

      await pumpToolSurface(tester, tool: longTitleTool);
      if (!shouldRunGoldens) return;

      await expectLater(
        find.byKey(const ValueKey('tool_title_golden_long_title_overflow')),
        matchesGoldenFile('goldens/tool_modal_long_title_overflow.png'),
      );
    });
  });

  group('Weather surface contract goldens', () {
    testWidgets('freshness: stale state', (tester) async {
      if (!shouldRunGoldens) return;

      SharedPreferences.setMockInitialValues({
        'places_v1': jsonEncode([home.toJson(), destination.toJson()]),
      });

      final liveData = DashboardLiveDataController(
        allowLiveRefreshInTestHarness: true,
      );
      addTearDown(liveData.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          home: Scaffold(
            body: WeatherSummaryBottomSheet(
              liveData: liveData,
              home: home,
              destination: destination,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byKey(const ValueKey('weather_summary_sheet')),
        matchesGoldenFile('goldens/weather_summary_stale.png'),
      );
    });

    testWidgets('freshness: live state', (tester) async {
      if (!shouldRunGoldens) return;

      SharedPreferences.setMockInitialValues({
        'places_v1': jsonEncode([home.toJson(), destination.toJson()]),
      });

      final liveData = DashboardLiveDataController(
        allowLiveRefreshInTestHarness: true,
      );
      addTearDown(liveData.dispose);
      liveData.debugSetLastRefreshedAt(DateTime.now());

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          home: Scaffold(
            body: WeatherSummaryBottomSheet(
              liveData: liveData,
              home: home,
              destination: destination,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byKey(const ValueKey('weather_summary_sheet')),
        matchesGoldenFile('goldens/weather_summary_live.png'),
      );
    });
  });
}
