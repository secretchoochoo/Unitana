/// Partial Spanish seed map for runtime fallback bridge.
///
/// This intentionally covers a small, high-traffic subset so we can validate
/// locale lookup + English fallback behavior before full ARB generation.
class LocalizationSeedEs {
  const LocalizationSeedEs._();

  static const Map<String, String> es419 = <String, String>{
    'dashboard.weather.title': 'Clima',
    'dashboard.weather.banner.highLow': 'Máx • Mín',
    'dashboard.weather.forecast.mode.hourly': 'Por hora',
    'dashboard.weather.forecast.mode.daily': '7 días',
    'dashboard.weather.forecast.unitsLegend': '°C | °F',
    'dashboard.weather.forecast.swapTooltip':
        'Toca para alternar por hora / 7 días',
    'dashboard.weather.forecast.unavailable': 'Pronóstico no disponible',
    'dashboard.tool.cta.swap': 'Intercambiar',
    'dashboard.time.picker.mode.cities': 'Ciudades',
    'dashboard.hero.env.label.aqi': 'ICA',
    'dashboard.hero.details.title.sun': 'Amanecer • Atardecer',
    'dashboard.hero.details.title.wind': 'Viento • Racha',
    'dashboard.hero.currency.ratePrefix': 'Tipo:',
    'dashboard.profiles.title': 'Perfiles',
    'dashboard.settings.title': 'Configuración',
    'dashboard.settings.option.about': 'Acerca de',
    'dashboard.settings.option.licenses': 'Licencias',
    'dashboard.settings.language.title': 'Idioma',
    'dashboard.settings.language.option.system': 'Predeterminado del sistema',
    'dashboard.settings.language.option.en': 'Inglés',
    'dashboard.settings.language.option.es': 'Español',
    'dashboard.settings.language.option.fr': 'Francés',
    'dashboard.settings.language.option.ptPT': 'Portugués (Portugal)',
    'dashboard.settings.language.updated': 'Idioma actualizado',
    'dashboard.settings.theme.title': 'Tema',
    'dashboard.settings.theme.option.system': 'Sistema',
    'dashboard.settings.theme.option.dark': 'Oscuro',
    'dashboard.settings.theme.option.light': 'Claro',
    'dashboard.settings.theme.updated': 'Tema actualizado',
    'dashboard.settings.about.title': 'Acerca de Unitana',
    'dashboard.settings.about.tagline':
        'Descifrador centrado en viajes; doble realidad en paralelo',
    'dashboard.settings.about.body':
        'Unitana ayuda a comparar contexto de casa y destino con herramientas prácticas de tiempo, clima y conversiones.',
    'dashboard.settings.about.legalese':
        'Copyright 2026 colaboradores de Unitana',
    'dashboard.settings.licenses.title': 'Licencias de código abierto',
  };
}
