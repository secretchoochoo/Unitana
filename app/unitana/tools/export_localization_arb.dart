import 'dart:convert';
import 'dart:io';

import 'package:unitana/l10n/localization_seed.dart';
import 'package:unitana/l10n/localization_seed_es.dart';

Map<String, String> _sorted(Map<String, String> map) {
  return Map<String, String>.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

void _writeArb(String path, Map<String, String> content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(content));
}

/// Generates ARB bridge files from runtime seed maps.
///
/// Usage:
///   dart run tools/export_localization_arb.dart
void main() {
  final en = _sorted(LocalizationSeed.enUs);
  final es = _sorted(<String, String>{
    for (final entry in en.entries)
      entry.key: LocalizationSeedEs.es419[entry.key] ?? '',
  });

  _writeArb('lib/l10n/arb/app_en.arb', <String, String>{
    '@@locale': 'en',
    ...en,
  });
  _writeArb('lib/l10n/arb/app_es.arb', <String, String>{
    '@@locale': 'es',
    ...es,
  });

  stdout.writeln('Wrote lib/l10n/arb/app_en.arb and app_es.arb');
}
