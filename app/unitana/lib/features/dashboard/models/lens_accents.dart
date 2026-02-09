import 'package:flutter/material.dart';

import '../../../theme/dracula_palette.dart';
import 'activity_lenses.dart';

/// Canonical mapping from lensId -> accent color.
///
/// This is intentionally kept in the dashboard domain layer so both the
/// ToolPicker and tool modals/tiles can share the same accent logic.
class LensAccents {
  const LensAccents._();

  static const Map<String, Color> _toolOverrides = <String, Color>{
    'shoe_sizes': DraculaPalette.red,
  };
  static const Map<String, Color> _toolLightOverrides = <String, Color>{
    // Keep shoes in the same family as its dark-mode red accent, but use a
    // softer Solarized-compatible tone to avoid over-saturation in light mode.
    'shoe_sizes': Color(0xFFB95A5A),
  };

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
        // Keep Weather & Time calmer than yellow while preserving a cool tone.
        return DraculaPalette.comment;
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

  static Color colorForBrightness(String lensId, Brightness brightness) {
    if (brightness != Brightness.light) return colorFor(lensId);
    switch (lensId) {
      case ActivityLensId.travelEssentials:
        return const Color(0xFF3D7194);
      case ActivityLensId.foodCooking:
        return const Color(0xFFB77838);
      case ActivityLensId.healthFitness:
        return const Color(0xFF627228);
      case ActivityLensId.homeDiy:
        return const Color(0xFF6D63A6);
      case ActivityLensId.weatherTime:
        return const Color(0xFF586E75);
      case ActivityLensId.moneyShopping:
        return const Color(0xFFA84F84);
      case ActivityLensId.oddUseful:
        return const Color(0xFFB95A5A);
      case ActivityLensId.quickTools:
        return const Color(0xFF6D63A6);
      default:
        return colorFor(lensId);
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

  static Color iconTintForBrightness(String lensId, Brightness brightness) {
    final alpha = brightness == Brightness.light ? 0.88 : 0.92;
    return colorForBrightness(lensId, brightness).withValues(alpha: alpha);
  }

  static Color toolIconTintFor({required String toolId, String? lensId}) {
    final override = _toolOverrides[toolId];
    if (override != null) {
      return override.withValues(alpha: 0.92);
    }
    return iconTintFor(lensId ?? '');
  }

  static Color toolIconTintForBrightness({
    required String toolId,
    String? lensId,
    required Brightness brightness,
  }) {
    final override = brightness == Brightness.light
        ? (_toolLightOverrides[toolId] ?? _toolOverrides[toolId])
        : _toolOverrides[toolId];
    if (override != null) {
      final alpha = brightness == Brightness.light ? 0.88 : 0.92;
      return override.withValues(alpha: alpha);
    }
    return iconTintForBrightness(lensId ?? '', brightness);
  }
}

extension LensAccentsX on BuildContext {
  Color lensAccent(String lensId) => LensAccents.iconTintFor(lensId);
}
