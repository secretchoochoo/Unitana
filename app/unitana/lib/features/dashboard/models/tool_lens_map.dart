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
    ActivityLensId.foodAndCooking: <String>[
      CanonicalToolId.liquids,
      CanonicalToolId.weight,
      CanonicalToolId.temperature,
    ],
    ActivityLensId.healthAndFitness: <String>[
      CanonicalToolId.weight,
      CanonicalToolId.length,
      CanonicalToolId.distance,
      CanonicalToolId.speed,
      CanonicalToolId.liquids,
    ],
    ActivityLensId.homeAndDiy: <String>[
      CanonicalToolId.length,
      CanonicalToolId.area,
      CanonicalToolId.distance,
      CanonicalToolId.weight,
      CanonicalToolId.liquids,
    ],
    ActivityLensId.money: <String>[CanonicalToolId.currency],
    ActivityLensId.weatherAndTime: <String>[
      CanonicalToolId.weather,
      CanonicalToolId.time,
      CanonicalToolId.speed,
    ],
    // Favorites is user-defined; mapping is intentionally empty.
    ActivityLensId.favorites: <String>[],
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
