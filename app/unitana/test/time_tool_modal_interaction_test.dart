import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  UnitanaAppState buildSeededState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);
    state.places = const [
      Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: true,
      ),
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
    ];
    state.defaultPlaceId = 'home';
    return state;
  }

  Future<void> pumpDashboard(WidgetTester tester, UnitanaAppState state) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  Future<void> openTimeTool(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'time',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('toolpicker_search_tool_time')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> openTimeZoneConverterTool(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'time zone converter',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_timezone_lookup')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  testWidgets('Time modal renders dedicated timezone workspace', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeTool(tester);

    expect(find.byKey(const ValueKey('tool_time_now_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_time_dual_analog_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_analog_clock_home')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_analog_clock_destination')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tool_time_planner_card')), findsNothing);
    expect(find.byKey(const ValueKey('tool_time_from_zone')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool_time_to_zone')), findsOneWidget);

    // No generic converter UI for Time.
    expect(find.byKey(const ValueKey('tool_input_time')), findsNothing);
    expect(find.byKey(const ValueKey('tool_run_time')), findsNothing);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('Time modal defaults from active reality zone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Home reality => From should seed to the home city.
    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await openTimeTool(tester);
    final fromHome = find.descendant(
      of: find.byKey(const ValueKey('tool_time_from_zone')),
      matching: find.textContaining('Denver'),
    );
    expect(fromHome, findsOneWidget);

    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Destination reality => From should seed to the destination city.
    await tester.tap(
      find.byKey(const ValueKey('places_hero_segment_destination')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await openTimeTool(tester);
    final fromDestination = find.descendant(
      of: find.byKey(const ValueKey('tool_time_from_zone')),
      matching: find.textContaining('Lisbon'),
    );
    expect(fromDestination, findsOneWidget);
  });

  testWidgets('Time Zone Converter opens from timezone lookup alias', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeZoneConverterTool(tester);

    expect(
      find.byKey(const ValueKey('tool_title_time_zone_converter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_converter_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_convert_input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tool_time_convert_run')), findsOneWidget);
  });

  testWidgets('Time Zone Converter converts and stores explicit history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeZoneConverterTool(tester);

    await tester.enterText(
      find.byKey(const ValueKey('tool_time_convert_input')),
      '2026-06-01 12:00',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.ensureVisible(
      find.byKey(const ValueKey('tool_time_convert_run')),
    );
    await tester.tap(find.byKey(const ValueKey('tool_time_convert_run')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('tool_result_time_zone_converter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_history_list')),
      findsOneWidget,
    );
  });

  testWidgets('Time zone picker defaults to city-first search', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeZoneConverterTool(tester);

    await tester.tap(find.byKey(const ValueKey('tool_time_from_zone')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.textContaining('EST · New York'), findsOneWidget);
    expect(find.textContaining('CST · Chicago'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('tool_time_zone_search_from')),
      'tokyo',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(
      find.byKey(
        const ValueKey('tool_time_city_item_from_tokyo_jp_asia_tokyo'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('tool_time_city_item_from_tokyo_jp_asia_tokyo'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('tool_time_city_item_from_tokyo_jp_asia_tokyo'),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tool_time_from_zone')),
        matching: find.textContaining('Tokyo'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Time zone picker supports timezone-id fallback search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeZoneConverterTool(tester);

    await tester.tap(find.byKey(const ValueKey('tool_time_from_zone')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byKey(const ValueKey('tool_time_zone_search_from')),
      'asia/tokyo',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('tool_time_zone_item_from_Asia_Tokyo')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tool_time_zone_item_from_Asia_Tokyo')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tool_time_from_zone')),
        matching: find.textContaining('Tokyo'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Time zone picker resolves EST alias to US Eastern', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);
    await openTimeZoneConverterTool(tester);

    await tester.tap(find.byKey(const ValueKey('tool_time_from_zone')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byKey(const ValueKey('tool_time_zone_search_from')),
      'EST',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.textContaining('New York'), findsWidgets);
  });
}
