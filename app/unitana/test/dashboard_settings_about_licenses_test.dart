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
    state.places = const <Place>[
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

  testWidgets('Settings exposes About and Licenses entry points', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    Future<void> openSettingsSheet() async {
      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('dashboard_menu_settings')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    await openSettingsSheet();
    expect(find.byKey(const ValueKey('settings_sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_option_about')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_option_licenses')),
      findsOneWidget,
    );

    final aboutOption = find.byKey(const ValueKey('settings_option_about'));
    await tester.ensureVisible(aboutOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(aboutOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('settings_about_sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_about_tagline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings_about_legalese')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Close this panel').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await openSettingsSheet();
    final licensesOption = find.byKey(
      const ValueKey('settings_option_licenses'),
    );
    await tester.ensureVisible(licensesOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(licensesOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('settings_licenses_page')),
      findsOneWidget,
    );
  });
}
