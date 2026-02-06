import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';

/// Ensures drag-reorder persists when the dashboard shifts between the
/// phone grid (2 columns) and tablet grid (3 columns).
///
/// Notes:
/// - Edit mode has a continuous “jiggle” animation, so avoid pumpAndSettle
///   once editing is enabled.
/// - We validate *reading order* (top-to-bottom, then left-to-right) instead
///   of assuming two tiles stay on the same row across layout changes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitanaAppState buildSeededState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);

    // Contract: places[0] = home, places[1] = destination.
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

  bool comesBefore(Offset a, Offset b) {
    // Compare in reading order (top-to-bottom, then left-to-right).
    // Resilient to header/padding changes that can shift row boundaries.
    const rowTolerance = 12.0;
    if ((a.dy - b.dy).abs() < rowTolerance) {
      return a.dx < b.dx;
    }
    return a.dy < b.dy;
  }

  testWidgets('edit-mode reorder persists across phone/tablet columns', (
    tester,
  ) async {
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

      // Avoid pumpAndSettle: the dashboard can contain continuous animations.
      await tester.pump(const Duration(milliseconds: 350));
    }

    addTearDown(() async => tester.binding.setSurfaceSize(null));

    // Phone (2 columns).
    await pumpDashboard(const Size(390, 844));

    // Enter edit mode via inline header action.
    await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('dashboard_edit_done')), findsOneWidget);

    final liquidsTile = find.byKey(const ValueKey('dashboard_item_liquids'));
    final areaTile = find.byKey(const ValueKey('dashboard_item_area'));

    expect(liquidsTile, findsOneWidget);
    expect(areaTile, findsOneWidget);

    // Pinned headers can occlude the top edge; align these tiles lower before
    // measuring positions and dragging.
    await ensureVisibleAligned(tester, liquidsTile);
    await ensureVisibleAligned(tester, areaTile);
    await tester.pump(const Duration(milliseconds: 50));

    final beforeLiquids = tester.getTopLeft(liquidsTile);
    final beforeArea = tester.getTopLeft(areaTile);

    // Defaults: Liquids appears before Area (reading order).
    expect(comesBefore(beforeLiquids, beforeArea), isTrue);

    final areaStack = find
        .ancestor(of: areaTile, matching: find.byType(Stack))
        .first;
    expect(areaStack, findsOneWidget);

    final areaHandle = find.descendant(
      of: areaStack,
      matching: find.byIcon(Icons.drag_indicator_rounded),
    );
    expect(areaHandle, findsOneWidget);

    // Drag Area handle onto Liquids tile center (robust across row shifts).
    final handleCenter = tester.getCenter(areaHandle);
    final liquidsCenter = tester.getCenter(liquidsTile);
    final delta = liquidsCenter - handleCenter;

    await tester.dragFrom(handleCenter, delta);
    await tester.pump(const Duration(milliseconds: 400));

    // Commit reorder.
    await tester.tap(find.byKey(const Key('dashboard_edit_done')));
    await tester.pump(const Duration(milliseconds: 400));

    final afterLiquids = tester.getTopLeft(liquidsTile);
    final afterArea = tester.getTopLeft(areaTile);

    // Swapped: Area now appears before Liquids (reading order).
    expect(comesBefore(afterArea, afterLiquids), isTrue);

    // Tablet (3 columns): rebuild with the same persisted preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));

    await pumpDashboard(const Size(900, 844));

    final tabletLiquids = tester.getTopLeft(liquidsTile);
    final tabletArea = tester.getTopLeft(areaTile);

    // Persisted: Area remains before Liquids in the tablet grid.
    expect(comesBefore(tabletArea, tabletLiquids), isTrue);
  });
}
