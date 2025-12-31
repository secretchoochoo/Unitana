import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/canonical_tools.dart';

void main() {
  test('Canonical tools registry has unique IDs and required fields', () {
    final ids = CanonicalTools.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'Tool IDs must be unique');

    for (final tool in CanonicalTools.all) {
      expect(tool.id.trim(), isNotEmpty);
      expect(tool.name.trim(), isNotEmpty);
      expect(tool.descriptor.trim(), isNotEmpty);
    }
  });

  test('Teaching tools have stable example pairs', () {
    expect(
      CanonicalTools.temperature.example,
      const DualUnitExample(metric: '20°C', imperial: '68°F'),
    );
    expect(
      CanonicalTools.distance.example,
      const DualUnitExample(metric: '5 km', imperial: '3.1 mi'),
    );
    expect(
      CanonicalTools.liquids.example,
      const DualUnitExample(metric: '355 ml', imperial: '12 oz'),
    );

    // Currency examples are intentionally null because rates are dynamic.
    expect(CanonicalTools.currency.example, isNull);
  });
}
