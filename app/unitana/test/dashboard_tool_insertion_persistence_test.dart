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

import 'dashboard_test_helpers.dart';

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
    expect(find.text('Baking'), findsOneWidget);

    // Tap the first visible + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Pick a non-default tool from the picker (Area).
    final homeLens = find.byKey(const ValueKey('toolpicker_lens_home_diy'));
    expect(homeLens, findsOneWidget);

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
    await tester.scrollUntilVisible(homeLens, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    // The lens header itself is tappable.
    await tester.tap(homeLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final areaTool = find.byKey(const ValueKey('toolpicker_tool_area'));
    await tester.scrollUntilVisible(areaTool, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(areaTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Area is not a default tile, so it should appear once.
    expect(find.text('Area'), findsOneWidget);

    // Attempt to add Area again; it should be blocked.
    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(homeLens, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(homeLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(areaTool, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(areaTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('toast_duplicate_tool_area')),
      findsOneWidget,
    );
    expect(find.text('Area'), findsOneWidget);

    // Rebuild the screen to prove persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDashboard(tester, state);

    expect(find.text('Area'), findsOneWidget);
  });

  testWidgets('long-press remove deletes a user-added tile and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();

    await pumpDashboard(tester, state);

    // Add an Area tile via a "+" slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final homeLens = find.byKey(const ValueKey('toolpicker_lens_home_diy'));
    expect(homeLens, findsOneWidget);

    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(homeLens, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(homeLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final areaTool = find.byKey(const ValueKey('toolpicker_tool_area'));
    await tester.scrollUntilVisible(areaTool, 200, scrollable: sheetScrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(areaTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Area'), findsOneWidget);

    // The ToolPicker flow opens the Distance modal; close it so the dashboard
    // tile is actually hit-testable for long-press actions.
    final closeArea = find.byKey(const ValueKey('tool_close_area'));
    if (closeArea.evaluate().isNotEmpty) {
      await tester.tap(closeArea);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
    }

    // Pull the persisted layout so we can target the user-added tile by key.
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString('dashboard_layout_v1::profile_1') ??
        prefs.getString('dashboard_layout_v1');
    expect(raw, isNotNull);

    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, isNotEmpty);

    // Target the user-added Area tool specifically (avoid relying on list ordering).
    Map<String, dynamic>? areaEntry;
    for (final e in decoded) {
      if (e is Map<String, dynamic> && e['toolId'] == 'area') {
        areaEntry = e;
        // Prefer user-added entries when present.
        if (e['userAdded'] == true) break;
      }
    }
    expect(areaEntry, isNotNull);
    final id = areaEntry!['id'] as String;

    // Long-press to open actions, then remove.
    final tile = find.byKey(ValueKey('dashboard_item_$id'));
    expect(tile, findsOneWidget);

    await ensureVisibleAligned(tester, tile);
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
      await ensureVisibleAligned(tester, tile);
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
          'Expected tile actions to appear after long-pressing Area tile, but no remove action key was found.',
        );
      }
    }
    await pumpFor(const Duration(milliseconds: 250));

    // Confirm removal.
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await pumpFor(const Duration(milliseconds: 250));

    // Area tile is removed.
    expect(find.text('Area'), findsNothing);

    // Commit edit mode so the removal persists.
    final done = find.byKey(const ValueKey('dashboard_edit_done'));
    expect(done, findsOneWidget);
    await tester.tap(done);
    await pumpFor(const Duration(milliseconds: 250));

    // Rebuild and validate persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDashboard(tester, state);

    expect(find.text('Area'), findsNothing);
  });

  testWidgets('default tiles can be removed and later restored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Baking is a default tile.
    expect(find.text('Baking'), findsOneWidget);

    // Enter edit mode by long-pressing the Baking tile.
    final bakingTile = find.text('Baking').first;
    await ensureVisibleAligned(tester, bakingTile);
    await tester.longPress(bakingTile, warnIfMissed: false);
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

    // Prove persistence: rebuild and expect Baking is gone.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDashboard(tester, state);

    expect(find.text('Baking'), findsNothing);

    // Ensure the hidden defaults list persisted the removed tool.
    final prefs = await SharedPreferences.getInstance();
    final hiddenRaw =
        prefs.getString('dashboard_hidden_defaults_v1::profile_1') ??
        prefs.getString('dashboard_hidden_defaults_v1');
    expect(hiddenRaw, isNotNull);
    expect(hiddenRaw, contains('baking'));

    // Restore Baking via the picker search.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);
    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final search = find.byKey(const ValueKey('toolpicker_search'));
    expect(search, findsOneWidget);
    await tester.enterText(search, 'Baking');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final bakingTool = find.byKey(
      const ValueKey('toolpicker_search_tool_baking'),
    );
    expect(bakingTool, findsOneWidget);
    await tester.tap(bakingTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Baking'), findsOneWidget);
  });
}
