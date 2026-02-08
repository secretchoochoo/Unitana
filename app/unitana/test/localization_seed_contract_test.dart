import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/l10n/localization_seed.dart';

void main() {
  test('localization seed keys are namespaced and unique', () {
    final keys = LocalizationSeed.enUs.keys.toList();
    expect(keys, isNotEmpty);
    expect(keys.toSet().length, keys.length);
    for (final key in keys) {
      expect(key.startsWith('${LocalizationSeed.namespace}.'), isTrue);
    }
  });

  test('localization seed includes Pack H bootstrap critical keys', () {
    expect(LocalizationSeed.enUs['dashboard.freshness.updating'], 'Updating…');
    expect(
      LocalizationSeed.enUs['dashboard.currency.cta.retry'],
      'Retry rates',
    );
    expect(
      LocalizationSeed.enUs['dashboard.jetLag.plan.title'],
      'Jet Lag Plan',
    );
    expect(
      LocalizationSeed.enUs['dashboard.jetLag.schedule.help.bedtime'],
      'Typical bedtime',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.converter.title'],
      'Convert Local Time',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.converter.inputHint'],
      '2026-02-06 18:30',
    );
    expect(
      LocalizationSeed.enUs['dashboard.tool.history.clearTitle'],
      'Clear history?',
    );
    expect(LocalizationSeed.enUs['dashboard.tool.input.hint'], 'Enter Value');
    expect(
      LocalizationSeed.enUs['dashboard.tip.invalidAmount'],
      'Enter a valid amount to calculate tip.',
    );
    expect(LocalizationSeed.enUs['dashboard.tip.inputHint.amount'], '100.00');
    expect(LocalizationSeed.enUs['dashboard.tax.mode.addOn'], 'Add-on tax');
    expect(LocalizationSeed.enUs['dashboard.tax.inputHint.amount'], '100.00');
    expect(
      LocalizationSeed.enUs['dashboard.unitPrice.compareToggle'],
      'Compare with Product B',
    );
    expect(
      LocalizationSeed.enUs['dashboard.unitPrice.inputHint.price'],
      '4.99',
    );
    expect(
      LocalizationSeed.enUs['dashboard.unitPrice.inputHint.quantity'],
      '500',
    );
    expect(LocalizationSeed.enUs['dashboard.lookup.sizeMatrix'], 'Size Matrix');
    expect(
      LocalizationSeed.enUs['dashboard.dashboard.updated'],
      'Dashboard updated',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.direction.eastbound'],
      'Eastbound',
    );
    expect(LocalizationSeed.enUs['dashboard.lookup.from'], 'From: {value}');
    expect(
      LocalizationSeed.enUs['dashboard.dashboard.tooltip.openMenu'],
      'Open menu',
    );
    expect(
      LocalizationSeed.enUs['dashboard.dashboard.profileNameFallback'],
      'My Places',
    );
    expect(LocalizationSeed.enUs['dashboard.dashboard.setCityCta'], 'Set city');
    expect(
      LocalizationSeed.enUs['dashboard.settings.language.title'],
      'Language',
    );
    expect(
      LocalizationSeed.enUs['dashboard.settings.language.option.system'],
      'System default',
    );
    expect(
      LocalizationSeed.enUs['dashboard.settings.language.option.es'],
      'Español',
    );
    expect(
      LocalizationSeed.enUs['dashboard.settings.language.updated'],
      'Language updated',
    );
    expect(LocalizationSeed.enUs['dashboard.settings.title'], 'Settings');
    expect(LocalizationSeed.enUs['dashboard.settings.option.about'], 'About');
    expect(
      LocalizationSeed.enUs['dashboard.settings.option.licenses'],
      'Licenses',
    );
    expect(
      LocalizationSeed.enUs['dashboard.settings.about.title'],
      'About Unitana',
    );
    expect(
      LocalizationSeed.enUs['dashboard.settings.licenses.title'],
      'Open-source licenses',
    );
    expect(LocalizationSeed.enUs['dashboard.profiles.title'], 'Profiles');
    expect(
      LocalizationSeed.enUs['dashboard.profiles.delete.message'],
      'Delete "{profileName}"? This cannot be undone.',
    );
    expect(
      LocalizationSeed.enUs['dashboard.profiles.defaultName'],
      'New Profile',
    );
    expect(
      LocalizationSeed.enUs['dashboard.devtools.weather.sourceHeading'],
      'Weather Source',
    );
    expect(
      LocalizationSeed.enUs['dashboard.devtools.clock.title'],
      'Clock Override',
    );
    expect(
      LocalizationSeed.enUs['dashboard.devtools.weather.backend.openMeteo'],
      'Live: Open-Meteo',
    );
    expect(
      LocalizationSeed.enUs['dashboard.devtools.weather.backendShort.mock'],
      'Demo',
    );
    expect(
      LocalizationSeed
          .enUs['dashboard.devtools.weather.condition.thunderstorm'],
      'Thunderstorm',
    );
    expect(LocalizationSeed.enUs['dashboard.hero.env.label.aqi'], 'AQI');
    expect(LocalizationSeed.enUs['dashboard.hero.env.indexSuffix'], ' idx');
    expect(
      LocalizationSeed.enUs['dashboard.hero.env.bandShort.aqi.veryUnhealthy'],
      'VUnh',
    );
    expect(
      LocalizationSeed.enUs['dashboard.hero.details.title.wind'],
      'Wind • Gust',
    );
    expect(
      LocalizationSeed.enUs['dashboard.hero.currency.rate.sameCurrency'],
      'Rate: same currency',
    );
    expect(
      LocalizationSeed.enUs['dashboard.devtools.resetRestart.title'],
      'Reset and Restart',
    );
    expect(
      LocalizationSeed.enUs['dashboard.toolPicker.title'],
      'Choose a tool',
    );
    expect(
      LocalizationSeed.enUs['dashboard.tool.unitPicker.fromCurrency'],
      'From Currency',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.picker.mode.cities'],
      'Cities',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.picker.searchHint.expanded'],
      'Search city, country, timezone, or EST',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.picker.searching'],
      'Searching…',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.picker.header.directZones'],
      'Direct Time Zones',
    );
    expect(
      LocalizationSeed.enUs['dashboard.time.converter.invalidInput'],
      'Enter date/time as YYYY-MM-DD HH:MM',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.cityNotSet'],
      'City not set',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.banner.highLow'],
      'High • Low',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.forecast.mode.hourly'],
      'Hourly',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.forecast.mode.daily'],
      '7-day',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.forecast.unitsLegend'],
      '°C | °F',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.forecast.swapTooltip'],
      'Tap to swap hourly / 7-day',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.forecast.unavailable'],
      'Forecast unavailable',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.aqi.unhealthySensitive'],
      'Unhealthy (Sensitive)',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.pollen.veryHigh'],
      'Very High',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.condition.thunderRain'],
      'Thunderstorm',
    );
    expect(
      LocalizationSeed.enUs['dashboard.weather.condition.weather'],
      'Weather',
    );
    expect(
      LocalizationSeed.enUs['dashboard.cityPicker.searchHint.cityOnly'],
      'Search city or country',
    );
    expect(
      LocalizationSeed.enUs['dashboard.cityPicker.searchHint.cityAndTimezone'],
      'Search city, country, timezone, or EST',
    );
    expect(
      LocalizationSeed.enUs['dashboard.cityPicker.header.topCities'],
      'Top Cities',
    );
    expect(
      LocalizationSeed.enUs['dashboard.toolPicker.resultsHeader'],
      'Results',
    );
    expect(
      LocalizationSeed.enUs['dashboard.toolPicker.moreCount'],
      '+{count} more',
    );
  });
}
