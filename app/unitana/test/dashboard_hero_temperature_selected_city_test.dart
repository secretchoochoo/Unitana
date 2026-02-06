import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  int tempValue(String text) {
    final m = RegExp(r'-?\d+').firstMatch(text);
    if (m == null) {
      throw StateError('No numeric temperature found in "$text"');
    }
    return int.parse(m.group(0)!);
  }

  testWidgets('Hero temp follows selected city and shows alt-unit conversion', (
    tester,
  ) async {
    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    Future<(String, String)> readTemps() async {
      final primary = tester.widget<Text>(
        find.byKey(const ValueKey('hero_primary_temp')),
      );
      final secondary = tester.widget<Text>(
        find.byKey(const ValueKey('hero_secondary_temp')),
      );
      return ((primary.data ?? ''), (secondary.data ?? ''));
    }

    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await pumpStable(tester);

    final homeTemps = await readTemps();
    final homePrimary = homeTemps.$1;
    final homeSecondary = homeTemps.$2;
    expect(homePrimary, contains('°F'));
    expect(homeSecondary, contains('°C'));
    final homeF = tempValue(homePrimary);
    final homeC = tempValue(homeSecondary);
    expect(((homeF - 32) * 5 / 9).round(), equals(homeC));

    await tester.tap(
      find.byKey(const ValueKey('places_hero_segment_destination')),
    );
    await pumpStable(tester);

    final destTemps = await readTemps();
    final destPrimary = destTemps.$1;
    final destSecondary = destTemps.$2;
    expect(destPrimary, contains('°C'));
    expect(destSecondary, contains('°F'));
    final destC = tempValue(destPrimary);
    final destF = tempValue(destSecondary);
    expect((destC * 9 / 5 + 32).round(), equals(destF));

    expect(destPrimary, isNot(equals(homePrimary)));
  });
}
