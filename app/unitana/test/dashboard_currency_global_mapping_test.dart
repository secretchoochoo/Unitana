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

  UnitanaAppState buildState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);
    state.places = const [
      Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Tokyo',
        countryCode: 'JP',
        timeZoneId: 'Asia/Tokyo',
        unitSystem: 'metric',
        use24h: true,
      ),
      Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
      ),
    ];
    state.defaultPlaceId = 'home';
    return state;
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: buildState()),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> openCurrencyTool(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'currency',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_currency_convert')),
    );
    await tester.pumpAndSettle();
  }

  Future<List<String>> readCurrencyCodes(WidgetTester tester) async {
    String readCode(String key) {
      final button = find.byKey(ValueKey(key));
      expect(button, findsOneWidget);
      final codeText = find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              RegExp(r'^[A-Z]{3}$').hasMatch((w.data ?? '').trim()),
        ),
      );
      expect(codeText, findsOneWidget);
      return (tester.widget<Text>(codeText).data ?? '').trim();
    }

    return [
      readCode('tool_unit_from_currency_convert'),
      readCode('tool_unit_to_currency_convert'),
    ];
  }

  Future<void> closeToolModal(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  }

  testWidgets('Currency tool uses global country->currency mapping', (
    tester,
  ) async {
    await pumpDashboard(tester);

    // Home selected by default: Tokyo (JPY) -> Denver (USD)
    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pumpAndSettle();
    await openCurrencyTool(tester);
    expect(await readCurrencyCodes(tester), equals(const ['JPY', 'USD']));
    await closeToolModal(tester);

    // Destination selected: Denver (USD) -> Tokyo (JPY)
    await tester.tap(
      find.byKey(const ValueKey('places_hero_segment_destination')),
    );
    await tester.pumpAndSettle();
    await openCurrencyTool(tester);
    expect(await readCurrencyCodes(tester), equals(const ['USD', 'JPY']));
  });

  testWidgets('Currency tool converts JPY<->USD with non-placeholder rate', (
    tester,
  ) async {
    await pumpDashboard(tester);

    // Home selected by default: Tokyo (JPY) -> Denver (USD)
    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pumpAndSettle();
    await openCurrencyTool(tester);

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_currency_convert')),
      '10',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_currency_convert')));
    await tester.pumpAndSettle();

    final resultRoot = find.byKey(
      const ValueKey('tool_result_currency_convert'),
    );
    expect(resultRoot, findsOneWidget);
    final resultRich = find.descendant(
      of: resultRoot,
      matching: find.byType(RichText),
    );
    expect(resultRich, findsAtLeastNWidgets(1));
    final result = tester.widget<RichText>(resultRich.first).text.toPlainText();
    expect(result, contains('→'));
    expect(result, isNot(contains('¥10.00  →  \$10.00')));
  });

  testWidgets('Currency tool seeds scaled default input for tiny-unit pairs', (
    tester,
  ) async {
    await pumpDashboard(tester);

    // Home selected by default: Tokyo (JPY) -> Denver (USD)
    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pumpAndSettle();
    await openCurrencyTool(tester);

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('tool_input_currency_convert')),
    );
    expect(input.controller?.text, '100');
  });

  testWidgets('Hero currency line scales base amount for tiny per-unit pairs', (
    tester,
  ) async {
    await pumpDashboard(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Home selected by default: Tokyo (JPY) -> Denver (USD).
    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pumpAndSettle();

    final text =
        tester
            .widget<Text>(
              find.byKey(const ValueKey('hero_currency_primary_line')),
            )
            .data ??
        '';
    expect(text, contains('≈'));
    expect(text, contains('¥100'));
  });
}
