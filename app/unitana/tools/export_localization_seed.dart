import 'dart:convert';
import 'dart:io';

import 'package:unitana/l10n/localization_seed.dart';

/// Emits the current localization seed table as pretty JSON.
///
/// Usage:
///   dart run tools/export_localization_seed.dart > /tmp/seed.json
void main() {
  final sorted = Map<String, String>.fromEntries(
    LocalizationSeed.enUs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(<String, Object>{
      'namespace': LocalizationSeed.namespace,
      'locale': 'en',
      'entries': sorted,
    }),
  );
}
