import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 160));
  }

  String tileLineForPrefix(WidgetTester tester, Finder tile, String prefix) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: tile, matching: find.byType(Text)),
    );
    for (final t in texts) {
      final data = t.data;
      if (data != null && data.startsWith(prefix)) {
        return data;
      }
    }
    return '';
  }

  testWidgets(
    'World Time Map widget uses compact delta readout and follows reality toggle',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'dashboard_layout_v1': jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'id': 'world_time_map_test',
            'kind': 'tool',
            'toolId': 'world_clock_delta',
            'colSpan': 1,
            'rowSpan': 1,
            'anchorIndex': null,
            'userAdded': true,
          },
        ]),
      });

      final storage = UnitanaStorage();
      await storage.savePlaces(const <Place>[
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
      ]);
      await storage.saveDefaultPlaceId('home');
      await storage.saveProfileName('XL-E');

      final state = UnitanaAppState(storage);
      await state.load();

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(state: state)));
      await pumpStable(tester);

      final tile = find.byKey(
        const ValueKey('dashboard_item_world_time_map_test'),
      );
      expect(tile, findsOneWidget);

      final deltaBefore = tileLineForPrefix(tester, tile, 'Δ ');
      expect(deltaBefore, isNotEmpty);
      expect(deltaBefore.endsWith('h'), isTrue);

      final summaryBefore = tileLineForPrefix(tester, tile, 'Porto');
      expect(summaryBefore, contains('UTC'));
      expect(summaryBefore, contains('Denver'));

      await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
      await pumpStable(tester);

      final deltaAfter = tileLineForPrefix(tester, tile, 'Δ ');
      expect(deltaAfter, isNotEmpty);
      expect(deltaAfter.endsWith('h'), isTrue);
      expect(deltaAfter, isNot(equals(deltaBefore)));

      final summaryAfter = tileLineForPrefix(tester, tile, 'Denver');
      expect(summaryAfter, contains('UTC'));
      expect(summaryAfter, contains('Porto'));
    },
  );
}
