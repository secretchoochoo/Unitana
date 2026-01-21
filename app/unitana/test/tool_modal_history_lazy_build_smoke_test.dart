import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/tool_modal_bottom_sheet.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Prevent runtime font fetching in widget tests.
  GoogleFonts.config.allowRuntimeFetching = false;

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

    // The dashboard has live elements; avoid full pumpAndSettle timeouts.
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  String resolveToolIdFromModal(WidgetTester tester, Finder modalRoot) {
    final inputFinder = find.descendant(
      of: modalRoot,
      matching: find.byWidgetPredicate((w) {
        if (w is! TextField) return false;
        final key = w.key;
        return key is ValueKey<String> && key.value.startsWith('tool_input_');
      }),
    );
    expect(inputFinder, findsOneWidget);

    final input = tester.widget<TextField>(inputFinder);
    final key = input.key as ValueKey<String>;
    return key.value.substring('tool_input_'.length);
  }

  testWidgets('Tool modal history is lazy-built and scroll-safe', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    // Constrain height enough to force the history container to scroll, but keep
    // the scrollable hit-test region fully within the test surface.
    // Extremely short surfaces can place the list's center just below the root
    // bounds, causing drag() to miss hit testing.
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final errors = <FlutterErrorDetails>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      prevOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = prevOnError;
    });

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Use search to avoid lens ordering assumptions.
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Area');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final areaSearchRow = find.byKey(
      const ValueKey('toolpicker_search_tool_area'),
    );
    expect(areaSearchRow, findsOneWidget);

    await tester.tap(areaSearchRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final modal = find.byType(ToolModalBottomSheet);
    expect(modal, findsOneWidget);

    final toolId = resolveToolIdFromModal(tester, modal);
    final inputKey = ValueKey('tool_input_$toolId');
    final runKey = ValueKey('tool_run_$toolId');

    // Create 10 history entries (history cap). Values are intentionally small.
    for (var i = 0; i < 10; i++) {
      await tester.enterText(find.byKey(inputKey), '${10 + i}');
      await tester.tap(find.byKey(runKey));
      await tester.pumpAndSettle(const Duration(milliseconds: 220));
    }

    final history0 = find.byKey(ValueKey('tool_history_${toolId}_0'));
    expect(history0, findsOneWidget);

    final history9 = find.byKey(ValueKey('tool_history_${toolId}_9'));

    // The tool history list is keyed for stable scroll targeting.
    final historyList = find.byKey(ValueKey('tool_history_list_$toolId'));
    expect(historyList, findsOneWidget);

    // Ensure the history list is on-screen before attempting to scroll it.
    await tester.ensureVisible(historyList);
    await tester.pump(const Duration(milliseconds: 60));

    final historyScrollable = find.descendant(
      of: historyList,
      matching: find.byType(Scrollable),
    );
    expect(historyScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      history9,
      120,
      scrollable: historyScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    expect(history9, findsOneWidget);

    // No overflows / nested-scroll exceptions.
    expect(tester.takeException(), isNull);

    // Filter out benign frame scheduling; only fail on real Flutter errors.
    final significant = errors
        .where((e) {
          final msg = e.exceptionAsString();
          return msg.contains('RenderFlex overflowed') ||
              msg.contains('A RenderFlex overflowed') ||
              msg.contains('Vertical viewport was given unbounded height') ||
              msg.contains('ScrollController not attached') ||
              msg.contains('Multiple ScrollController') ||
              msg.contains('NestedScrollView');
        })
        .toList(growable: false);

    expect(significant, isEmpty);
  });
}
