// Dashboard persistence contract test (keys/ids must remain stable).
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

    // Let the initial async loads settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  Finder firstAddSlotFinder() {
    return find.byWidgetPredicate((w) {
      final key = w.key;
      if (key is! ValueKey) return false;
      final v = key.value.toString();
      return v.startsWith('dashboard_add_slot_');
    });
  }

  testWidgets('tapping + inserts a tool tile and persists it', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();

    await pumpDashboard(tester, state);

    // Defaults are present.
    expect(find.text('Area'), findsOneWidget);

    // Tap the first visible + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Pick a non-default tool from the picker.
    // ToolPickerSheet is two-level (lenses -> tools). Expand Travel Essentials,
    // then select Distance.
    final travelLens = find.byKey(
      const ValueKey('toolpicker_lens_travel_essentials'),
    );
    expect(travelLens, findsOneWidget);

    // ToolPickerSheet is presented in a modal bottom sheet. There are multiple
    // scrollables in the app (dashboard grid, bottom sheet list, etc.), so we
    // must scope scrollUntilVisible() to the bottom sheet's scrollable to avoid
    // "Too many elements" errors.
    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;

    // Ensure the lens header is on-screen before tapping.
    await tester.scrollUntilVisible(
      travelLens,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    // The lens header itself is tappable.
    await tester.tap(travelLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final distanceTool = find.byKey(const ValueKey('toolpicker_tool_distance'));
    await tester.scrollUntilVisible(
      distanceTool,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(distanceTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Distance is not a default tile, so it should appear once.
    expect(find.text('Distance'), findsOneWidget);

    // Attempt to add Distance again; it should be blocked.
    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(
      travelLens,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(travelLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(
      distanceTool,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(distanceTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('toast_duplicate_tool_distance')),
      findsOneWidget,
    );
    expect(find.text('Distance'), findsOneWidget);

    // Rebuild the screen to prove persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDashboard(tester, state);

    expect(find.text('Distance'), findsOneWidget);
  });

  testWidgets('long-press remove deletes a user-added tile and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();

    await pumpDashboard(tester, state);

    // Add a Distance tile via a "+" slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final travelLens = find.byKey(
      const ValueKey('toolpicker_lens_travel_essentials'),
    );
    expect(travelLens, findsOneWidget);

    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      travelLens,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(travelLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final distanceTool = find.byKey(const ValueKey('toolpicker_tool_distance'));
    await tester.scrollUntilVisible(
      distanceTool,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(distanceTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Distance'), findsOneWidget);

    // The ToolPicker flow opens the Distance modal; close it so the dashboard
    // tile is actually hit-testable for long-press actions.
    final closeDistance = find.byKey(const ValueKey('tool_close_distance'));
    if (closeDistance.evaluate().isNotEmpty) {
      await tester.tap(closeDistance);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
    }

    // Pull the persisted layout so we can target the user-added tile by key.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dashboard_layout_v1');
    expect(raw, isNotNull);

    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, isNotEmpty);

    // Target the user-added Distance tool specifically (avoid relying on list ordering).
    Map<String, dynamic>? distanceEntry;
    for (final e in decoded) {
      if (e is Map<String, dynamic> && e['toolId'] == 'distance') {
        distanceEntry = e;
        // Prefer user-added entries when present.
        if (e['userAdded'] == true) break;
      }
    }
    expect(distanceEntry, isNotNull);
    final id = distanceEntry!['id'] as String;

    // Long-press to open actions, then remove.
    final tile = find.byKey(ValueKey('dashboard_item_$id'));
    expect(tile, findsOneWidget);

    await tester.ensureVisible(tile);
    await tester.pump(const Duration(milliseconds: 250));

    // NOTE: While in edit mode the dashboard tiles run a continuous jiggle
    // animation (home-screen style). That means pumpAndSettle() will never
    // converge once edit mode is active. Use bounded pumps instead.
    Future<void> pumpFor(Duration duration) async {
      final deadline = DateTime.now().add(duration);
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> pumpUntil(
      bool Function() predicate, {
      Duration step = const Duration(milliseconds: 50),
      Duration timeout = const Duration(seconds: 2),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        if (predicate()) return;
        await tester.pump(step);
      }
    }

    Future<void> openActionsSheet() async {
      // We intentionally do not require the tile to be hit-testable, because it
      // can be partially occluded by pinned overlays at small viewport sizes.
      // Instead, press inside the tile bounds (lower-middle) which is reliably
      // tappable across layouts.
      final rect = tester.getRect(tile);
      final pressPoint = Offset(
        rect.center.dx,
        rect.top + (rect.height * 0.72),
      );
      await tester.longPressAt(pressPoint);
      await pumpFor(const Duration(milliseconds: 220));
    }

    // Open actions sheet (retry once, because entering edit mode triggers a
    // rebuild that can occasionally swallow the first post-gesture frame).
    await openActionsSheet();

    final removeKey = ValueKey('dashboard_tile_action_remove_$id');
    Finder removeByKey = find.byKey(removeKey);

    await pumpUntil(() => removeByKey.evaluate().isNotEmpty);
    if (removeByKey.evaluate().isEmpty) {
      await openActionsSheet();
      removeByKey = find.byKey(removeKey);
      await pumpUntil(() => removeByKey.evaluate().isNotEmpty);
    }

    if (removeByKey.evaluate().isNotEmpty) {
      await tester.tap(removeByKey.first, warnIfMissed: false);
    } else {
      // Fallback: match any remove action key (id mismatch edge case).
      final anyRemoveByKey = find.byWidgetPredicate((w) {
        final k = w.key;
        if (k is ValueKey) {
          final v = k.value.toString();
          return v.startsWith('dashboard_tile_action_remove_');
        }
        return false;
      });
      if (anyRemoveByKey.evaluate().isNotEmpty) {
        await tester.tap(anyRemoveByKey.first, warnIfMissed: false);
      } else {
        fail(
          'Expected tile actions to appear after long-pressing Distance tile, but no remove action key was found.',
        );
      }
    }
    await pumpFor(const Duration(milliseconds: 250));

    // Confirm removal.
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await pumpFor(const Duration(milliseconds: 250));

    // Distance tile is removed.
    expect(find.text('Distance'), findsNothing);

    // Commit edit mode so the removal persists.
    final done = find.byKey(const ValueKey('dashboard_edit_done'));
    expect(done, findsOneWidget);
    await tester.tap(done);
    await pumpFor(const Duration(milliseconds: 250));

    // Rebuild and validate persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDashboard(tester, state);

    expect(find.text('Distance'), findsNothing);
  });

  testWidgets('default tiles can be removed and later restored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Area is a default tile.
    expect(find.text('Area'), findsOneWidget);

    // Enter edit mode by long-pressing the Area tile.
    await tester.longPress(find.text('Area').first, warnIfMissed: false);
    Future<void> pumpFor(Duration duration) async {
      final deadline = DateTime.now().add(duration);
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await pumpFor(const Duration(milliseconds: 250));

    // Remove the tile.
    expect(find.text('Remove tile'), findsOneWidget);
    await tester.tap(find.text('Remove tile'));
    await pumpFor(const Duration(milliseconds: 250));

    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await pumpFor(const Duration(milliseconds: 250));

    // Commit edit mode so the hidden-default state persists.
    final done = find.byKey(const ValueKey('dashboard_edit_done'));
    expect(done, findsOneWidget);
    await tester.tap(done, warnIfMissed: false);
    await pumpFor(const Duration(milliseconds: 250));

    // Prove persistence: rebuild and expect Area is gone.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDashboard(tester, state);

    expect(find.text('Area'), findsNothing);

    // Ensure the hidden defaults list persisted the removed tool.
    final prefs = await SharedPreferences.getInstance();
    final hiddenRaw = prefs.getString('dashboard_hidden_defaults_v1');
    expect(hiddenRaw, isNotNull);
    expect(hiddenRaw, contains('area'));

    // Restore Area via the picker search.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);
    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final search = find.byKey(const ValueKey('toolpicker_search'));
    expect(search, findsOneWidget);
    await tester.enterText(search, 'Area');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final areaTool = find.byKey(const ValueKey('toolpicker_search_tool_area'));
    expect(areaTool, findsOneWidget);
    await tester.tap(areaTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Area'), findsOneWidget);
  });
}
