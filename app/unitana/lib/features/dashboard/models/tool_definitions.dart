import 'package:flutter/material.dart';

import 'activity_lenses.dart';
import 'canonical_tools.dart';

enum ToolId { height, baking, liquids, area }

@immutable
class ToolDefinition {
  /// Engine identifier used by conversion logic.
  final String id;

  /// Canonical tool identifier used for shared history and persistence.
  /// Example: both 'baking' and 'liquids' can share CanonicalToolId.liquids.
  final String canonicalToolId;

  /// Optional activity lens tag for UI presets + log labeling.
  final String? lensId;

  final String title;
  final IconData icon;
  final String defaultPrimary;
  final String defaultSecondary;

  const ToolDefinition({
    required this.id,
    required this.canonicalToolId,
    this.lensId,
    required this.title,
    required this.icon,
    required this.defaultPrimary,
    required this.defaultSecondary,
  });
}

class ToolDefinitions {
  static const height = ToolDefinition(
    id: 'height',
    canonicalToolId: CanonicalToolId.length,
    lensId: ActivityLensId.travelEssentials,
    title: 'Distance',
    icon: Icons.accessibility_new_rounded,
    defaultPrimary: '178 cm',
    defaultSecondary: "5' 10\"",
  );

  static const baking = ToolDefinition(
    id: 'baking',
    canonicalToolId: CanonicalToolId.liquids,
    lensId: ActivityLensId.foodAndCooking,
    title: 'Baking',
    icon: Icons.local_cafe_rounded,
    defaultPrimary: '1 cup',
    defaultSecondary: '240 ml',
  );

  static const liquids = ToolDefinition(
    id: 'liquids',
    canonicalToolId: CanonicalToolId.liquids,
    lensId: ActivityLensId.travelEssentials,
    title: 'Liquids',
    icon: Icons.water_drop_rounded,
    defaultPrimary: '12 oz',
    defaultSecondary: '355 ml',
  );

  static const area = ToolDefinition(
    id: 'area',
    canonicalToolId: CanonicalToolId.area,
    lensId: ActivityLensId.homeAndDiy,
    title: 'Area',
    icon: Icons.crop_square_rounded,
    defaultPrimary: '12 m²',
    defaultSecondary: '129 ft²',
  );

  static const all = <ToolDefinition>[height, baking, liquids, area];
}

class ToolConverters {
  static String? convert({
    required String toolId,
    String? lensId,
    required bool forward,
    required String input,
  }) {
    switch (toolId) {
      case CanonicalToolId.length:
        return _convertLength(forward: forward, input: input);
      case CanonicalToolId.liquids:
        // Liquids is a canonical engine. The lens controls which preset pairing
        // we present: cooking uses cups <-> ml; travel uses fl oz <-> ml.
        if (lensId == ActivityLensId.foodAndCooking) {
          return _convertBaking(forward: forward, input: input);
        }
        return _convertLiquids(forward: forward, input: input);
      case CanonicalToolId.area:
        return _convertArea(forward: forward, input: input);
      default:
        return null;
    }
  }

  static String? _convertBaking({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    // Design mock uses 1 cup = 240 ml.
    if (forward) {
      final ml = value * 240.0;
      return '${_fmt(ml)} ml';
    }
    final cups = value / 240.0;
    return '${_fmt(cups)} cup';
  }

  static String? _convertLiquids({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    // US fl oz to ml.
    const mlPerOz = 29.5735;
    if (forward) {
      final ml = value * mlPerOz;
      return '${_fmt(ml)} ml';
    }
    final oz = value / mlPerOz;
    return '${_fmt(oz)} oz';
  }

  static String? _convertArea({required bool forward, required String input}) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    const ft2PerM2 = 10.7639;
    if (forward) {
      final ft2 = value * ft2PerM2;
      return '${_fmt(ft2)} ft²';
    }
    final m2 = value / ft2PerM2;
    return '${_fmt(m2)} m²';
  }

  static String? _convertLength({
    required bool forward,
    required String input,
  }) {
    if (forward) {
      // cm -> ft/in
      final cm = double.tryParse(input.trim());
      if (cm == null) return null;
      final totalIn = cm / 2.54;
      final ft = totalIn ~/ 12;
      final inches = (totalIn - (ft * 12)).round();
      return "$ft' $inches\"";
    }

    // ft/in -> cm. Accept formats: 5'10", 5 10, 5ft 10in, 70
    final t = input.trim().toLowerCase();
    // NOTE: Avoid raw strings here because we want to include a literal double quote
    // in the regex (for inputs like 5'10"). In Dart raw strings, \" does not escape
    // the quote delimiter.
    final re = RegExp(
      '^(\\d+)\\s*(?:ft|\')\\s*(\\d+)?\\s*(?:in|")?\\s*'
      r'$',
    );
    final m = re.firstMatch(t);
    if (m != null) {
      final ft = int.tryParse(m.group(1) ?? '');
      final inch = int.tryParse(m.group(2) ?? '0') ?? 0;
      if (ft == null) return null;
      final totalIn = ft * 12 + inch;
      final cm = totalIn * 2.54;
      return '${_fmt(cm)} cm';
    }

    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 2) {
      final ft = int.tryParse(parts[0]);
      final inch = int.tryParse(parts[1]);
      if (ft != null && inch != null) {
        final cm = (ft * 12 + inch) * 2.54;
        return '${_fmt(cm)} cm';
      }
    }

    // Fallback: assume inches.
    final inches = double.tryParse(t);
    if (inches == null) return null;
    final cm = inches * 2.54;
    return '${_fmt(cm)} cm';
  }

  static String _fmt(double v) {
    // Keep outputs compact and stable for UI and tests.
    if ((v - v.roundToDouble()).abs() < 0.0001) {
      return v.round().toString();
    }
    return v.toStringAsFixed(1);
  }
}
