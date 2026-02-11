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

    // Enter edit mode via the top-right menu.
    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('dashboard_edit_done')), findsOneWidget);

    final bakingTile = find.byKey(const ValueKey('dashboard_item_baking'));
    final distanceTile = find.byKey(const ValueKey('dashboard_item_distance'));

    expect(bakingTile, findsOneWidget);
    expect(distanceTile, findsOneWidget);

    // Pinned headers can occlude the top edge; align these tiles lower before
    // measuring positions and dragging.
    await ensureVisibleAligned(tester, bakingTile);
    await ensureVisibleAligned(tester, distanceTile);
    await tester.pump(const Duration(milliseconds: 50));

    final beforeBaking = tester.getTopLeft(bakingTile);
    final beforeDistance = tester.getTopLeft(distanceTile);

    // Defaults: Baking appears before Distance (reading order).
    expect(comesBefore(beforeBaking, beforeDistance), isTrue);

    final distanceStack = find
        .ancestor(of: distanceTile, matching: find.byType(Stack))
        .first;
    expect(distanceStack, findsOneWidget);

    final distanceHandle = find.descendant(
      of: distanceStack,
      matching: find.byIcon(Icons.drag_indicator_rounded),
    );
    expect(distanceHandle, findsOneWidget);

    // Drag Distance handle onto Baking tile center (robust across row shifts).
    final handleCenter = tester.getCenter(distanceHandle);
    final bakingCenter = tester.getCenter(bakingTile);
    final delta = bakingCenter - handleCenter;

    await tester.dragFrom(handleCenter, delta);
    await tester.pump(const Duration(milliseconds: 400));

    // Commit reorder.
    await tester.tap(find.byKey(const Key('dashboard_edit_done')));
    await tester.pump(const Duration(milliseconds: 400));

    final afterBaking = tester.getTopLeft(bakingTile);
    final afterDistance = tester.getTopLeft(distanceTile);

    // Swapped: Distance now appears before Baking (reading order).
    expect(comesBefore(afterDistance, afterBaking), isTrue);

    // Tablet (3 columns): rebuild with the same persisted preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));

    await pumpDashboard(const Size(900, 844));

    final tabletBaking = tester.getTopLeft(bakingTile);
    final tabletDistance = tester.getTopLeft(distanceTile);

    // Persisted: Distance remains before Baking in the tablet grid.
    expect(comesBefore(tabletDistance, tabletBaking), isTrue);
  });
}
