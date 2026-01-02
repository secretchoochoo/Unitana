import 'package:flutter/material.dart';

import '../../../theme/dracula_palette.dart';
import 'activity_lenses.dart';

/// Canonical mapping from lensId -> accent color.
///
/// This is intentionally kept in the dashboard domain layer so both the
/// ToolPicker and tool modals/tiles can share the same accent logic.
class LensAccents {
  const LensAccents._();

  static Color colorFor(String lensId) {
    switch (lensId) {
      case ActivityLensId.travelEssentials:
        return DraculaPalette.cyan;
      case ActivityLensId.foodCooking:
        return DraculaPalette.orange;
      case ActivityLensId.healthFitness:
        return DraculaPalette.green;
      case ActivityLensId.homeDiy:
        return DraculaPalette.purple;
      case ActivityLensId.weatherTime:
        return DraculaPalette.yellow;
      case ActivityLensId.moneyShopping:
        return DraculaPalette.pink;
      case ActivityLensId.oddUseful:
        return DraculaPalette.red;
      case ActivityLensId.quickTools:
        // Quick Tools is a discovery surface; keep it aligned to the primary.
        return DraculaPalette.purple;
      default:
        return DraculaPalette.purple;
    }
  }

  /// Used when you want subtle tinting rather than a full accent.
  ///
  /// This keeps icons readable on the Dracula background without turning the
  /// picker into a rainbow.
  static Color iconTintFor(String lensId) {
    // Slightly soften accents so they sit well with Dracula foreground.
    return colorFor(lensId).withValues(alpha: 0.92);
  }
}

extension LensAccentsX on BuildContext {
  Color lensAccent(String lensId) => LensAccents.iconTintFor(lensId);
}
