import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/models/dashboard_layout_controller.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/tool_definitions.dart';
import 'package:unitana/features/dashboard/widgets/dashboard_board.dart';
import 'package:unitana/features/dashboard/widgets/unitana_tile.dart';
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

  Future<void> pumpBoard(
    WidgetTester tester, {
    required UnitanaAppState state,
    required DashboardSessionController session,
    required DashboardLiveDataController liveData,
    required DashboardLayoutController layout,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: AnimatedBuilder(
              animation: Listenable.merge([session, liveData, layout]),
              builder: (context, _) => DashboardBoard(
                state: state,
                session: session,
                liveData: liveData,
                layout: layout,
                availableWidth: 358,
                isEditing: false,
                includePlacesHero: false,
                focusActionTileId: null,
                focusToolTileId: null,
                onEnteredEditMode: (_) {},
                onConsumedFocusTileId: () {},
                onConsumedFocusToolTileId: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder weatherTileFinder() {
    return find.byWidgetPredicate((w) {
      return w is UnitanaTile && w.title == 'Weather';
    });
  }

  testWidgets('Weather tile surfaces precip chance for the active reality', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    final session = DashboardSessionController();
    final liveData = DashboardLiveDataController();
    final layout = DashboardLayoutController();
    await layout.addTool(ToolDefinitions.weatherSummary);
    liveData.ensureSeeded(state.places);

    await pumpBoard(
      tester,
      state: state,
      session: session,
      liveData: liveData,
      layout: layout,
    );

    expect(weatherTileFinder(), findsOneWidget);
    var tile = tester.widget<UnitanaTile>(weatherTileFinder());
    expect(tile.primary, contains('°C'));
    expect(tile.secondary, contains('% precip'));

    session.setReality(DashboardReality.home);
    await tester.pump(const Duration(milliseconds: 200));

    tile = tester.widget<UnitanaTile>(weatherTileFinder());
    expect(tile.primary, contains('°F'));
    expect(tile.secondary.contains('% precip'), isFalse);
  });
}
