import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/models/place.dart';
import 'dashboard_test_helpers.dart';

Future<void> _openToolPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
  await tester.pumpAndSettle();
}

Future<void> _searchTool(WidgetTester tester, String query) async {
  await tester.enterText(
    find.byKey(const ValueKey('toolpicker_search')),
    query,
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('Jet Lag Delta opens dedicated planner contract', (tester) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'jet lag');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_jet_lag_delta')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_jet_lag_delta')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tool_time_action_row')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool_time_swap_zones')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool_add_widget_time')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool_time_now_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_time_planner_card')),
      findsOneWidget,
    );
    expect(find.text('Travel Facts'), findsOneWidget);
    expect(find.text('Jet Lag Plan'), findsOneWidget);
    expect(find.textContaining('vs'), findsOneWidget);
    expect(find.textContaining('Flight:'), findsOneWidget);
    expect(find.textContaining('Band:'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_jetlag_bedtime_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_jetlag_wake_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_jetlag_personalized_schedule')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_jetlag_tip_rotator')),
      findsOneWidget,
    );
    expect(find.text('Quick Tips'), findsOneWidget);
    expect(find.text('Call Windows'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_jetlag_overlap_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_converter_card')),
      findsNothing,
    );
  });

  testWidgets('Jet Lag tip rotates on 5-second cadence', (tester) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'jet lag');
    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_jet_lag_delta')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_jetlag_tip_text_0')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('tool_jetlag_tip_text_1')),
      findsOneWidget,
    );
  });

  testWidgets('Jet Lag low-shift overlap is behind reveal control', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage)
      ..places = const [
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
        Place(
          id: 'dest',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: 'New York',
          countryCode: 'US',
          timeZoneId: 'America/New_York',
          unitSystem: 'imperial',
          use24h: false,
        ),
      ]
      ..defaultPlaceId = 'home';

    await pumpDashboardForTest(
      tester,
      state: state,
      surfaceSize: const Size(390, 900),
    );
    await _openToolPicker(tester);
    await _searchTool(tester, 'jet lag');
    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_jet_lag_delta')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_jetlag_overlap_toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_jetlag_overlap_panel')),
      findsNothing,
    );

    await ensureVisibleAligned(
      tester,
      find.byKey(const ValueKey('tool_jetlag_overlap_toggle')),
      alignment: 0.9,
    );
    await tester.tap(find.byKey(const ValueKey('tool_jetlag_overlap_toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_jetlag_overlap_panel')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Quick check before scheduling calls:'),
      findsOneWidget,
    );
  });
}
