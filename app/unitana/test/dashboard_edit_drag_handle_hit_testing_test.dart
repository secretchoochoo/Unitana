import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_test_helpers.dart';

/// P0 regression guard: edit-mode reordering must only start from the drag handle.
///
/// This test verifies:
/// - In edit mode, tapping the tile body does not open tool sheets.
/// - Dragging the tile body does not persist default tile anchors.
/// - Dragging from the drag handle does persist default tile anchors.

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _enterEditMode(WidgetTester tester) async {
  // If we're already editing, no-op.
  if (find.byKey(const Key('dashboard_edit_done')).evaluate().isNotEmpty) {
    return;
  }

  await tester.tap(find.byKey(const Key('dashboard_menu_button')));
  await tester.pumpAndSettle(const Duration(milliseconds: 250));

  await tester.tap(find.text('Edit Widgets'));
  await _pumpFor(tester, const Duration(milliseconds: 260));

  expect(find.byKey(const Key('dashboard_edit_done')), findsOneWidget);
}

Future<Map<String, dynamic>> _readDefaultAnchors() async {
  final prefs = await SharedPreferences.getInstance();
  final raw =
      prefs.getString('dashboard_default_tool_anchors_v1::profile_1') ??
      prefs.getString('dashboard_default_tool_anchors_v1');
  if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};

  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

void main() {
  testWidgets('dashboard edit mode only reorders from drag handle', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    final areaTile = find.byKey(const ValueKey('dashboard_item_area'));
    final liquidsTile = find.byKey(const ValueKey('dashboard_item_liquids'));

    expect(areaTile, findsOneWidget);
    expect(liquidsTile, findsOneWidget);

    await _enterEditMode(tester);

    // Sanity: tile body is not tappable in edit mode (no tool sheets).
    await tester.tap(areaTile, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('tool_close_area')), findsNothing);

    // Dragging the tile body should not persist anchor overrides.
    final areaRect = tester.getRect(areaTile);
    await tester.dragFrom(areaRect.center, const Offset(0, -140));
    await _pumpFor(tester, const Duration(milliseconds: 250));

    await tester.tap(
      find.byKey(const Key('dashboard_edit_done')),
      warnIfMissed: false,
    );
    await _pumpFor(tester, const Duration(milliseconds: 280));

    final anchorsAfterBodyDrag = await _readDefaultAnchors();
    expect(anchorsAfterBodyDrag.containsKey('area'), isFalse);
    expect(anchorsAfterBodyDrag.containsKey('liquids'), isFalse);

    // Now perform an actual reorder by dragging from the drag handle.
    await _enterEditMode(tester);

    final areaTile2 = find.byKey(const ValueKey('dashboard_item_area'));
    final liquidsTile2 = find.byKey(const ValueKey('dashboard_item_liquids'));

    final areaStack = find
        .ancestor(of: areaTile2, matching: find.byType(Stack))
        .first;
    final handleIcon = find.descendant(
      of: areaStack,
      matching: find.byIcon(Icons.drag_indicator_rounded),
    );
    expect(handleIcon, findsOneWidget);

    final start = tester.getCenter(handleIcon);
    final target = tester.getCenter(liquidsTile2);
    await tester.dragFrom(start, target - start);
    await _pumpFor(tester, const Duration(milliseconds: 360));

    await tester.tap(
      find.byKey(const Key('dashboard_edit_done')),
      warnIfMissed: false,
    );
    await _pumpFor(tester, const Duration(milliseconds: 300));

    final anchorsAfterHandleDrag = await _readDefaultAnchors();
    expect(
      anchorsAfterHandleDrag.containsKey('area') ||
          anchorsAfterHandleDrag.containsKey('liquids'),
      isTrue,
    );
  });
}
