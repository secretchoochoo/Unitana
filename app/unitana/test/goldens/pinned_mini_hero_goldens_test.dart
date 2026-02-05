import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dashboard_test_helpers.dart';

void main() {
  // Goldens are opt-in by default. When running `--update-goldens`, Flutter sets
  // `autoUpdateGoldenFiles=true`, and we should allow the suite to execute even
  // if UNITANA_GOLDENS is not set.
  final shouldRunGoldens =
      Platform.environment['UNITANA_GOLDENS'] == '1' || autoUpdateGoldenFiles;

  setUpAll(() {
    if (!shouldRunGoldens) {
      // ignore: avoid_print
      print(
        'Goldens disabled. To generate/update baselines, run: '
        'flutter test --update-goldens test/goldens/pinned_mini_hero_goldens_test.dart',
      );
    }
  });

  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets(
    'Golden: Pinned mini-hero overlay (destination selected)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDashboardHarness(tester);
      await pumpStable(tester);

      // Scroll enough to force the pinned overlay to appear.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await pumpStable(tester);

      // Destination selected is the default segment in the pinned overlay tests.
      expect(
        find.byKey(const ValueKey('dashboard_pinned_mini_hero_readout')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(const ValueKey('dashboard_pinned_mini_hero_readout')),
        matchesGoldenFile('goldens/pinned_mini_hero_dest.png'),
      );
    },
    skip: !shouldRunGoldens,
  );

  testWidgets('Golden: Pinned mini-hero overlay (home selected)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    // Scroll enough to force the pinned overlay to appear.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await pumpStable(tester);

    // Switch to home.
    final homeSeg = find.byKey(const ValueKey('dashboard_pinned_segment_home'));
    if (homeSeg.evaluate().isNotEmpty) {
      await tester.tap(homeSeg);
      await pumpStable(tester);
    }

    expect(
      find.byKey(const ValueKey('dashboard_pinned_mini_hero_readout')),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(const ValueKey('dashboard_pinned_mini_hero_readout')),
      matchesGoldenFile('goldens/pinned_mini_hero_home.png'),
    );
  }, skip: !shouldRunGoldens);
}
