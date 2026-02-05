import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app.dart';

import 'goldens_test_utils.dart';

void main() {
  final shouldRunGoldens = goldensEnabled();

  group('Wizard flow goldens', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets('wizard step 2 renders (phone)', (tester) async {
      if (!shouldRunGoldens) {
        return;
      }

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const UnitanaApp());
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.byKey(const Key('first_run_nav_next')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/wizard_step2_phone.png'),
      );
    }, skip: !shouldRunGoldens);
  });
}
