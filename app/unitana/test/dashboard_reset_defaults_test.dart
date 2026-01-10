import 'dart:convert';

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
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  testWidgets(
    'Reset Dashboard Defaults clears hidden defaults and user-added tiles',
    (tester) async {
      // Seed prefs with:
      // - a hidden default (Area)
      // - a user-added Distance tile persisted in the layout controller
      SharedPreferences.setMockInitialValues({
        'dashboard_hidden_defaults_v1': jsonEncode(<String>['area']),
        // Legacy key still supported for backward compatibility.
        'hidden_defaults_v1': jsonEncode(<String>['area']),
        'dashboard_layout_v1': jsonEncode([
          {
            'id': 'user_distance_1',
            'kind': 'tool',
            'toolId': 'distance',
            'colSpan': 1,
            'rowSpan': 1,
            'anchorIndex': 0,
            'userAdded': true,
          },
        ]),
      });

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final state = buildSeededState();
      await pumpDashboard(tester, state);

      // Hidden default should not be visible; user-added Distance should be visible.
      expect(find.text('Area'), findsNothing);
      expect(find.text('Distance'), findsAtLeastNWidgets(1));

      // Open the dashboard menu.
      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Trigger reset.
      await tester.tap(
        find.byKey(const ValueKey('dashboard_menu_reset_defaults')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Confirm.
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      // After reset:
      // - hidden default is cleared (Area returns)
      // - user-added layout is cleared (dashboard_layout_v1 removed)
      expect(find.text('Area'), findsAtLeastNWidgets(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get('dashboard_layout_v1'), isNull);
      expect(prefs.get('dashboard_hidden_defaults_v1'), isNull);
      expect(prefs.get('hidden_defaults_v1'), isNull);

      // Additionally validate that the reset toast is shown.
      expect(
        find.byKey(const ValueKey('toast_dashboard_reset_defaults')),
        findsOneWidget,
      );
    },
  );
}
