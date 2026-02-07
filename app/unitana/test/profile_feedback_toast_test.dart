import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _pumpFor(
  WidgetTester tester, {
  int ticks = 4,
  Duration step = const Duration(milliseconds: 120),
}) async {
  for (var i = 0; i < ticks; i += 1) {
    await tester.pump(step);
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 12,
  Duration step = const Duration(milliseconds: 120),
}) async {
  for (var i = 0; i < maxTicks; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _openProfilesBoard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dashboard_menu_button')));
  await _pumpFor(tester);
  final profilesTile = find.widgetWithText(ListTile, 'Profiles');
  await ensureVisibleAligned(tester, profilesTile);
  await tester.tap(profilesTile);
  await _pumpFor(tester);
}

Future<void> _pickCity(
  WidgetTester tester, {
  required Key buttonKey,
  required String query,
  required String city,
}) async {
  await tester.tap(find.byKey(buttonKey));
  await _pumpFor(tester);
  final searchField = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == 'Search city, country, code, timezone',
  );
  expect(searchField, findsOneWidget);
  await tester.enterText(searchField, query);
  await _pumpFor(tester);
  final cityText = find.textContaining(city);
  expect(cityText, findsWidgets);
  final cityTile = find.ancestor(
    of: cityText.first,
    matching: find.byType(ListTile),
  );
  expect(cityTile, findsWidgets);
  await tester.tap(cityTile.first);
  await _pumpFor(tester);
}

void main() {
  testWidgets('Edit profile save emits Profile updated toast', (tester) async {
    await pumpDashboardForTest(tester);
    await _openProfilesBoard(tester);

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 250));

    final editFinder = find.byKey(
      const ValueKey('profiles_board_edit_profile_1'),
    );
    final editButton = tester.widget<IconButton>(editFinder);
    editButton.onPressed?.call();
    await _pumpUntil(tester, find.byKey(const Key('first_run_step_welcome')));

    await tester.tap(find.byKey(const Key('first_run_nav_next')));
    await _pumpFor(tester);
    await tester.tap(find.byKey(const Key('first_run_nav_next')));
    await _pumpFor(tester);
    await tester.tap(find.byKey(const Key('first_run_finish_button')));
    await _pumpFor(tester, ticks: 6);

    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('Add profile save emits Profile created toast', (tester) async {
    await pumpDashboardForTest(tester);
    await _openProfilesBoard(tester);

    await tester.tap(find.byKey(const Key('profiles_board_add_profile')));
    await _pumpUntil(tester, find.byKey(const Key('first_run_step_welcome')));

    await tester.tap(find.byKey(const Key('first_run_nav_next')));
    await _pumpFor(tester);

    await _pickCity(
      tester,
      buttonKey: const Key('first_run_home_city_button'),
      query: 'denver',
      city: 'Denver',
    );
    await _pickCity(
      tester,
      buttonKey: const Key('first_run_dest_city_button'),
      query: 'porto',
      city: 'Porto',
    );

    await tester.tap(find.byKey(const Key('first_run_nav_next')));
    await _pumpFor(tester);
    await tester.tap(find.byKey(const Key('first_run_finish_button')));
    await _pumpFor(tester, ticks: 6);

    expect(find.text('Profile created'), findsOneWidget);
  });
}
