/// Partial European Portuguese seed map for runtime fallback bridge.
///
/// Keeps high-traffic language/settings/weather labels localized while
/// preserving deterministic English fallback for uncovered keys.
class LocalizationSeedPt {
  const LocalizationSeedPt._();

  static const Map<String, String> ptPt = <String, String>{
    'dashboard.weather.title': 'Meteorologia',
    'dashboard.weather.banner.highLow': 'Max • Min',
    'dashboard.weather.forecast.mode.hourly': 'Horario',
    'dashboard.weather.forecast.mode.daily': '7 dias',
    'dashboard.weather.forecast.unitsLegend': '°C | °F',
    'dashboard.weather.forecast.swapTooltip':
        'Toque para alternar horario / 7 dias',
    'dashboard.weather.forecast.unavailable': 'Previsao indisponivel',
    'dashboard.tool.cta.swap': 'Trocar',
    'dashboard.time.picker.mode.cities': 'Cidades',
    'dashboard.dashboard.menu.title': 'Menu',
    'dashboard.settings.title': 'Definicoes',
    'dashboard.settings.option.about': 'Sobre',
    'dashboard.settings.option.licenses': 'Licencas',
    'dashboard.settings.language.title': 'Idioma',
    'dashboard.settings.language.option.system': 'Predefinido do sistema',
    'dashboard.settings.language.option.en': 'Ingles',
    'dashboard.settings.language.option.es': 'Espanhol',
    'dashboard.settings.language.option.fr': 'Frances',
    'dashboard.settings.language.option.ptPT': 'Portugues (Portugal)',
    'dashboard.settings.language.updated': 'Idioma atualizado',
    'dashboard.settings.theme.title': 'Tema',
    'dashboard.settings.theme.option.system': 'Sistema',
    'dashboard.settings.theme.option.dark': 'Escuro',
    'dashboard.settings.theme.option.light': 'Claro',
    'dashboard.settings.theme.updated': 'Tema atualizado',
  };
}
