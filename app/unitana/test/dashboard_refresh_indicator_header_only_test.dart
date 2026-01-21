import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/data_refresh_status_label.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets(
    'Refresh indicator renders under city header only (never under hero marquee)',
    (tester) async {
      // Enable network weather via dev backend selection so the refresh label
      // becomes visible (provider-agnostic).
      SharedPreferences.setMockInitialValues({
        'dev_weather_backend_v1': 'openmeteo',
      });

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final state = buildSeededDashboardState();

      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          home: DashboardScreen(state: state),
        ),
      );

      // Allow dev settings + initial layout to settle.
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      final refreshLabel = find.byType(DataRefreshStatusLabel);
      expect(refreshLabel, findsOneWidget);

      final marqueeSlot = find.byKey(const ValueKey('hero_marquee_slot'));
      expect(marqueeSlot, findsOneWidget);

      // Contract: no refresh badge/label under the hero marquee.
      expect(
        find.descendant(of: marqueeSlot, matching: refreshLabel),
        findsNothing,
      );

      final marqueeTexts = tester
          .widgetList<Text>(
            find.descendant(of: marqueeSlot, matching: find.byType(Text)),
          )
          .map((t) => t.data ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      final forbidden = marqueeTexts.any(
        (s) =>
            s.startsWith('Updated ') ||
            s.startsWith('Stale') ||
            s == 'Not updated' ||
            s == 'Updating…',
      );

      expect(forbidden, isFalse);
    },
  );
}
