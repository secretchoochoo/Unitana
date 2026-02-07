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
      LocalizationSeed.enUs['dashboard.time.converter.title'],
      'Convert Local Time',
    );
    expect(
      LocalizationSeed.enUs['dashboard.tool.history.clearTitle'],
      'Clear history?',
    );
    expect(
      LocalizationSeed.enUs['dashboard.tip.invalidAmount'],
      'Enter a valid amount to calculate tip.',
    );
    expect(LocalizationSeed.enUs['dashboard.tax.mode.addOn'], 'Add-on tax');
    expect(
      LocalizationSeed.enUs['dashboard.unitPrice.compareToggle'],
      'Compare with Product B',
    );
  });
}
