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
      locale: const Locale('de'),
      key: 'dashboard.tool.cta.swap',
    );
    expect(value, 'Swap');
  });

  test('DashboardLocalizations resolves french and portuguese seed keys', () {
    final frTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('fr'),
      key: 'dashboard.settings.language.title',
    );
    final ptTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('pt', 'PT'),
      key: 'dashboard.settings.language.title',
    );
    final ptCities = DashboardLocalizations.resolveForLocale(
      locale: const Locale('pt', 'PT'),
      key: 'dashboard.time.picker.mode.cities',
    );

    expect(frTitle, 'Langue');
    expect(ptTitle, 'Idioma');
    expect(ptCities, 'Cidades');
  });

  test(
    'DashboardLocalizations auto-translates fallback strings for pt locale',
    () {
      final ptToolName = DashboardLocalizations.resolveForLocale(
        locale: const Locale('pt', 'PT'),
        key: 'dashboard.tools.distance.title',
        fallback: 'Distance',
      );
      final ptPickerTitle = DashboardLocalizations.resolveForLocale(
        locale: const Locale('pt', 'PT'),
        key: 'dashboard.toolPicker.title',
      );
      expect(ptToolName, 'Distancia');
      expect(ptPickerTitle, isNot('Choose a tool'));
    },
  );

  test(
    'DashboardLocalizations uses partial spanish seed and falls back to english',
    () {
      final weatherEs = DashboardLocalizations.resolveForLocale(
        locale: const Locale('es'),
        key: 'dashboard.weather.title',
      );
      final citiesEs = DashboardLocalizations.resolveForLocale(
        locale: const Locale('es'),
        key: 'dashboard.time.picker.mode.cities',
      );
      final englishFallback = DashboardLocalizations.resolveForLocale(
        locale: const Locale('es'),
        key: 'dashboard.time.converter.title',
      );
      final settingsTitleEs = DashboardLocalizations.resolveForLocale(
        locale: const Locale('es'),
        key: 'dashboard.settings.language.title',
      );

      expect(weatherEs, 'Clima');
      expect(citiesEs, 'Ciudades');
      expect(settingsTitleEs, 'Idioma');
      expect(englishFallback, 'Convert Local Time');
    },
  );

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
    final toolInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tool.input.hint',
    );
    final tipInvalid = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tip.invalidAmount',
    );
    final tipInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tip.inputHint.amount',
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
    final settingsLanguageTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.language.title',
    );
    final settingsLanguageOptionSystem =
        DashboardLocalizations.resolveForLocale(
          locale: const Locale('en'),
          key: 'dashboard.settings.language.option.system',
        );
    final settingsLanguageUpdated = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.language.updated',
    );
    final settingsTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.title',
    );
    final settingsAbout = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.option.about',
    );
    final settingsLicenses = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.option.licenses',
    );
    final settingsAboutTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.about.title',
    );
    final settingsLicensesTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.settings.licenses.title',
    );
    final profileNameFallback = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.dashboard.profileNameFallback',
    );
    final setCityCta = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.dashboard.setCityCta',
    );
    final profileDeleteMessage = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.profiles.delete.message',
      params: const <String, String>{'profileName': 'Weekend Trip'},
    );
    final profileDefaultName = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.profiles.defaultName',
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
    final devtoolsBackend = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.devtools.weather.backend.openMeteo',
    );
    final devtoolsBackendShort = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.devtools.weather.backendShort.mock',
    );
    final devtoolsCondition = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.devtools.weather.condition.clear',
    );
    final heroEnvLabel = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.hero.env.label.aqi',
    );
    final heroEnvIdxSuffix = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.hero.env.indexSuffix',
    );
    final heroEnvBand = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.hero.env.bandShort.pollen.medium',
    );
    final heroDetailsTitle = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.hero.details.title.sun',
    );
    final heroCurrencyRate = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.hero.currency.rate.pair',
      params: const <String, String>{'leftRate': '\$1', 'rightRate': '€0.92'},
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
    final timeInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.converter.inputHint',
    );
    final jetLagBedtimeHelp = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.jetLag.schedule.help.bedtime',
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
    final searching = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.time.picker.searching',
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
    final weatherHighLow = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.banner.highLow',
    );
    final weatherForecastHourly = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.forecast.mode.hourly',
    );
    final weatherForecastDaily = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.forecast.mode.daily',
    );
    final weatherForecastLegend = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.forecast.unitsLegend',
    );
    final weatherForecastSwap = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.forecast.swapTooltip',
    );
    final weatherForecastUnavailable = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.forecast.unavailable',
    );
    final aqiBand = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.aqi.veryUnhealthy',
    );
    final pollenBand = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.pollen.veryHigh',
    );
    final rainLight = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.condition.rainLight',
    );
    final thunderRain = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.weather.condition.thunderRain',
    );
    final cityOnlyHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.cityPicker.searchHint.cityOnly',
    );
    final cityAndTimezoneHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.cityPicker.searchHint.cityAndTimezone',
    );
    final taxInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.tax.inputHint.amount',
    );
    final unitPriceInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.unitPrice.inputHint.price',
    );
    final unitQtyInputHint = DashboardLocalizations.resolveForLocale(
      locale: const Locale('en'),
      key: 'dashboard.unitPrice.inputHint.quantity',
    );
    expect(clearTitle, 'Clear history?');
    expect(hint, 'tap copies result; long-press copies input');
    expect(refreshNotice, 'Refreshing rates…');
    expect(toolInputHint, 'Enter Value');
    expect(tipInvalid, 'Enter a valid amount to calculate tip.');
    expect(tipInputHint, '100.00');
    expect(unitCompare, 'Product A is cheaper by 12.3%.');
    expect(lookupFrom, 'From: US');
    expect(comingSoon, 'Settings: coming soon');
    expect(openMenu, 'Open menu');
    expect(settingsLanguageTitle, 'Language');
    expect(settingsLanguageOptionSystem, 'System default');
    expect(settingsLanguageUpdated, 'Language updated');
    expect(settingsTitle, 'Settings');
    expect(settingsAbout, 'About');
    expect(settingsLicenses, 'Licenses');
    expect(settingsAboutTitle, 'About Unitana');
    expect(settingsLicensesTitle, 'Open-source licenses');
    expect(profileNameFallback, 'My Places');
    expect(setCityCta, 'Set city');
    expect(
      profileDeleteMessage,
      'Delete "Weekend Trip"? This cannot be undone.',
    );
    expect(profileDefaultName, 'New Profile');
    expect(
      devtoolsSourceSummary,
      'Source: Live: Open-Meteo\nForce hero weather scenes during development',
    );
    expect(devtoolsFreshness, 'Demo: Last update: 2m ago');
    expect(devtoolsBackend, 'Live: Open-Meteo');
    expect(devtoolsBackendShort, 'Demo');
    expect(devtoolsCondition, 'Clear');
    expect(heroEnvLabel, 'AQI');
    expect(heroEnvIdxSuffix, ' idx');
    expect(heroEnvBand, 'Med');
    expect(heroDetailsTitle, 'Sunrise • Sunset');
    expect(heroCurrencyRate, 'Rate: \$1 = €0.92');
    expect(toolPickerTitle, 'Choose a tool');
    expect(removeTitle, 'Remove Weather?');
    expect(timeMode, 'Advanced: Time Zones');
    expect(timeInputHint, '2026-02-06 18:30');
    expect(jetLagBedtimeHelp, 'Typical bedtime');
    expect(moreCount, '+5 more');
    expect(pickerHint, 'Search city, country, timezone, or EST');
    expect(searching, 'Searching…');
    expect(zoneHeader, 'Direct Time Zones');
    expect(invalidInput, 'Enter date/time as YYYY-MM-DD HH:MM');
    expect(cityFallback, 'City not set');
    expect(weatherHighLow, 'High • Low');
    expect(weatherForecastHourly, 'Hourly');
    expect(weatherForecastDaily, '7-day');
    expect(weatherForecastLegend, '°C | °F');
    expect(weatherForecastSwap, 'Tap to swap hourly / 7-day');
    expect(weatherForecastUnavailable, 'Forecast unavailable');
    expect(aqiBand, 'Very Unhealthy');
    expect(pollenBand, 'Very High');
    expect(rainLight, 'Light rain');
    expect(thunderRain, 'Thunderstorm');
    expect(cityOnlyHint, 'Search city or country');
    expect(cityAndTimezoneHint, 'Search city, country, timezone, or EST');
    expect(taxInputHint, '100.00');
    expect(unitPriceInputHint, '4.99');
    expect(unitQtyInputHint, '500');
  });
}
