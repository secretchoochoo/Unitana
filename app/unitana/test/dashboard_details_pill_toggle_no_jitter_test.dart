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

  void expectRectClose(Rect a, Rect b, {double tol = 3.0}) {
    expect((a.left - b.left).abs(), lessThanOrEqualTo(tol));
    expect((a.top - b.top).abs(), lessThanOrEqualTo(tol));
    expect((a.width - b.width).abs(), lessThanOrEqualTo(tol));
    expect((a.height - b.height).abs(), lessThanOrEqualTo(tol));
  }

  testWidgets('Places hero details pill toggles with no layout jitter', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));
    await pumpStable(tester);

    final heroPill = find.byKey(const ValueKey('hero_sun_pill'));
    expect(heroPill, findsOneWidget);

    final before = tester.getRect(heroPill);

    // Tap center to avoid relying on node hit-testing specifics.
    await tester.tapAt(before.center);
    await tester.pump(const Duration(milliseconds: 220));
    await pumpStable(tester);

    final after = tester.getRect(heroPill);
    expectRectClose(before, after);

    // Toggle back.
    await tester.tapAt(after.center);
    await tester.pump(const Duration(milliseconds: 220));
    await pumpStable(tester);

    final back = tester.getRect(heroPill);
    expectRectClose(before, back);
  });

  testWidgets('Pinned overlay segment toggle has no layout jitter', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));
    await pumpStable(tester);

    // The pinned overlay is only built after scrolling past the hero. Scroll
    // first, then assert the segment exists.
    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    Finder detailsSeg() =>
        find.byKey(const ValueKey('dashboard_pinned_segment_home'));

    for (var i = 0; i < 14; i++) {
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 120));
      if (detailsSeg().hitTestable().evaluate().isNotEmpty) break;
    }

    expect(detailsSeg(), findsOneWidget);
    expect(detailsSeg().hitTestable(), findsOneWidget);

    final before = tester.getRect(detailsSeg());

    await tester.tap(detailsSeg().hitTestable());
    await tester.pump(const Duration(milliseconds: 220));
    await pumpStable(tester);

    final after = tester.getRect(detailsSeg());
    expectRectClose(before, after, tol: 12.0);

    await tester.tap(detailsSeg().hitTestable());
    await tester.pump(const Duration(milliseconds: 220));
    await pumpStable(tester);

    final back = tester.getRect(detailsSeg());
    expectRectClose(before, back, tol: 12.0);
  });
}
