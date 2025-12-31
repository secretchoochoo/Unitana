import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/activity_lenses.dart';
import 'package:unitana/features/dashboard/models/canonical_tools.dart';
import 'package:unitana/features/dashboard/models/tool_lens_map.dart';

void main() {
  test('Every non-favorites lens has at least one tool', () {
    for (final lens in ActivityLenses.all) {
      if (lens.id == ActivityLensId.favorites) continue;
      final tools = ToolLensMap.toolsByLensId[lens.id];
      expect(tools, isNotNull, reason: 'Missing mapping for lens: ${lens.id}');
      expect(
        tools!,
        isNotEmpty,
        reason: 'Lens should not be empty: ${lens.id}',
      );
    }
  });

  test('Every canonical tool is discoverable in at least one lens', () {
    for (final tool in CanonicalTools.all) {
      // Favorites is user-curated; ignore it.
      final lenses = ToolLensMap.lensesForTool(
        tool.id,
      ).where((id) => id != ActivityLensId.favorites).toList();

      expect(
        lenses,
        isNotEmpty,
        reason: 'Tool must appear in at least one lens: ${tool.id}',
      );
    }
  });
}
