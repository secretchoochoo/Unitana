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

  test('DashboardLocalizations resolves currency stale retry with params', () {
    final value = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.currency.stale.retryNow',
      params: const <String, String>{'age': '2m ago'},
    );
    expect(value, 'Rates are stale (last error 2m ago). You can retry now.');
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

  test('DashboardLocalizations resolves migrated tool microcopy keys', () {
    final clearTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tool.history.clearTitle',
    );
    final hint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tool.history.copyHint',
    );
    final refreshNotice = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.currency.notice.refreshing',
    );
    final tipInvalid = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tip.invalidAmount',
    );
    final unitCompare = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.unitPrice.compareA',
      params: const <String, String>{'percent': '12.3'},
    );
    final lookupFrom = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.lookup.from',
      params: const <String, String>{'value': 'US'},
    );
    final comingSoon = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.dashboard.comingSoon',
      params: const <String, String>{'label': 'Settings'},
    );
    final openMenu = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.dashboard.tooltip.openMenu',
    );
    final profileNameFallback = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.dashboard.profileNameFallback',
    );
    final profileDeleteMessage = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.profiles.delete.message',
      params: const <String, String>{'profileName': 'Weekend Trip'},
    );
    final devtoolsSourceSummary = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.devtools.weather.sourceSummary',
      params: const <String, String>{'sourceLabel': 'Live: Open-Meteo'},
    );
    final devtoolsFreshness = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.devtools.weather.freshness.updated',
      params: const <String, String>{'source': 'Demo', 'age': '2m ago'},
    );
    final toolPickerTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.toolPicker.title',
    );
    final removeTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.toolPicker.action.removeTitle',
      params: const <String, String>{'label': 'Weather'},
    );
    final timeMode = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.picker.mode.advancedZones',
    );
    final moreCount = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.toolPicker.moreCount',
      params: const <String, String>{'count': '5'},
    );
    final pickerHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.picker.searchHint.expanded',
    );
    final zoneHeader = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.picker.header.directZones',
    );
    final invalidInput = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.converter.invalidInput',
    );
    final cityFallback = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.cityNotSet',
    );
    final aqiBand = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.aqi.veryUnhealthy',
    );
    final pollenBand = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.pollen.veryHigh',
    );
    expect(clearTitle, 'Clear history?');
    expect(hint, 'tap copies result; long-press copies input');
    expect(refreshNotice, 'Refreshing rates…');
    expect(tipInvalid, 'Enter a valid amount to calculate tip.');
    expect(unitCompare, 'Product A is cheaper by 12.3%.');
    expect(lookupFrom, 'From: US');
    expect(comingSoon, 'Settings: coming soon');
    expect(openMenu, 'Open menu');
    expect(profileNameFallback, 'My Places');
    expect(
      profileDeleteMessage,
      'Delete "Weekend Trip"? This cannot be undone.',
    );
    expect(
      devtoolsSourceSummary,
      'Source: Live: Open-Meteo\nForce hero weather scenes during development',
    );
    expect(devtoolsFreshness, 'Demo: Last update: 2m ago');
    expect(toolPickerTitle, 'Choose a tool');
    expect(removeTitle, 'Remove Weather?');
    expect(timeMode, 'Advanced: Time Zones');
    expect(moreCount, '+5 more');
    expect(pickerHint, 'Search city, country, timezone, or EST');
    expect(zoneHeader, 'Direct Time Zones');
    expect(invalidInput, 'Enter date/time as YYYY-MM-DD HH:MM');
    expect(cityFallback, 'City not set');
    expect(aqiBand, 'Very Unhealthy');
    expect(pollenBand, 'Very High');
  });
}
