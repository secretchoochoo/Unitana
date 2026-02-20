import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_test_helpers.dart';

/// P0 regression guard: edit-mode reordering starts from long-press on the tile.
///
/// This test verifies:
/// - In edit mode, tapping the tile body does not open tool sheets.
/// - Long-press dragging the tile body persists default tile anchors.

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
  await _pumpFor(tester, const Duration(milliseconds: 220));
  await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
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
  testWidgets('dashboard edit mode reorders from long-press tile drag', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    final bakingTile = find.byKey(const ValueKey('dashboard_item_baking'));
    final distanceTile = find.byKey(const ValueKey('dashboard_item_distance'));

    expect(bakingTile, findsOneWidget);
    expect(distanceTile, findsOneWidget);

    await _enterEditMode(tester);

    // Sanity: tile body is not tappable in edit mode (no tool sheets).
    await tester.tap(bakingTile, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('tool_close_baking')), findsNothing);

    // Long-press drag on the tile body should persist anchor overrides.
    final start = tester.getCenter(bakingTile);
    final target = tester.getCenter(distanceTile);
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
    await gesture.moveTo(target);
    await gesture.up();
    await _pumpFor(tester, const Duration(milliseconds: 360));

    await tester.tap(
      find.byKey(const Key('dashboard_edit_done')),
      warnIfMissed: false,
    );
    await _pumpFor(tester, const Duration(milliseconds: 300));

    final anchorsAfterHandleDrag = await _readDefaultAnchors();
    expect(
      anchorsAfterHandleDrag.containsKey('baking') ||
          anchorsAfterHandleDrag.containsKey('distance'),
      isTrue,
    );
  });
}
