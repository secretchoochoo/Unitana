import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching in widget/golden tests so GoogleFonts can resolve
  // required font files during tests (avoids bundling font assets in-repo).
  GoogleFonts.config.allowRuntimeFetching = true;

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

  String readClockDetail(WidgetTester tester) {
    final detail = find.byKey(const ValueKey('places_hero_clock_detail'));
    expect(detail, findsOneWidget);

    // The widget carrying this key may be wrapped (for example, by an internal
    // KeyedSubtree). Read the first Text descendant if present; otherwise treat
    // the keyed widget itself as a Text.
    final textDesc = find.descendant(of: detail, matching: find.byType(Text));
    if (textDesc.evaluate().isNotEmpty) {
      final widget = tester.widget<Text>(textDesc.first);
      return widget.data ?? '';
    }

    final widget = tester.widget(detail);
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText() ?? '';
    }
    if (widget is RichText) {
      return widget.text.toPlainText();
    }
    return '';
  }

  testWidgets('DevTools Clock Override updates hero clock display', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    final before = readClockDetail(tester);
    expect(before.isNotEmpty, isTrue);

    // Open dashboard menu (ellipsis) and navigate to Developer Tools.
    final moreButton = find.byKey(const Key('dashboard_menu_button'));
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final devtools = find.byKey(
      const ValueKey('dashboard_menu_developer_tools'),
    );
    expect(devtools, findsOneWidget);
    await tester.tap(devtools);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final clockMenu = find.byKey(const ValueKey('devtools_clock_menu'));
    expect(clockMenu, findsOneWidget);
    await tester.tap(clockMenu);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Enable override, then move slider far enough to guarantee a change.
    final enabled = find.byKey(const ValueKey('devtools_clock_enabled'));
    expect(enabled, findsOneWidget);
    await tester.tap(enabled);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final slider = find.byKey(const ValueKey('devtools_clock_offset_slider'));
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(320, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final after = readClockDetail(tester);
    expect(after, isNot(equals(before)));
  });
}
