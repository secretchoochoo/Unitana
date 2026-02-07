/// Partial Spanish seed map for runtime fallback bridge.
///
/// This intentionally covers a small, high-traffic subset so we can validate
/// locale lookup + English fallback behavior before full ARB generation.
class LocalizationSeedEs {
  const LocalizationSeedEs._();

  static const Map<String, String> es419 = <String, String>{
    'dashboard.weather.title': 'Clima',
    'dashboard.tool.cta.swap': 'Intercambiar',
    'dashboard.time.picker.mode.cities': 'Ciudades',
    'dashboard.hero.env.label.aqi': 'ICA',
    'dashboard.hero.details.title.sun': 'Amanecer • Atardecer',
    'dashboard.hero.details.title.wind': 'Viento • Racha',
    'dashboard.hero.currency.ratePrefix': 'Tipo:',
    'dashboard.profiles.title': 'Perfiles',
  };
}
