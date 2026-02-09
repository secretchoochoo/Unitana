/// Partial French seed map for runtime fallback bridge.
///
/// Keeps high-traffic language/settings/weather labels localized while
/// preserving deterministic English fallback for uncovered keys.
class LocalizationSeedFr {
  const LocalizationSeedFr._();

  static const Map<String, String> frFr = <String, String>{
    'dashboard.weather.title': 'Meteo',
    'dashboard.weather.banner.highLow': 'Max • Min',
    'dashboard.weather.forecast.mode.hourly': 'Horaire',
    'dashboard.weather.forecast.mode.daily': '7 jours',
    'dashboard.weather.forecast.unitsLegend': '°C | °F',
    'dashboard.weather.forecast.swapTooltip':
        'Touchez pour basculer horaire / 7 jours',
    'dashboard.weather.forecast.unavailable': 'Previsions indisponibles',
    'dashboard.tool.cta.swap': 'Permuter',
    'dashboard.time.picker.mode.cities': 'Villes',
    'dashboard.settings.title': 'Parametres',
    'dashboard.settings.option.about': 'A propos',
    'dashboard.settings.option.licenses': 'Licences',
    'dashboard.settings.language.title': 'Langue',
    'dashboard.settings.language.option.system': 'Par defaut du systeme',
    'dashboard.settings.language.option.en': 'Anglais',
    'dashboard.settings.language.option.es': 'Espagnol',
    'dashboard.settings.language.option.fr': 'Francais',
    'dashboard.settings.language.option.ptPT': 'Portugais (Portugal)',
    'dashboard.settings.language.updated': 'Langue mise a jour',
  };
}
