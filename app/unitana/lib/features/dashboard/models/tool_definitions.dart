import 'package:flutter/material.dart';

import 'activity_lenses.dart';
import 'canonical_tools.dart';

enum ToolId { height, baking, liquids, area }

@immutable
class ToolDefinition {
  /// User-facing tool identifier.
  final String id;

  /// Canonical conversion engine identifier used by conversion logic.
  ///
  /// Multiple user-facing tools can share a conversion engine (e.g. baking and
  /// travel liquids). Tool history and layout persistence should always be
  /// keyed by [id], not by this canonical engine id.
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
    lensId: ActivityLensId.healthFitness,
    title: 'Height',
    icon: Icons.height,
    defaultPrimary: '178 cm',
    defaultSecondary: "5' 10\"",
  );

  static const baking = ToolDefinition(
    id: 'baking',
    canonicalToolId: CanonicalToolId.liquids,
    lensId: ActivityLensId.foodCooking,
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
    lensId: ActivityLensId.homeDiy,
    title: 'Area',
    icon: Icons.crop_square_rounded,
    defaultPrimary: '12 m²',
    defaultSecondary: '129 ft²',
  );

  static const distance = ToolDefinition(
    id: 'distance',
    canonicalToolId: CanonicalToolId.distance,
    lensId: ActivityLensId.travelEssentials,
    title: 'Distance',
    icon: Icons.straighten_rounded,
    defaultPrimary: '5 km',
    defaultSecondary: '3.1 mi',
  );

  static const speed = ToolDefinition(
    id: 'speed',
    canonicalToolId: CanonicalToolId.speed,
    lensId: ActivityLensId.travelEssentials,
    title: 'Speed',
    icon: Icons.speed_rounded,
    defaultPrimary: '100 km/h',
    defaultSecondary: '62 mph',
  );

  static const temperature = ToolDefinition(
    id: 'temperature',
    canonicalToolId: CanonicalToolId.temperature,
    lensId: ActivityLensId.travelEssentials,
    title: 'Temperature',
    icon: Icons.device_thermostat_rounded,
    defaultPrimary: '20°C',
    defaultSecondary: '68°F',
  );

  /// Default dashboard tiles shown on a fresh install.
  static const defaultTiles = <ToolDefinition>[height, baking, liquids, area];

  /// Full registry of enabled tool definitions (selection in the picker and
  /// user-added tiles).
  static const registry = <ToolDefinition>[
    height,
    baking,
    liquids,
    area,
    distance,
    speed,
    temperature,
  ];

  static const Map<String, ToolDefinition> _byId = {
    'height': height,
    'baking': baking,
    'liquids': liquids,
    'area': area,
    'distance': distance,
    'speed': speed,
    'temperature': temperature,
  };

  static ToolDefinition? byId(String toolId) => _byId[toolId];
}

class ToolConverters {
  static String? convert({
    required String toolId,
    String? lensId,
    required bool forward,
    required String input,
  }) {
    switch (toolId) {
      case CanonicalToolId.distance:
        return _convertDistance(forward: forward, input: input);
      case CanonicalToolId.speed:
        return _convertSpeed(forward: forward, input: input);
      case CanonicalToolId.temperature:
        return _convertTemperature(forward: forward, input: input);
      case CanonicalToolId.length:
        return _convertLength(forward: forward, input: input);
      case CanonicalToolId.liquids:
        // Liquids is a canonical engine. The lens controls which preset pairing
        // we present: cooking uses cups <-> ml; travel uses fl oz <-> ml.
        if (lensId == ActivityLensId.foodCooking) {
          return _convertBaking(forward: forward, input: input);
        }
        return _convertLiquids(forward: forward, input: input);
      case CanonicalToolId.area:
        return _convertArea(forward: forward, input: input);
      default:
        return null;
    }
  }

  static String? _convertDistance({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    const miPerKm = 0.621371;
    if (forward) {
      final mi = value * miPerKm;
      return '${_fmt(mi)} mi';
    }
    final km = value / miPerKm;
    return '${_fmt(km)} km';
  }

  static String? _convertSpeed({required bool forward, required String input}) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    const mphPerKmh = 0.621371;
    if (forward) {
      final mph = value * mphPerKmh;
      return '${_fmt(mph)} mph';
    }
    final kmh = value / mphPerKmh;
    return '${_fmt(kmh)} km/h';
  }

  static String? _convertTemperature({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    if (forward) {
      final f = value * 9 / 5 + 32;
      return '${_fmt(f)}°F';
    }
    final c = (value - 32) * 5 / 9;
    return '${_fmt(c)}°C';
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
