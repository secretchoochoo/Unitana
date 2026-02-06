import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/data/city_schema_validator.dart';

void main() {
  test('cities_v1.json satisfies canonical city schema', () {
    final file = File('assets/data/cities_v1.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Missing assets/data/cities_v1.json',
    );

    final decoded = jsonDecode(file.readAsStringSync());
    expect(
      decoded,
      isA<List<dynamic>>(),
      reason: 'Dataset must be a JSON array',
    );

    final rows = decoded as List<dynamic>;
    expect(rows, isNotEmpty, reason: 'Dataset must not be empty');

    final failures = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map<String, dynamic>) {
        failures.add('row $i is not an object');
        continue;
      }

      final errors = CitySchemaValidator.validateRecord(row);
      if (errors.isNotEmpty) {
        failures.add(
          'row $i (${row['id'] ?? 'missing-id'}): ${errors.join(', ')}',
        );
      }
    }

    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });
}
