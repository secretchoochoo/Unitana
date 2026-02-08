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

  testWidgets('Settings opens language sheet and persists selection', (
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

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('settings_language_system')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings_language_en')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_language_es')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_language_es')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(state.preferredLanguageCode, 'es');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('preferred_language_code_v1'), 'es');
  });
}
