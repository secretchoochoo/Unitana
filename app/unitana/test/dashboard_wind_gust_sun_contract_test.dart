import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    // Avoid pumpAndSettle; dashboard has live elements.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 160));
  }

  String richTextPlainText(WidgetTester tester, Finder finder) {
    final widget = tester.widget<RichText>(finder);
    return widget.text.toPlainText(includeSemanticsLabels: false);
  }

  testWidgets('Hero wind rows are centered when in wind mode', (tester) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));
    await pumpStable(tester);

    final pill = find.byKey(const ValueKey('hero_sun_pill'));
    expect(pill, findsOneWidget);

    // Toggle to wind mode (pill starts in Sun mode).
    await tester.tap(pill);
    await tester.pump(const Duration(milliseconds: 220));
    await pumpStable(tester);

    final windRow = find.byKey(const ValueKey('hero_wind_row'));
    final gustRow = find.byKey(const ValueKey('hero_gust_row'));
    expect(windRow, findsOneWidget);
    expect(gustRow, findsOneWidget);

    final pillRect = tester.getRect(pill);
    final windRect = tester.getRect(windRow);
    final gustRect = tester.getRect(gustRow);

    // Center alignment contract: rows should remain visually centered in wind mode.
    expect((windRect.center.dx - pillRect.center.dx).abs(), lessThan(12.0));
    expect((gustRect.center.dx - pillRect.center.dx).abs(), lessThan(12.0));
  });

  testWidgets('Pinned overlay gust line includes gust suffix', (tester) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));
    await pumpStable(tester);

    final detailsPill = find.byKey(
      const ValueKey('dashboard_pinned_details_pill'),
    );
    expect(detailsPill, findsOneWidget);

    // Scroll until overlay is interactive.
    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);
    for (var i = 0; i < 14; i++) {
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 120));
      if (detailsPill.hitTestable().evaluate().isNotEmpty) break;
    }
    expect(detailsPill.hitTestable(), findsOneWidget);

    // Ensure we are in wind mode; if currently sun, toggle once.
    final windContentKey = find.byKey(
      const ValueKey('dashboard_pinned_details_wind'),
    );
    if (windContentKey.evaluate().isEmpty) {
      await tester.tap(detailsPill.hitTestable());
      await tester.pump(const Duration(milliseconds: 220));
      await pumpStable(tester);
    }
    expect(windContentKey, findsOneWidget);

    // Second line must include the gust suffix (lowercase).
    final gustText = find.textContaining('gust');
    expect(gustText, findsWidgets);
  });

  testWidgets('Hero sunrise and sunset rows do not include timezone labels', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));
    await pumpStable(tester);

    final pill = find.byKey(const ValueKey('hero_sun_pill'));
    expect(pill, findsOneWidget);

    // Ensure we're in sun mode; if currently wind, toggle back.
    final sunriseRow = find.byKey(const ValueKey('hero_sunrise_row'));
    if (sunriseRow.evaluate().isEmpty) {
      await tester.tap(pill);
      await tester.pump(const Duration(milliseconds: 220));
      await pumpStable(tester);
    }

    final sunsetRow = find.byKey(const ValueKey('hero_sunset_row'));

    // The keyed widgets are the RichText themselves (not a wrapper), so target them directly.
    expect(sunriseRow, findsOneWidget);
    expect(sunsetRow, findsOneWidget);

    final riseText = richTextPlainText(tester, sunriseRow);
    final setText = richTextPlainText(tester, sunsetRow);

    // Contract: sunrise/sunset lines should not show timezone abbreviations.
    // We keep this as a conservative guard against regressions like "7:12 AM MT".
    const bannedTokens = <String>[
      ' UTC',
      ' GMT',
      ' Z',
      ' MT',
      ' MST',
      ' MDT',
      ' PT',
      ' PST',
      ' PDT',
      ' ET',
      ' EST',
      ' EDT',
    ];
    for (final token in bannedTokens) {
      expect(riseText.contains(token), isFalse);
      expect(setText.contains(token), isFalse);
    }
  });
}
