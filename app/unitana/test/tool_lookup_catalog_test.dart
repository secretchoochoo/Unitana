import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/canonical_tools.dart';
import 'package:unitana/features/dashboard/models/tool_lookup_catalog.dart';

void main() {
  test('lookup systems and defaults stay aligned for key tools', () {
    final shoeSystems = toolLookupSystemsFor(CanonicalToolId.shoeSizes);
    final shoeDefaults = toolLookupDefaultsFor(CanonicalToolId.shoeSizes);
    final cupDefaults = toolLookupDefaultsFor(
      CanonicalToolId.cupsGramsEstimates,
    );

    expect(shoeSystems, containsAll(const <String>['US Men', 'EU', 'JP (cm)']));
    expect(shoeDefaults, isNotNull);
    expect(shoeDefaults!.fromSystem, 'US Men');
    expect(shoeDefaults.toSystem, 'EU');
    expect(shoeDefaults.entryKey, 'shoe_9');

    expect(cupDefaults, isNotNull);
    expect(cupDefaults!.fromSystem, 'Cup');
    expect(cupDefaults.toSystem, 'Weight');
    expect(cupDefaults.entryKey, 'cupsgrams_flour');
  });

  test('lookup presentation helpers produce stable display labels', () {
    final shoeRow = toolLookupEntriesFor(
      CanonicalToolId.shoeSizes,
    ).firstWhere((row) => row.keyId == 'shoe_9');
    final clothingRow = toolLookupEntriesFor(
      CanonicalToolId.clothingSizes,
    ).firstWhere((row) => row.keyId == 'cloth_w_tops_s');

    expect(
      toolLookupReferenceLabel(
        canonicalToolId: CanonicalToolId.shoeSizes,
        row: shoeRow,
      ),
      '27.0 cm',
    );
    expect(toolLookupReferenceHeader(CanonicalToolId.shoeSizes), 'Foot (cm)');
    expect(
      toolLookupMatrixHeaderLabel(
        canonicalToolId: CanonicalToolId.shoeSizes,
        system: 'US Men',
      ),
      'US M',
    );
    expect(
      toolLookupMatrixHeaderLabel(
        canonicalToolId: CanonicalToolId.shoeSizes,
        system: 'US Women',
      ),
      'US W',
    );
    expect(
      toolLookupMatrixValueSystems(CanonicalToolId.shoeSizes),
      isNot(contains('JP (cm)')),
    );

    expect(
      toolLookupReferenceLabel(
        canonicalToolId: CanonicalToolId.clothingSizes,
        row: clothingRow,
      ),
      clothingRow.label,
    );
    expect(
      toolLookupReferenceHeader(CanonicalToolId.clothingSizes),
      'Garment / Size',
    );
    expect(
      toolLookupShouldPersistMatrixSelection(CanonicalToolId.paperSizes),
      isTrue,
    );
    expect(
      toolLookupShouldPersistMatrixSelection(
        CanonicalToolId.cupsGramsEstimates,
      ),
      isFalse,
    );
  });

  test('clothing lookup exposes stable garment groups and row mapping', () {
    final rows = toolLookupEntriesFor(CanonicalToolId.clothingSizes);
    final groups = toolLookupGroupsFor(CanonicalToolId.clothingSizes);
    final outerwearRows = toolLookupEntriesForGroup(
      canonicalToolId: CanonicalToolId.clothingSizes,
      rows: rows,
      groupKey: 'outerwear',
    );

    expect(groups.map((group) => group.keyId), <String>[
      'women_tops',
      'women_bottoms',
      'men_tops',
      'men_bottoms',
      'outerwear',
    ]);
    expect(
      toolLookupGroupKeyForRow(
        canonicalToolId: CanonicalToolId.clothingSizes,
        row: rows.firstWhere((row) => row.keyId == 'cloth_m_bottoms_32'),
      ),
      'men_bottoms',
    );
    expect(outerwearRows.map((row) => row.keyId), <String>[
      'cloth_outer_unisex_m',
      'cloth_outer_unisex_xl',
    ]);
  });
}
