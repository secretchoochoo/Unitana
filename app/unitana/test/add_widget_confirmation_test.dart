import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        use24h: false,
      ),
      Place(
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
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  testWidgets('Add Widget confirmation is visible while tool modal is open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open the ToolPickerSheet via the dedicated top-left Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Use search so we don't depend on lens ordering.
    final search = find.byKey(const ValueKey('toolpicker_search'));
    expect(search, findsOneWidget);
    await tester.enterText(search, 'Distance');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final distanceResult = find.byKey(
      const Key('toolpicker_search_tool_distance'),
    );
    expect(distanceResult, findsOneWidget);
    await tester.tap(distanceResult);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Tool modal is now open; add the widget.
    final addWidget = find.byKey(const ValueKey('tool_add_widget_distance'));
    expect(addWidget, findsOneWidget);
    await tester.tap(addWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    // Confirmation should be visible while the modal is open.
    final notice = find.byKey(
      const ValueKey('tool_add_widget_notice_distance'),
    );
    expect(notice, findsOneWidget);
    expect(
      find.byKey(const ValueKey('add_widget_banner_distance')),
      findsNothing,
    );
    expect(find.text('Added Distance to dashboard'), findsAtLeastNWidgets(1));

    // Auto-dismiss after a short time.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(notice, findsNothing);
  });

  testWidgets('Dashboard Tools button opens the ToolPickerSheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Top-left Tools button should open the picker without going through the menu.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('toolpicker_search')), findsOneWidget);
  });
}
