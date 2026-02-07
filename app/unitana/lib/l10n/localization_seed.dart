/// ARB migration scaffold for Pack H.
///
/// This is intentionally read-only seed metadata: it defines stable key names
/// and default English strings for high-traffic dashboard/tool surfaces.
/// Runtime still uses `DashboardCopy` until ARB wiring is introduced.
class LocalizationSeed {
  const LocalizationSeed._();

  static const String namespace = 'dashboard';

  static const Map<String, String> enUs = <String, String>{
    'dashboard.weather.title': 'Weather',
    'dashboard.weather.tooltip.refresh': 'Refresh weather',
    'dashboard.weather.tooltip.close': 'Close weather',
    'dashboard.weather.section.destination': 'Destination',
    'dashboard.weather.section.home': 'Home',
    'dashboard.freshness.updating': 'Updating…',
    'dashboard.freshness.notUpdated': 'Not updated',
    'dashboard.freshness.updated': 'Updated {age}',
    'dashboard.freshness.stale': 'Stale ({age})',
    'dashboard.currency.stale.retryNow':
        'Rates are stale (last error {age}). You can retry now.',
    'dashboard.currency.stale.retrySoon':
        'Rates are stale (last error {age}). Retrying in a moment.',
    'dashboard.currency.stale.cached': 'Using cached rates. They may be stale.',
    'dashboard.currency.cta.retry': 'Retry rates',
    'dashboard.tool.tooltip.close': 'Close tool',
    'dashboard.tool.cta.swap': 'Swap',
    'dashboard.tool.cta.addWidget': '+ Add Widget',
    'dashboard.tool.history.title': 'History',
    'dashboard.tool.history.clear': 'Clear',
    'dashboard.time.fromZone.standard': 'From Time Zone',
    'dashboard.time.toZone.standard': 'To Time Zone',
    'dashboard.time.fromZone.jetLag': 'Home Time Zone',
    'dashboard.time.toZone.jetLag': 'Destination Time Zone',
    'dashboard.time.converter.title': 'Convert Local Time',
    'dashboard.time.converter.helper':
        'Enter as YYYY-MM-DD HH:MM in {fromDisplayLabel}',
    'dashboard.time.converter.cta': 'Convert Time',
    'dashboard.jetLag.facts.title': 'Travel Facts',
    'dashboard.jetLag.plan.title': 'Jet Lag Plan',
    'dashboard.jetLag.tips.title': 'Quick Tips',
    'dashboard.jetLag.callWindows.title': 'Call Windows',
    'dashboard.jetLag.callWindows.cta.show': 'Show call windows',
    'dashboard.jetLag.callWindows.intro':
        'Quick check before scheduling calls:',
  };
}
