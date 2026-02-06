import 'canonical_tools.dart';
import 'activity_lenses.dart';

/// Maps activity lenses to canonical tools.
///
/// A tool may appear in multiple lenses without duplicating history.
class ToolLensMap {
  const ToolLensMap._();

  static const Map<String, List<String>> toolsByLensId = <String, List<String>>{
    ActivityLensId.travelEssentials: <String>[
      CanonicalToolId.temperature,
      CanonicalToolId.distance,
      CanonicalToolId.currency,
      CanonicalToolId.time,
      CanonicalToolId.weather,
      CanonicalToolId.liquids,
    ],
    ActivityLensId.foodCooking: <String>[
      CanonicalToolId.liquids,
      CanonicalToolId.weight,
      CanonicalToolId.temperature,
    ],
    ActivityLensId.healthFitness: <String>[
      CanonicalToolId.weight,
      CanonicalToolId.length,
      CanonicalToolId.distance,
      CanonicalToolId.speed,
      CanonicalToolId.liquids,
    ],
    ActivityLensId.homeDiy: <String>[
      CanonicalToolId.length,
      CanonicalToolId.area,
      CanonicalToolId.volume,
      CanonicalToolId.pressure,
      CanonicalToolId.distance,
      CanonicalToolId.weight,
      CanonicalToolId.liquids,
    ],
    ActivityLensId.moneyShopping: <String>[
      CanonicalToolId.currency,
      CanonicalToolId.tipHelper,
    ],
    ActivityLensId.weatherTime: <String>[
      CanonicalToolId.weather,
      CanonicalToolId.time,
      CanonicalToolId.speed,
    ],

    ActivityLensId.oddUseful: <String>[
      CanonicalToolId.currency,
      CanonicalToolId.time,
      CanonicalToolId.distance,
      CanonicalToolId.shoeSizes,
      CanonicalToolId.paperSizes,
      CanonicalToolId.mattressSizes,
    ],

    // Quick Tools is a "fast entry" lens. Until its dedicated lookup tools
    // (shoe sizes, paper sizes, etc.) ship, it still needs a stable mapping
    // so tests and discovery remain consistent.
    ActivityLensId.quickTools: <String>[
      CanonicalToolId.time,
      CanonicalToolId.currency,
      CanonicalToolId.distance,
      CanonicalToolId.shoeSizes,
      CanonicalToolId.paperSizes,
    ],
  };

  /// Returns all lens IDs that include the given tool.
  static List<String> lensesForTool(String toolId) {
    final matches = <String>[];
    for (final entry in toolsByLensId.entries) {
      if (entry.value.contains(toolId)) matches.add(entry.key);
    }
    return matches;
  }
}
