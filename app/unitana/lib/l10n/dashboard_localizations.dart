import 'package:flutter/material.dart';

import 'localization_seed.dart';

/// Minimal runtime localization lookup for Pack H pilot wiring.
///
/// This intentionally uses seeded key/value tables with English fallback so we
/// can migrate surfaces incrementally before full ARB generation is introduced.
class DashboardLocalizations {
  final Locale locale;

  const DashboardLocalizations(this.locale);

  static DashboardLocalizations of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return DashboardLocalizations(locale);
  }

  String text(
    String key, {
    Map<String, String> params = const <String, String>{},
    String? fallback,
  }) {
    final template =
        _lookup(locale.languageCode, key) ??
        _lookup('en', key) ??
        fallback ??
        key;
    return _applyParams(template, params);
  }

  static String resolveForLocale({
    required Locale locale,
    required String key,
    Map<String, String> params = const <String, String>{},
    String? fallback,
  }) {
    return DashboardLocalizations(
      locale,
    ).text(key, params: params, fallback: fallback);
  }

  static String? _lookup(String languageCode, String key) {
    final table = _seedByLanguageCode[languageCode];
    return table?[key];
  }

  static String _applyParams(String template, Map<String, String> params) {
    var output = template;
    for (final entry in params.entries) {
      output = output.replaceAll('{${entry.key}}', entry.value);
    }
    return output;
  }

  static const Map<String, Map<String, String>> _seedByLanguageCode =
      <String, Map<String, String>>{'en': LocalizationSeed.enUs};
}
