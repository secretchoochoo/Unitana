import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/tool_definitions.dart';
import 'package:unitana/features/dashboard/widgets/tool_modal_bottom_sheet.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  const home = Place(
    id: 'home',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    unitSystem: 'imperial',
    use24h: false,
  );
  const destination = Place(
    id: 'dest',
    type: PlaceType.visiting,
    name: 'Destination',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    unitSystem: 'metric',
    use24h: true,
  );

  Future<void> pumpCurrencyTool(
    WidgetTester tester, {
    required bool isStale,
    required bool shouldRetryNow,
    DateTime? errorAt,
    DateTime? refreshedAt,
    Future<void> Function()? onRetryCurrencyNow,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: Scaffold(
          body: ToolModalBottomSheet(
            tool: ToolDefinitions.currencyConvert,
            session: DashboardSessionController(),
            preferMetric: true,
            home: home,
            destination: destination,
            currencyIsStale: isStale,
            currencyShouldRetryNow: shouldRetryNow,
            currencyLastErrorAt: errorAt,
            currencyLastRefreshedAt: refreshedAt,
            onRetryCurrencyNow: onRetryCurrencyNow,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets(
    'currency tool shows stale status banner when stale/error exists',
    (tester) async {
      final errorAt = DateTime.now().subtract(const Duration(minutes: 3));
      await pumpCurrencyTool(
        tester,
        isStale: true,
        shouldRetryNow: true,
        errorAt: errorAt,
      );

      final banner = find.byKey(
        const ValueKey('tool_currency_status_currency_convert'),
      );
      expect(banner, findsOneWidget);
      expect(
        find.textContaining('Live rates are temporarily unavailable'),
        findsOneWidget,
      );
    },
  );

  testWidgets('currency tool hides stale status banner when fresh', (
    tester,
  ) async {
    await pumpCurrencyTool(
      tester,
      isStale: false,
      shouldRetryNow: false,
      errorAt: null,
    );

    expect(
      find.byKey(const ValueKey('tool_currency_status_currency_convert')),
      findsNothing,
    );
  });

  testWidgets('currency tool exposes retry action when retry is allowed', (
    tester,
  ) async {
    var called = 0;
    final errorAt = DateTime.now().subtract(const Duration(minutes: 3));
    await pumpCurrencyTool(
      tester,
      isStale: true,
      shouldRetryNow: true,
      errorAt: errorAt,
      onRetryCurrencyNow: () async {
        called += 1;
      },
    );

    final retry = find.byKey(
      const ValueKey('tool_currency_retry_currency_convert'),
    );
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump(const Duration(milliseconds: 120));

    expect(called, 1);
    expect(find.text('Refreshing rates…'), findsOneWidget);
  });

  testWidgets(
    'currency tool shows backoff message when retry is not available yet',
    (tester) async {
      final errorAt = DateTime.now().subtract(const Duration(minutes: 3));
      await pumpCurrencyTool(
        tester,
        isStale: true,
        shouldRetryNow: false,
        errorAt: errorAt,
      );

      expect(find.textContaining('Auto-retry is on.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tool_currency_retry_currency_convert')),
        findsNothing,
      );
    },
  );

  testWidgets('currency tool shows cached-rates message for stale-only state', (
    tester,
  ) async {
    await pumpCurrencyTool(
      tester,
      isStale: true,
      shouldRetryNow: false,
      errorAt: null,
    );

    expect(find.textContaining('Using saved rates'), findsOneWidget);
  });
}
