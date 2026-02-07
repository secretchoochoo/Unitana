import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/l10n/dashboard_localizations.dart';

void main() {
  test('DashboardLocalizations resolves seeded english keys', () {
    final value = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.title',
    );
    expect(value, 'Weather');
  });

  test('DashboardLocalizations replaces placeholder params', () {
    final value = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.freshness.updated',
      params: const <String, String>{'age': '5m ago'},
    );
    expect(value, 'Updated 5m ago');
  });

  test('DashboardLocalizations falls back to english when locale missing', () {
    final value = DashboardLocalizations.resolveForLocale(
      locale: const Locale('es'),
      key: 'dashboard.tool.cta.swap',
    );
    expect(value, 'Swap');
  });

  test('DashboardLocalizations uses explicit fallback when key missing', () {
    final value = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.missing.key',
      fallback: 'fallback value',
    );
    expect(value, 'fallback value');
  });
}
