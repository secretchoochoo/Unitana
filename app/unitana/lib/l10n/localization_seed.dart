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
    'dashboard.currency.notice.refreshing': 'Refreshing rates…',
    'dashboard.currency.notice.refreshFailed': 'Could not refresh rates',
    'dashboard.tool.tooltip.close': 'Close tool',
    'dashboard.tool.cta.swap': 'Swap',
    'dashboard.tool.cta.addWidget': '+ Add Widget',
    'dashboard.tool.input.editValue': 'Edit Value',
    'dashboard.tool.history.title': 'History',
    'dashboard.tool.history.clear': 'Clear',
    'dashboard.tool.history.clearTitle': 'Clear history?',
    'dashboard.tool.history.clearMessage':
        'Remove the last 10 conversions for this tool.',
    'dashboard.tool.history.copyHint':
        'tap copies result; long-press copies input',
    'dashboard.tool.history.cleared': 'History cleared',
    'dashboard.tool.history.clearButton': 'Clear History',
    'dashboard.tip.billAmountLabel': 'Bill Amount ({currencyCode})',
    'dashboard.tip.splitLabel': 'Split',
    'dashboard.tip.round.none': 'No round',
    'dashboard.tip.round.nearest': 'Nearest',
    'dashboard.tip.round.up': 'Round up',
    'dashboard.tip.round.down': 'Round down',
    'dashboard.tip.invalidAmount': 'Enter a valid amount to calculate tip.',
    'dashboard.tip.line.tip': 'Tip ({percent}%)',
    'dashboard.tip.line.total': 'Total',
    'dashboard.tip.line.perPerson': 'Per person ({count})',
    'dashboard.tip.roundingAdjustment':
        'Rounding adjustment: {sign}{deltaAmount}',
    'dashboard.tax.subtotalLabel': 'Subtotal ({currencyCode})',
    'dashboard.tax.totalLabel': 'Total ({currencyCode})',
    'dashboard.tax.mode.addOn': 'Add-on tax',
    'dashboard.tax.mode.inclusive': 'VAT inclusive',
    'dashboard.tax.invalidAmount': 'Enter a valid amount to calculate tax.',
    'dashboard.tax.line.subtotal': 'Subtotal',
    'dashboard.tax.line.tax': 'Tax ({percent}%)',
    'dashboard.tax.line.total': 'Total',
    'dashboard.tax.mode.help.addOn': 'Mode: add tax on top of subtotal',
    'dashboard.tax.mode.help.inclusive': 'Mode: tax already included in total',
    'dashboard.unitPrice.compareInvalid':
        'Comparison needs valid values in the same unit family.',
    'dashboard.unitPrice.compareA': 'Product A is cheaper by {percent}%.',
    'dashboard.unitPrice.compareB': 'Product B is cheaper by {percent}%.',
    'dashboard.unitPrice.compareEqual':
        'Products are equal in normalized unit price.',
    'dashboard.unitPrice.label.price': 'Price ({currencyCode})',
    'dashboard.unitPrice.label.quantity': 'Quantity',
    'dashboard.unitPrice.title.productA': 'Product A',
    'dashboard.unitPrice.title.productB': 'Product B',
    'dashboard.unitPrice.compareToggle': 'Compare with Product B',
    'dashboard.unitPrice.invalidProductA':
        'Enter valid price and quantity for Product A.',
    'dashboard.time.fromZone.standard': 'From Time Zone',
    'dashboard.time.toZone.standard': 'To Time Zone',
    'dashboard.time.fromZone.jetLag': 'Home Time Zone',
    'dashboard.time.toZone.jetLag': 'Destination Time Zone',
    'dashboard.time.converter.title': 'Convert Local Time',
    'dashboard.time.converter.helper':
        'Enter as YYYY-MM-DD HH:MM in {fromDisplayLabel}',
    'dashboard.time.converter.cta': 'Convert Time',
    'dashboard.jetLag.facts.title': 'Travel Facts',
    'dashboard.time.currentClocks.title': 'Current Clocks',
    'dashboard.jetLag.plan.title': 'Jet Lag Plan',
    'dashboard.jetLag.tips.title': 'Quick Tips',
    'dashboard.jetLag.callWindows.title': 'Call Windows',
    'dashboard.jetLag.callWindows.cta.show': 'Show call windows',
    'dashboard.jetLag.callWindows.intro':
        'Quick check before scheduling calls:',
  };
}
