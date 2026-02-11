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

  /// Menu + picker display title.
  ///
  /// Policy: keep this in Title Case ("Body Weight", "Prime School", etc.).
  /// If a shorter label is needed for dashboard tiles, use
  /// [ToolDefinitions.widgetTitleFor] (shortnames are tile-only).
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
  /// Short display titles used only on dashboard tiles.
  ///
  /// Policy:
  /// - Tools menu and picker always use [ToolDefinition.title] (full Title Case).
  /// - Tiles may use shortnames to avoid truncation on small devices.
  /// - Keep shortnames recognizable and compact; prefer common abbreviations.
  static const Map<String, String> _widgetShortTitles = {
    'temperature': 'Temp',
    'oven_temperature': 'Oven Temp',
    'body_weight': 'Body Wt',
    'time_zone_converter': 'TZ Converter',
    'paper_sizes': 'Paper',
    'mattress_sizes': 'Mattress',
    'shoe_sizes': 'Shoes',
    'world_clock_delta': 'Time Map',
    'unit_price_helper': 'Price Compare',
  };

  static String widgetTitleFor(ToolDefinition tool) {
    return _widgetShortTitles[tool.id] ?? tool.title;
  }

  static const height = ToolDefinition(
    id: 'height',
    canonicalToolId: CanonicalToolId.length,
    lensId: ActivityLensId.healthFitness,
    title: 'Height',
    icon: Icons.height,
    defaultPrimary: '178 cm',
    defaultSecondary: "5' 10\"",
  );

  static const length = ToolDefinition(
    id: 'length',
    canonicalToolId: CanonicalToolId.length,
    lensId: ActivityLensId.homeDiy,
    title: 'Length',
    icon: Icons.straighten_rounded,
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

  static const cupsGramsEstimates = ToolDefinition(
    id: 'cups_grams_estimates',
    canonicalToolId: CanonicalToolId.cupsGramsEstimates,
    lensId: ActivityLensId.foodCooking,
    title: 'Cups ↔ Grams Estimates',
    icon: Icons.restaurant_menu_rounded,
    defaultPrimary: 'Flour (all-purpose)',
    defaultSecondary: '1 cup ≈ 120 g',
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

  static const volume = ToolDefinition(
    id: 'volume',
    canonicalToolId: CanonicalToolId.volume,
    lensId: ActivityLensId.homeDiy,
    title: 'Volume',
    icon: Icons.local_drink_rounded,
    defaultPrimary: '10 L',
    defaultSecondary: '2.6 gal',
  );

  static const pressure = ToolDefinition(
    id: 'pressure',
    canonicalToolId: CanonicalToolId.pressure,
    lensId: ActivityLensId.homeDiy,
    title: 'Pressure',
    icon: Icons.tire_repair_rounded,
    defaultPrimary: '220 kPa',
    defaultSecondary: '32 psi',
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

  static const pace = ToolDefinition(
    id: 'pace',
    canonicalToolId: CanonicalToolId.pace,
    lensId: ActivityLensId.healthFitness,
    title: 'Pace',
    icon: Icons.directions_run_rounded,
    defaultPrimary: '5:30 min/km',
    defaultSecondary: '8:51 min/mi',
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

  static const ovenTemperature = ToolDefinition(
    id: 'oven_temperature',
    canonicalToolId: CanonicalToolId.temperature,
    lensId: ActivityLensId.foodCooking,
    title: 'Oven Temperature',
    icon: Icons.bakery_dining_rounded,
    defaultPrimary: '350°F',
    defaultSecondary: '177°C',
  );

  static const time = ToolDefinition(
    id: 'time',
    canonicalToolId: CanonicalToolId.time,
    lensId: ActivityLensId.travelEssentials,
    title: 'Time',
    icon: Icons.schedule_rounded,
    defaultPrimary: '18:30',
    defaultSecondary: '6:30 PM',
  );

  static const timeZoneConverter = ToolDefinition(
    id: 'time_zone_converter',
    canonicalToolId: CanonicalToolId.time,
    lensId: ActivityLensId.weatherTime,
    title: 'Time Zone Converter',
    icon: Icons.travel_explore_rounded,
    defaultPrimary: '2026-02-06 18:30',
    defaultSecondary: '2026-02-06 10:30',
  );

  static const jetLagDelta = ToolDefinition(
    id: 'jet_lag_delta',
    canonicalToolId: CanonicalToolId.time,
    lensId: ActivityLensId.travelEssentials,
    title: 'Jet Lag',
    icon: Icons.airline_seat_recline_normal_rounded,
    defaultPrimary: 'Destination +7h',
    defaultSecondary: 'Adjust over 4 days',
  );

  static const dataStorage = ToolDefinition(
    id: 'data_storage',
    canonicalToolId: CanonicalToolId.dataStorage,
    lensId: ActivityLensId.travelEssentials,
    title: 'Data Storage',
    icon: Icons.sd_storage_rounded,
    defaultPrimary: '1 GB',
    defaultSecondary: '1024 MB',
  );

  static const energy = ToolDefinition(
    id: 'energy',
    canonicalToolId: CanonicalToolId.energy,
    lensId: ActivityLensId.healthFitness,
    title: 'Calories / Energy',
    icon: Icons.local_fire_department_rounded,
    defaultPrimary: '500 cal',
    defaultSecondary: '2092 kJ',
  );

  static const hydration = ToolDefinition(
    id: 'hydration',
    canonicalToolId: CanonicalToolId.hydration,
    lensId: ActivityLensId.healthFitness,
    title: 'Hydration',
    icon: Icons.water_drop_rounded,
    defaultPrimary: '70 kg • 45 min',
    defaultSecondary: '2.7 L / day estimate',
  );

  static const currencyConvert = ToolDefinition(
    id: 'currency_convert',
    canonicalToolId: CanonicalToolId.currency,
    lensId: ActivityLensId.moneyShopping,
    title: 'Currency',
    icon: Icons.currency_exchange_rounded,
    defaultPrimary: '€10.00',
    defaultSecondary: '\$11.00',
  );

  static const shoeSizes = ToolDefinition(
    id: 'shoe_sizes',
    canonicalToolId: CanonicalToolId.shoeSizes,
    lensId: ActivityLensId.quickTools,
    title: 'Shoes',
    icon: Icons.directions_run_rounded,
    defaultPrimary: '42 EU',
    defaultSecondary: '9 US M',
  );

  static const paperSizes = ToolDefinition(
    id: 'paper_sizes',
    canonicalToolId: CanonicalToolId.paperSizes,
    lensId: ActivityLensId.oddUseful,
    title: 'Paper Sizes',
    icon: Icons.description_rounded,
    defaultPrimary: 'A4',
    defaultSecondary: '210 × 297 mm',
  );

  static const mattressSizes = ToolDefinition(
    id: 'mattress_sizes',
    canonicalToolId: CanonicalToolId.mattressSizes,
    lensId: ActivityLensId.oddUseful,
    title: 'Mattress Sizes',
    icon: Icons.bed_rounded,
    defaultPrimary: 'Queen (US)',
    defaultSecondary: '60 × 80 in',
  );

  static const weight = ToolDefinition(
    id: 'weight',
    canonicalToolId: CanonicalToolId.weight,
    lensId: ActivityLensId.foodCooking,
    title: 'Weight',
    icon: Icons.monitor_weight_rounded,
    defaultPrimary: '1 kg',
    defaultSecondary: '2.2 lb',
  );

  /// Weather summary tile.
  ///
  /// This is not a numeric converter; it opens a lightweight details sheet
  /// driven by the live dashboard data controller.
  static const weatherSummary = ToolDefinition(
    id: 'weather_summary',
    canonicalToolId: CanonicalToolId.weather,
    lensId: ActivityLensId.weatherTime,
    title: 'Weather',
    icon: Icons.cloud_rounded,
    // These are placeholders; the dashboard renders live labels when possible.
    defaultPrimary: '—',
    defaultSecondary: '—',
  );

  static const worldClockDelta = ToolDefinition(
    id: 'world_clock_delta',
    canonicalToolId: CanonicalToolId.time,
    lensId: ActivityLensId.weatherTime,
    title: 'World Time Map',
    icon: Icons.public_rounded,
    defaultPrimary: 'Δ --',
    defaultSecondary: 'Set both cities',
  );

  static const tipHelper = ToolDefinition(
    id: 'tip_helper',
    canonicalToolId: CanonicalToolId.tipHelper,
    lensId: ActivityLensId.moneyShopping,
    title: 'Tip Helper',
    icon: Icons.percent_rounded,
    defaultPrimary: '\$100.00',
    defaultSecondary: '15% • Split 2',
  );

  static const taxVatHelper = ToolDefinition(
    id: 'tax_vat_helper',
    canonicalToolId: 'tax_vat_helper',
    lensId: ActivityLensId.moneyShopping,
    title: 'Sales Tax / VAT Helper',
    icon: Icons.calculate_rounded,
    defaultPrimary: '\$100.00',
    defaultSecondary: '8% • Add-on',
  );

  static const unitPriceHelper = ToolDefinition(
    id: 'unit_price_helper',
    canonicalToolId: 'unit_price_helper',
    lensId: ActivityLensId.moneyShopping,
    title: 'Price Compare',
    icon: Icons.local_offer_rounded,
    defaultPrimary: '\$4.99',
    defaultSecondary: '500 g',
  );

  static const bodyWeight = ToolDefinition(
    id: 'body_weight',
    canonicalToolId: CanonicalToolId.weight,
    lensId: ActivityLensId.healthFitness,
    title: 'Body Weight',
    icon: Icons.monitor_weight_rounded,
    defaultPrimary: '70 kg',
    defaultSecondary: '154 lb',
  );

  /// Default dashboard tiles shown on a fresh install.
  static const defaultTiles = <ToolDefinition>[
    temperature,
    currencyConvert,
    baking,
    distance,
    time,
    unitPriceHelper,
  ];

  /// Full registry of enabled tool definitions (selection in the picker and
  /// user-added tiles).
  static const registry = <ToolDefinition>[
    height,
    length,
    baking,
    liquids,
    cupsGramsEstimates,
    area,
    volume,
    pressure,
    distance,
    speed,
    pace,
    temperature,
    ovenTemperature,
    time,
    jetLagDelta,
    dataStorage,
    energy,
    hydration,
    currencyConvert,
    shoeSizes,
    paperSizes,
    mattressSizes,
    weight,
    bodyWeight,
    weatherSummary,
    worldClockDelta,
    tipHelper,
    taxVatHelper,
    unitPriceHelper,
  ];

  static const Map<String, ToolDefinition> _byId = {
    'height': height,
    'length': length,
    'baking': baking,
    'liquids': liquids,
    'cups_grams_estimates': cupsGramsEstimates,
    'area': area,
    'volume': volume,
    'pressure': pressure,
    'distance': distance,
    'speed': speed,
    'pace': pace,
    'temperature': temperature,
    'oven_temperature': ovenTemperature,
    'time': time,
    'jet_lag_delta': jetLagDelta,
    'time_zone_converter': timeZoneConverter,
    'data_storage': dataStorage,
    'energy': energy,
    'hydration': hydration,
    'currency_convert': currencyConvert,
    'shoe_sizes': shoeSizes,
    'paper_sizes': paperSizes,
    'mattress_sizes': mattressSizes,
    'weight': weight,
    'body_weight': bodyWeight,
    'weather_summary': weatherSummary,
    'world_clock_delta': worldClockDelta,
    'tip_helper': tipHelper,
    'tax_vat_helper': taxVatHelper,
    'unit_price_helper': unitPriceHelper,
  };

  static ToolDefinition? byId(String toolId) => _byId[toolId];
}

// Local data row for the shoe-size lookup table.
// Kept private and colocated with the tool definitions so we do not introduce
// any cross-feature dependency for a small, static dataset.
//
// NOTE: Values are approximate, intended for quick travel use rather than
// brand-specific fit.
class _ShoeRow {
  final int eu;
  final double usM;
  final double uk;
  final double jp;

  const _ShoeRow({
    required this.eu,
    required this.usM,
    required this.uk,
    required this.jp,
  });
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
      case CanonicalToolId.pace:
        return _convertPace(forward: forward, input: input);
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
      case CanonicalToolId.volume:
        return _convertVolume(forward: forward, input: input);
      case CanonicalToolId.pressure:
        return _convertPressure(forward: forward, input: input);
      case CanonicalToolId.shoeSizes:
        return _convertShoeSizes(forward: forward, input: input);
      case CanonicalToolId.weight:
        return _convertWeight(forward: forward, input: input);
      case CanonicalToolId.time:
        return _convertTime(forward: forward, input: input);
      default:
        return null;
    }
  }

  /// Multi-unit conversion for tools that support more than a single fixed pair.
  ///
  /// This is intentionally narrow-scope (currently Volume and Pressure) so we can
  /// expand the unit surface without forcing a “From/To” UI everywhere.
  ///
  /// Returns a formatted output label including the [toUnit] suffix, or null if
  /// the input could not be parsed.
  static String? convertWithUnits({
    required String toolId,
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    switch (toolId) {
      case CanonicalToolId.distance:
        return _convertDistanceWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.area:
        return _convertAreaWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.liquids:
        return _convertLiquidsWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.volume:
        return _convertVolumeWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.pressure:
        return _convertPressureWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.weight:
        return _convertWeightWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.dataStorage:
        return _convertDataStorageWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      case CanonicalToolId.energy:
        return _convertEnergyWithUnits(
          fromUnit: fromUnit,
          toUnit: toUnit,
          input: input,
        );
      default:
        // Fallback to the dual-unit engine when no multi-unit mapping exists.
        return convert(toolId: toolId, forward: true, input: input);
    }
  }

  static String? _convertDistanceWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into meters as a base unit.
    const metersPer = <String, double>{
      'm': 1.0,
      'km': 1000.0,
      'mi': 1609.344,
      'yd': 0.9144,
      'ft': 0.3048,
      'in': 0.0254,
    };

    final fromFactor = metersPer[fromUnit];
    final toFactor = metersPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final meters = value * fromFactor;
    final out = meters / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertVolumeWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into liters as a base unit.
    const litersPer = <String, double>{
      'mL': 0.001,
      'L': 1.0,
      // US liquid units.
      'pt': 0.473176,
      'qt': 0.946353,
      'gal': 3.78541,
    };

    final fromFactor = litersPer[fromUnit];
    final toFactor = litersPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final liters = value * fromFactor;
    final out = liters / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertAreaWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into square meters as a base unit.
    const sqmPer = <String, double>{
      'm²': 1.0,
      'm2': 1.0,
      'ft²': 0.09290304,
      'ft2': 0.09290304,
      'yd²': 0.83612736,
      'yd2': 0.83612736,
      'acre': 4046.8564224,
      'ha': 10000.0,
      'hectare': 10000.0,
    };

    final fromFactor = sqmPer[fromUnit];
    final toFactor = sqmPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final sqm = value * fromFactor;
    final out = sqm / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertLiquidsWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into mL as a shared volume base.
    const mlPer = <String, double>{
      'ml': 1.0,
      'mL': 1.0,
      'L': 1000.0,
      'cup': 236.5882365,
      'tbsp': 14.78676478125,
      'tsp': 4.92892159375,
      'oz': 29.5735295625,
      'fl oz': 29.5735295625,
      'pt': 473.176473,
      'qt': 946.352946,
    };

    final fromFactor = mlPer[fromUnit];
    final toFactor = mlPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final ml = value * fromFactor;
    final out = ml / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertPressureWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into kPa as a base unit.
    const kpaPer = <String, double>{
      'kPa': 1.0,
      'psi': 6.89476,
      'bar': 100.0,
      'atm': 101.325,
    };

    final fromFactor = kpaPer[fromUnit];
    final toFactor = kpaPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final kpa = value * fromFactor;
    final out = kpa / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertWeightWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into kilograms as a base unit.
    const kgPer = <String, double>{
      'g': 0.001,
      'kg': 1.0,
      'oz': 0.0283495,
      'lb': 0.453592,
      'st': 6.35029,
    };

    final fromFactor = kgPer[fromUnit];
    final toFactor = kgPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final kg = value * fromFactor;
    final out = kg / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertDataStorageWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into bytes (binary multiples for practical storage math).
    const bytesPer = <String, double>{
      'B': 1.0,
      'KB': 1024.0,
      'MB': 1024.0 * 1024.0,
      'GB': 1024.0 * 1024.0 * 1024.0,
      'TB': 1024.0 * 1024.0 * 1024.0 * 1024.0,
    };

    final fromFactor = bytesPer[fromUnit];
    final toFactor = bytesPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final bytes = value * fromFactor;
    final out = bytes / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  static String? _convertEnergyWithUnits({
    required String fromUnit,
    required String toUnit,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // Normalize into kilocalories as base unit.
    const kcalPer = <String, double>{'kcal': 1.0, 'cal': 1.0, 'kJ': 1 / 4.184};
    final fromFactor = kcalPer[fromUnit];
    final toFactor = kcalPer[toUnit];
    if (fromFactor == null || toFactor == null) return null;

    final kcal = value * fromFactor;
    final out = kcal / toFactor;
    return '${_fmt(out)} $toUnit';
  }

  /// Converts between 24h and 12h time representations.
  ///
  /// `forward == true` means 24h -> 12h.
  /// `forward == false` means 12h -> 24h.
  ///
  /// Supported inputs:
  /// - 24h: `18:30`, `1830`, `6:05` (treated as 06:05)
  /// - 12h: `6:30 PM`, `6pm`, `12:00 am`
  ///
  /// Notes:
  /// - For 12h -> 24h, AM/PM is required; otherwise we return null.
  static String? _convertTime({required bool forward, required String input}) {
    var raw = input.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    if (lower == 'noon') {
      return forward ? '12 PM' : '12:00';
    }
    if (lower == 'midnight') {
      return forward ? '12 AM' : '00:00';
    }

    final hasAm = lower.contains('am');
    final hasPm = lower.contains('pm');
    final hasMeridiem = hasAm || hasPm;

    // Remove meridiem markers and other non-digit separators we tolerate.
    raw = lower
        .replaceAll('am', '')
        .replaceAll('pm', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    int hour;
    int minute;

    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length != 2) return null;
      hour = int.tryParse(parts[0]) ?? -1;
      minute = int.tryParse(parts[1]) ?? -1;
    } else {
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      if (digits.length == 4) {
        hour = int.tryParse(digits.substring(0, 2)) ?? -1;
        minute = int.tryParse(digits.substring(2, 4)) ?? -1;
      } else if (digits.length == 3) {
        hour = int.tryParse(digits.substring(0, 1)) ?? -1;
        minute = int.tryParse(digits.substring(1, 3)) ?? -1;
      } else {
        hour = int.tryParse(digits) ?? -1;
        minute = 0;
      }
    }

    if (minute < 0 || minute > 59) return null;

    if (forward) {
      // 24h -> 12h
      // If user supplied AM/PM, we'll still accept it as a hint, but treat the
      // numeric hour as the source of truth.
      if (hour < 0 || hour > 23) {
        // Sometimes users type 12h in the 24h direction; accept 1..12 if AM/PM exists.
        if (!hasMeridiem || hour < 1 || hour > 12) return null;
        var h = hour % 12;
        if (hasPm) h += 12;
        hour = h;
      }

      final suffix = hour < 12 ? 'AM' : 'PM';
      var hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      if (minute == 0) {
        return '$hour12 $suffix';
      }
      final mm = minute.toString().padLeft(2, '0');
      return '$hour12:$mm $suffix';
    }

    // 12h -> 24h
    if (!hasMeridiem) return null;
    if (hour < 1 || hour > 12) return null;
    var h24 = hour % 12;
    if (hasPm) h24 += 12;
    final hh = h24.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String? _convertWeight({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    const lbPerKg = 2.2046226218;
    if (forward) {
      final lb = value * lbPerKg;
      return '${_fmt(lb)} lb';
    }
    final kg = value / lbPerKg;
    return '${_fmt(kg)} kg';
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

  static String? _convertPace({required bool forward, required String input}) {
    final minutes = _parsePaceMinutes(input);
    if (minutes == null || minutes <= 0) return null;

    const kmPerMi = 1.609344;
    // forward => min/km -> min/mi
    final converted = forward ? (minutes * kmPerMi) : (minutes / kmPerMi);
    final unit = forward ? 'min/mi' : 'min/km';
    return '${_fmtPaceMinutes(converted)} $unit';
  }

  static double? _parsePaceMinutes(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return null;

    // mm:ss or m:ss
    final colon = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(raw);
    if (colon != null) {
      final mm = int.tryParse(colon.group(1)!);
      final ss = int.tryParse(colon.group(2)!);
      if (mm == null || ss == null || ss < 0 || ss > 59) return null;
      return mm + (ss / 60.0);
    }

    // 5m30s / 5m / 30s
    final token = RegExp(
      r'^(?:(\d{1,2})m)?\s*(?:(\d{1,2})s)?$',
    ).firstMatch(raw);
    if (token != null && (token.group(1) != null || token.group(2) != null)) {
      final mm = int.tryParse(token.group(1) ?? '0');
      final ss = int.tryParse(token.group(2) ?? '0');
      if (mm == null || ss == null || ss < 0 || ss > 59) return null;
      return mm + (ss / 60.0);
    }

    return double.tryParse(raw);
  }

  static String _fmtPaceMinutes(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final mm = totalSeconds ~/ 60;
    final ss = totalSeconds % 60;
    return '$mm:${ss.toString().padLeft(2, '0')}';
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

  static String? _convertVolume({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    // US liquid gallons.
    const litersPerGallon = 3.78541;
    if (forward) {
      final gal = value / litersPerGallon;
      return '${_fmt(gal)} gal';
    }
    final liters = value * litersPerGallon;
    return '${_fmt(liters)} L';
  }

  static String? _convertPressure({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    // kPa ↔ psi. 1 psi = 6.89476 kPa.
    const kpaPerPsi = 6.89476;
    if (forward) {
      final psi = value / kpaPerPsi;
      return '${_fmt(psi)} psi';
    }
    final kpa = value * kpaPerPsi;
    return '${_fmt(kpa)} kPa';
  }

  static String? _convertShoeSizes({
    required bool forward,
    required String input,
  }) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;

    // EU is treated as the “metric” side. US uses men's sizing.
    const rows = <_ShoeRow>[
      _ShoeRow(eu: 35, usM: 3, uk: 2.5, jp: 21.5),
      _ShoeRow(eu: 36, usM: 4, uk: 3.5, jp: 22.5),
      _ShoeRow(eu: 37, usM: 5, uk: 4.5, jp: 23.5),
      _ShoeRow(eu: 38, usM: 6, uk: 5.5, jp: 24.5),
      _ShoeRow(eu: 39, usM: 7, uk: 6.5, jp: 25.0),
      _ShoeRow(eu: 40, usM: 7.5, uk: 7, jp: 25.5),
      _ShoeRow(eu: 41, usM: 8, uk: 7.5, jp: 26.0),
      _ShoeRow(eu: 42, usM: 9, uk: 8, jp: 26.5),
      _ShoeRow(eu: 43, usM: 9.5, uk: 8.5, jp: 27.0),
      _ShoeRow(eu: 44, usM: 10, uk: 9, jp: 27.5),
      _ShoeRow(eu: 45, usM: 11, uk: 10, jp: 28.5),
      _ShoeRow(eu: 46, usM: 12, uk: 11, jp: 29.5),
      _ShoeRow(eu: 47, usM: 13, uk: 12, jp: 30.5),
    ];

    _ShoeRow nearestByEu(double eu) {
      var best = rows.first;
      var bestDelta = (best.eu.toDouble() - eu).abs();
      for (final r in rows.skip(1)) {
        final delta = (r.eu.toDouble() - eu).abs();
        if (delta < bestDelta) {
          best = r;
          bestDelta = delta;
        }
      }
      return best;
    }

    _ShoeRow nearestByUs(double us) {
      var best = rows.first;
      var bestDelta = (best.usM - us).abs();
      for (final r in rows.skip(1)) {
        final delta = (r.usM - us).abs();
        if (delta < bestDelta) {
          best = r;
          bestDelta = delta;
        }
      }
      return best;
    }

    if (forward) {
      // EU -> US (men)
      final r = nearestByEu(value);
      return '${_fmtShoe(r.usM)} US M (UK ${_fmtShoe(r.uk)}, JP ${_fmtShoe(r.jp)})';
    }

    // US (men) -> EU
    final r = nearestByUs(value);
    return '${_fmtShoe(r.eu.toDouble())} EU (UK ${_fmtShoe(r.uk)}, JP ${_fmtShoe(r.jp)})';
  }

  static String _fmtShoe(double v) {
    if ((v - v.roundToDouble()).abs() < 0.0001) {
      return v.round().toString();
    }
    // Shoe sizes commonly use 0.5 increments.
    return v.toStringAsFixed(1).replaceAll('.0', '');
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

    // Common shorthand: 6.4 means 6 ft 4 in (not decimal feet).
    final shorthand = RegExp(r'^(\d{1,2})[.,](\d{1,2})$').firstMatch(t);
    if (shorthand != null) {
      final ft = int.tryParse(shorthand.group(1) ?? '');
      final inch = int.tryParse(shorthand.group(2) ?? '');
      if (ft != null && inch != null && inch <= 11) {
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
