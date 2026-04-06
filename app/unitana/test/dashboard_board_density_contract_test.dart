import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_test_helpers.dart';

Finder _addSlotFinder() {
  return find.byWidgetPredicate((w) {
    final key = w.key;
    if (key is! ValueKey) return false;
    final value = key.value.toString();
    return value.startsWith('dashboard_add_slot_');
  });
}

void main() {
  Map<String, Object> crowdedDashboardPrefs() {
    final layout = jsonEncode([
      {
        'id': 'user_liquids',
        'kind': 'tool',
        'toolId': 'liquids',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
      {
        'id': 'user_area',
        'kind': 'tool',
        'toolId': 'area',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
      {
        'id': 'user_volume',
        'kind': 'tool',
        'toolId': 'volume',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
      {
        'id': 'user_pressure',
        'kind': 'tool',
        'toolId': 'pressure',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
      {
        'id': 'user_speed',
        'kind': 'tool',
        'toolId': 'speed',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
      {
        'id': 'user_weight',
        'kind': 'tool',
        'toolId': 'weight',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': null,
        'userAdded': true,
      },
    ]);
    return <String, Object>{
      'dashboard_layout_v1': layout,
      'dashboard_layout_v1::profile_1': layout,
    };
  }

  testWidgets('Dashboard browsing mode uses a single add-widget affordance', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 844));

    expect(_addSlotFinder(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard_add_slot_inline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
      findsNothing,
    );
  });

  testWidgets('Dashboard edit mode still exposes multiple open slots', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 844));

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await pumpUntilFound(tester, find.byKey(const Key('dashboard_edit_mode')));
    await ensureVisibleAligned(
      tester,
      find.byKey(const Key('dashboard_edit_mode')),
    );
    await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_addSlotFinder(), findsWidgets);
    expect(find.byKey(const Key('dashboard_edit_done')), findsOneWidget);
  });

  testWidgets('Crowded dashboard can expand and collapse overflow rows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(crowdedDashboardPrefs());

    await pumpDashboardForTest(
      tester,
      surfaceSize: const Size(390, 844),
      resetStorage: false,
    );

    expect(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
      findsOneWidget,
    );
    await ensureVisibleAligned(
      tester,
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
    );
    expect(find.text('Show all widgets'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard_item_user_speed')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Show fewer widgets'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard_item_user_speed')),
      findsOneWidget,
    );

    await ensureVisibleAligned(
      tester,
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
    );
    await tester.tap(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Show all widgets'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard_item_user_speed')),
      findsNothing,
    );
  });

  testWidgets('Edit mode ignores browsing overflow collapse', (tester) async {
    SharedPreferences.setMockInitialValues(crowdedDashboardPrefs());

    await pumpDashboardForTest(
      tester,
      surfaceSize: const Size(390, 844),
      resetStorage: false,
    );

    expect(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard_item_user_speed')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await pumpUntilFound(tester, find.byKey(const Key('dashboard_edit_mode')));
    await ensureVisibleAligned(
      tester,
      find.byKey(const Key('dashboard_edit_mode')),
    );
    await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('dashboard_board_overflow_toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard_item_user_speed')),
      findsOneWidget,
    );
  });
}
