import 'package:flutter/material.dart';

/// Canonical converter IDs.
///
/// These IDs are intended to be stable across refactors and are suitable for
/// persistence (history ownership, dashboard layout, profiles).
class CanonicalToolId {
  const CanonicalToolId._();

  static const String time = 'time';
  static const String currency = 'currency';
  static const String temperature = 'temperature';
  static const String distance = 'distance';
  static const String speed = 'speed';
  static const String area = 'area';
  static const String liquids = 'liquids';
  static const String weight = 'weight';
  static const String length = 'length';
  static const String volume = 'volume';
  static const String pressure = 'pressure';
  static const String shoeSizes = 'shoe_sizes';
  static const String weather = 'weather';
  static const String dataStorage = 'data_storage';

  static const List<String> all = <String>[
    time,
    currency,
    temperature,
    distance,
    speed,
    area,
    liquids,
    weight,
    length,
    volume,
    pressure,
    shoeSizes,
    weather,
    dataStorage,
  ];
}

@immutable
class DualUnitExample {
  final String metric;
  final String imperial;

  const DualUnitExample({required this.metric, required this.imperial});
}

@immutable
class CanonicalTool {
  final String id;
  final String name;
  final String descriptor;
  final IconData icon;
  final DualUnitExample? example;

  const CanonicalTool({
    required this.id,
    required this.name,
    required this.descriptor,
    required this.icon,
    this.example,
  });
}

/// One source of truth for the canonical converters.
///
/// Lenses may influence copy, presets, and log tagging, but tool IDs and
/// history ownership remain canonical.
class CanonicalTools {
  const CanonicalTools._();

  static const CanonicalTool time = CanonicalTool(
    id: CanonicalToolId.time,
    name: 'Time',
    descriptor: 'Home vs local time; 12/24h',
    icon: Icons.schedule_rounded,
  );

  static const CanonicalTool currency = CanonicalTool(
    id: CanonicalToolId.currency,
    name: 'Currency',
    descriptor: 'Quick exchange using current rates',
    icon: Icons.currency_exchange_rounded,
    // Currency examples depend on rates; keep null to avoid teaching the wrong
    // relationship by default. Tiles can still display "Example" with a
    // placeholder until live rates are available.
    example: null,
  );

  static const CanonicalTool temperature = CanonicalTool(
    id: CanonicalToolId.temperature,
    name: 'Temperature',
    descriptor: '°C ↔ °F',
    icon: Icons.thermostat_rounded,
    example: DualUnitExample(metric: '20°C', imperial: '68°F'),
  );

  static const CanonicalTool distance = CanonicalTool(
    id: CanonicalToolId.distance,
    name: 'Distance',
    descriptor: 'km ↔ mi',
    icon: Icons.directions_walk_rounded,
    example: DualUnitExample(metric: '5 km', imperial: '3.1 mi'),
  );

  static const CanonicalTool speed = CanonicalTool(
    id: CanonicalToolId.speed,
    name: 'Speed',
    descriptor: 'km/h ↔ mph',
    icon: Icons.speed_rounded,
  );

  static const CanonicalTool area = CanonicalTool(
    id: CanonicalToolId.area,
    name: 'Area',
    descriptor: 'm² ↔ ft²',
    icon: Icons.crop_square_rounded,
    example: DualUnitExample(metric: '12 m²', imperial: '129 ft²'),
  );

  static const CanonicalTool liquids = CanonicalTool(
    id: CanonicalToolId.liquids,
    name: 'Liquids',
    descriptor: 'ml ↔ oz, cups ↔ ml',
    icon: Icons.water_drop_rounded,
    example: DualUnitExample(metric: '355 ml', imperial: '12 oz'),
  );

  static const CanonicalTool weight = CanonicalTool(
    id: CanonicalToolId.weight,
    name: 'Weight',
    descriptor: 'kg ↔ lb',
    icon: Icons.fitness_center_rounded,
    example: DualUnitExample(metric: '10 kg', imperial: '22 lb'),
  );

  static const CanonicalTool length = CanonicalTool(
    id: CanonicalToolId.length,
    name: 'Length',
    descriptor: 'cm ↔ ft/in',
    icon: Icons.straighten_rounded,
    example: DualUnitExample(metric: '178 cm', imperial: "5' 10\""),
  );

  static const CanonicalTool volume = CanonicalTool(
    id: CanonicalToolId.volume,
    name: 'Volume',
    descriptor: 'L ↔ gal',
    icon: Icons.local_drink_rounded,
  );

  static const CanonicalTool pressure = CanonicalTool(
    id: CanonicalToolId.pressure,
    name: 'Pressure',
    descriptor: 'kPa ↔ psi',
    icon: Icons.tire_repair_rounded,
  );

  static const CanonicalTool shoeSizes = CanonicalTool(
    id: CanonicalToolId.shoeSizes,
    name: 'Shoe Sizes',
    descriptor: 'EU ↔ US (men) with UK/JP hints',
    icon: Icons.directions_run_rounded,
  );

  static const CanonicalTool weather = CanonicalTool(
    id: CanonicalToolId.weather,
    name: 'Weather',
    descriptor: 'Conditions, precipitation, wind',
    icon: Icons.cloud_rounded,
  );

  static const List<CanonicalTool> all = <CanonicalTool>[
    time,
    currency,
    temperature,
    distance,
    speed,
    area,
    liquids,
    weight,
    length,
    volume,
    pressure,
    shoeSizes,
    weather,
  ];

  static final Map<String, CanonicalTool> byId =
      Map<String, CanonicalTool>.unmodifiable({for (final t in all) t.id: t});
}
