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

  testWidgets('Quick Tools lens is not shown in the picker accordion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open the picker via the dashboard Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('toolpicker_lens_quick_tools')),
      findsNothing,
    );
    expect(find.text('Quick Tools'), findsNothing);

    // Search still works and returns tools.
    final search = find.byKey(const ValueKey('toolpicker_search'));
    expect(search, findsOneWidget);
    await tester.enterText(search, 'Area');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('toolpicker_search_tool_area')),
      findsOneWidget,
    );
  });
}
