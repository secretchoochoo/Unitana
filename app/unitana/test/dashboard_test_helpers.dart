import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

/// Shared helpers for dashboard widget tests.
///
/// Keep these helpers minimal and deterministic. Tests should not depend on
/// ToolPicker ordering or locale-sensitive labels.
UnitanaAppState buildSeededDashboardState() {
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
      cityName: 'Porto',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    ),
  ];
  state.defaultPlaceId = 'home';

  return state;
}

/// Canonical deterministic theme for widget tests.
///
/// Keep this aligned with the app's default dark theme so golden tests are
/// meaningful and non-golden tests catch layout regressions.
ThemeData buildTestTheme() => UnitanaTheme.dark();

Future<void> pumpDashboardForTest(
  WidgetTester tester, {
  UnitanaAppState? state,
  Size surfaceSize = const Size(390, 844),
}) async {
  // Ensure deterministic storage.
  SharedPreferences.setMockInitialValues({});

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  final seeded = state ?? buildSeededDashboardState();

  await tester.pumpWidget(
    MaterialApp(
      theme: UnitanaTheme.dark(),
      home: DashboardScreen(state: seeded),
    ),
  );

  // The dashboard can include continuous animations (eg, edit-mode jiggle),
  // so avoid pumpAndSettle here. A short fixed pump is enough for the initial
  // frame + any immediate microtasks.
  await tester.pump(const Duration(milliseconds: 300));
}

/// Back-compat alias used by older dashboard overlay tests.
///
/// Prefer [pumpDashboardForTest] going forward.
Future<void> pumpDashboardHarness(
  WidgetTester tester, {
  UnitanaAppState? state,
  Size surfaceSize = const Size(390, 844),
}) {
  return pumpDashboardForTest(tester, state: state, surfaceSize: surfaceSize);
}

/// Ensures a widget is scrolled fully into view, accounting for pinned headers.
///
/// Use a high [alignment] (near 1.0) so the target lands away from the top edge,
/// which can be occluded by pinned slivers.
Future<void> ensureVisibleAligned(
  WidgetTester tester,
  Finder finder, {
  double alignment = 0.85,
}) async {
  final elements = finder.evaluate().toList();
  if (elements.isEmpty) {
    // Nothing to scroll to. Let the caller's expectations fail normally.
    return;
  }
  // Some finders can legally match multiple widgets (eg, repeated tiles). For
  // scroll alignment we only need a single representative element.
  final element = elements.first;
  await Scrollable.ensureVisible(
    element,
    alignment: alignment,
    duration: Duration.zero,
  );
  // Do not pumpAndSettle: pinned headers and other dashboard animations can
  // run continuously in tests.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
