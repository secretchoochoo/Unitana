import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app.dart';
import 'package:unitana/models/place.dart';

import 'goldens_test_utils.dart';

void main() {
  final shouldRunGoldens = goldensEnabled();

  Map<String, Object> seedPrefs() {
    final home = Place(
      id: 'living-denver',
      type: PlaceType.living,
      name: 'Home',
      cityName: 'Denver',
      countryCode: 'US',
      timeZoneId: 'America/Denver',
      unitSystem: 'imperial',
      use24h: false,
    );

    final dest = Place(
      id: 'visiting-porto',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: 'Porto',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    );

    return <String, Object>{
      'places_v1': jsonEncode([home.toJson(), dest.toJson()]),
      'default_place_id_v1': home.id,
      'profile_name_v1': 'Porto',
    };
  }

  group('Dashboard screen (phone) goldens', () {
    testWidgets('expanded at top', (tester) async {
      if (!shouldRunGoldens) {
        return;
      }

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      SharedPreferences.setMockInitialValues(seedPrefs());

      await tester.pumpWidget(const UnitanaApp());
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Give the initial refresh pass some breathing room to stabilize.
      await tester.pump(const Duration(milliseconds: 600));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dashboard_phone_expanded.png'),
      );
    });

    testWidgets('collapsed header', (tester) async {
      if (!shouldRunGoldens) {
        return;
      }

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      SharedPreferences.setMockInitialValues(seedPrefs());

      await tester.pumpWidget(const UnitanaApp());
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 600));

      final scrollable = find.byType(Scrollable).first;

      // Scroll enough to ensure the sliver header collapses.
      await tester.drag(scrollable, const Offset(0, -700));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dashboard_phone_collapsed.png'),
      );
    });
  });
}
