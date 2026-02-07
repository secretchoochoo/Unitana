import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/data/cities.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/l10n/city_picker_copy.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';
import 'package:unitana/widgets/city_picker.dart';

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

  testWidgets('wizard city picker uses shared city-only copy contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CityPicker(cities: kCuratedCities)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        CityPickerCopy.topHeader(tester.element(find.byType(CityPicker))),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText ==
                CityPickerCopy.searchHint(
                  tester.element(find.byType(CityPicker)),
                  mode: CityPickerMode.cityOnly,
                ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('time picker uses shared city+timezone copy contract', (
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

    final context = tester.element(find.byType(BottomSheet).first);
    expect(find.text(CityPickerCopy.topHeader(context)), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText ==
                CityPickerCopy.searchHint(
                  context,
                  mode: CityPickerMode.cityAndTimezone,
                ),
      ),
      findsOneWidget,
    );
  });
}
