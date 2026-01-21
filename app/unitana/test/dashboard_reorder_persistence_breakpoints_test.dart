import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

/// Ensures drag-reorder persists when the dashboard shifts between the
/// phone grid (2 columns) and tablet grid (3 columns).
///
/// Notes:
/// - Edit mode has a continuous “jiggle” animation, so avoid pumpAndSettle
///   once editing is enabled.
/// - We reorder tiles that live below the hero region so anchor indices remain
///   valid across the 2-col -> 3-col mapping.
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

  testWidgets('edit-mode reorder persists across phone/tablet columns', (
    tester,
  ) async {
    // Deterministic storage across both pumps.
    SharedPreferences.setMockInitialValues({});

    final UnitanaAppState state = buildSeededState();

    Future<void> pumpDashboard(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          home: DashboardScreen(state: state),
        ),
      );

      // Let the initial async loads settle.
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }

    addTearDown(() async => tester.binding.setSurfaceSize(null));

    // Phone (2 columns).
    await pumpDashboard(const Size(390, 844));

    // Enter edit mode via the menu (avoids opening the per-tile actions sheet).
    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.tap(find.text('Edit widgets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final liquidsTile = find.byKey(const ValueKey('dashboard_item_liquids'));
    final areaTile = find.byKey(const ValueKey('dashboard_item_area'));

    expect(liquidsTile, findsOneWidget);
    expect(areaTile, findsOneWidget);

    final beforeLiquids = tester.getTopLeft(liquidsTile);
    final beforeArea = tester.getTopLeft(areaTile);

    // Defaults put Liquids left of Area in the same row.
    expect((beforeLiquids.dy - beforeArea.dy).abs(), lessThan(1.0));
    expect(beforeLiquids.dx, lessThan(beforeArea.dx));

    final areaStack = find
        .ancestor(of: areaTile, matching: find.byType(Stack))
        .first;
    expect(areaStack, findsOneWidget);

    final areaHandle = find.descendant(
      of: areaStack,
      matching: find.byIcon(Icons.pan_tool_alt_rounded),
    );
    expect(areaHandle, findsOneWidget);

    final delta = tester.getCenter(liquidsTile) - tester.getCenter(areaHandle);
    await tester.drag(areaHandle, delta);
    await tester.pump(const Duration(milliseconds: 350));

    // Commit reorder.
    await tester.tap(find.byKey(const Key('dashboard_edit_done')));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    final afterLiquids = tester.getTopLeft(liquidsTile);
    final afterArea = tester.getTopLeft(areaTile);

    // Swapped: Area now lives left of Liquids.
    expect((afterLiquids.dy - afterArea.dy).abs(), lessThan(1.0));
    expect(afterArea.dx, lessThan(afterLiquids.dx));

    // Tablet (3 columns): rebuild with the same persisted preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDashboard(const Size(900, 844));

    final tabletLiquids = tester.getTopLeft(liquidsTile);
    final tabletArea = tester.getTopLeft(areaTile);

    // Persisted: Area remains left of Liquids in the tablet grid.
    expect((tabletLiquids.dy - tabletArea.dy).abs(), lessThan(1.0));
    expect(tabletArea.dx, lessThan(tabletLiquids.dx));
  });
}
