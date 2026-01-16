import 'package:flutter/material.dart';

import 'activity_lenses.dart';

@immutable
class ToolRegistryTool {
  /// Stable tool identifier used for Keys and (eventually) persistence.
  final String toolId;
  final String label;
  final IconData icon;

  /// Activity lenses where this tool appears.
  final List<String> lenses;

  /// Optional per-lens preset metadata.
  ///
  /// Slice C only needs this for ordering and future-proofing; tooling
  /// behavior is still driven by the existing ToolDefinition / converter layer.
  final Map<String, Map<String, Object?>> presetsByLens;

  /// Whether this tool is currently wired to a dashboard tile + modal.
  ///
  /// Slice C focuses on the picker UX; unsupported tools are discoverable but
  /// disabled to avoid breaking flows.
  final bool isEnabled;

  const ToolRegistryTool({
    required this.toolId,
    required this.label,
    required this.icon,
    required this.lenses,
    this.presetsByLens = const <String, Map<String, Object?>>{},
    this.isEnabled = false,
  });
}

class ToolRegistry {
  const ToolRegistry._();

  /// Lens ordering is part of the UI contract.
  static const List<String> lensOrder = <String>[
    ActivityLensId.travelEssentials,
    ActivityLensId.foodCooking,
    ActivityLensId.healthFitness,
    ActivityLensId.homeDiy,
    ActivityLensId.weatherTime,
    ActivityLensId.moneyShopping,
    ActivityLensId.oddUseful,
    ActivityLensId.quickTools,
  ];

  static const List<ToolRegistryTool> all = <ToolRegistryTool>[
    // Travel Essentials
    ToolRegistryTool(
      toolId: 'distance',
      label: 'Distance',
      icon: Icons.straighten_rounded,
      isEnabled: true,
      lenses: <String>[
        ActivityLensId.travelEssentials,
        ActivityLensId.healthFitness,
      ],
      presetsByLens: <String, Map<String, Object?>>{
        ActivityLensId.travelEssentials: <String, Object?>{
          'pairs': <String>['km_mi'],
        },
        ActivityLensId.healthFitness: <String, Object?>{
          'pairs': <String>['km_mi'],
          'defaults': 'run_walk',
        },
      },
    ),
    ToolRegistryTool(
      toolId: 'speed',
      label: 'Speed',
      icon: Icons.speed_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.travelEssentials],
    ),
    ToolRegistryTool(
      toolId: 'time',
      label: 'Time',
      icon: Icons.schedule_rounded,
      isEnabled: true,
      lenses: <String>[
        ActivityLensId.travelEssentials,
        ActivityLensId.weatherTime,
      ],
    ),
    ToolRegistryTool(
      toolId: 'jet_lag_delta',
      label: 'Jet Lag Delta',
      icon: Icons.airline_seat_recline_normal,
      lenses: <String>[ActivityLensId.travelEssentials],
      presetsByLens: <String, Map<String, Object?>>{
        ActivityLensId.travelEssentials: <String, Object?>{
          'mode': 'delta_only',
        },
      },
    ),
    ToolRegistryTool(
      toolId: 'data_storage',
      label: 'Data Storage',
      icon: Icons.sd_storage_rounded,
      lenses: <String>[ActivityLensId.travelEssentials],
    ),
    ToolRegistryTool(
      toolId: 'temperature',
      label: 'Temperature',
      icon: Icons.thermostat_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.travelEssentials, ActivityLensId.homeDiy],
    ),

    // Food and Cooking
    ToolRegistryTool(
      toolId: 'liquid_volume',
      label: 'Liquid Volume',
      icon: Icons.science_rounded,
      lenses: <String>[ActivityLensId.foodCooking],
      // Enabled via existing baking/liquids tooling; picker maps to those.
      isEnabled: true,
    ),
    ToolRegistryTool(
      toolId: 'weight',
      label: 'Weight',
      icon: Icons.monitor_weight_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.foodCooking],
    ),
    ToolRegistryTool(
      toolId: 'oven_temperature',
      label: 'Oven Temperature',
      icon: Icons.bakery_dining_rounded,
      lenses: <String>[ActivityLensId.foodCooking],
    ),
    ToolRegistryTool(
      toolId: 'cups_grams_estimates',
      label: 'Cups ↔ Grams Estimates',
      icon: Icons.restaurant_menu_rounded,
      lenses: <String>[ActivityLensId.foodCooking],
    ),

    // Health and Fitness
    ToolRegistryTool(
      toolId: 'body_weight',
      label: 'Body Weight',
      icon: Icons.monitor_weight_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.healthFitness],
    ),
    ToolRegistryTool(
      toolId: 'height',
      label: 'Height',
      icon: Icons.height_rounded,
      lenses: <String>[ActivityLensId.healthFitness],
      isEnabled: true,
    ),
    ToolRegistryTool(
      toolId: 'pace',
      label: 'Pace',
      icon: Icons.directions_run_rounded,
      lenses: <String>[ActivityLensId.healthFitness],
    ),
    ToolRegistryTool(
      toolId: 'hydration',
      label: 'Hydration',
      icon: Icons.water_drop_rounded,
      lenses: <String>[ActivityLensId.healthFitness],
    ),
    ToolRegistryTool(
      toolId: 'energy',
      label: 'Calories / Energy',
      icon: Icons.local_fire_department_rounded,
      lenses: <String>[ActivityLensId.healthFitness],
    ),

    // Home and DIY
    ToolRegistryTool(
      toolId: 'length',
      label: 'Length',
      icon: Icons.straighten_rounded,
      lenses: <String>[ActivityLensId.homeDiy],
      isEnabled: true,
    ),
    ToolRegistryTool(
      toolId: 'area',
      label: 'Area',
      icon: Icons.square_foot_rounded,
      lenses: <String>[ActivityLensId.homeDiy],
      isEnabled: true,
    ),
    ToolRegistryTool(
      toolId: 'volume',
      label: 'Volume',
      icon: Icons.local_drink_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.homeDiy],
    ),
    ToolRegistryTool(
      toolId: 'pressure',
      label: 'Pressure',
      icon: Icons.tire_repair_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.homeDiy],
    ),

    // Weather and Time
    ToolRegistryTool(
      toolId: 'weather_summary',
      label: 'Weather Summary',
      icon: Icons.cloud_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.weatherTime],
    ),
    ToolRegistryTool(
      toolId: 'world_clock_delta',
      label: 'World Clock Delta',
      icon: Icons.public_rounded,
      lenses: <String>[ActivityLensId.weatherTime],
    ),

    // Money and Shopping
    ToolRegistryTool(
      toolId: 'currency_convert',
      label: 'Currency',
      icon: Icons.currency_exchange_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.moneyShopping],
    ),
    ToolRegistryTool(
      toolId: 'tip_helper',
      label: 'Tip Helper',
      icon: Icons.percent_rounded,
      lenses: <String>[ActivityLensId.moneyShopping],
    ),
    ToolRegistryTool(
      toolId: 'tax_vat_helper',
      label: 'Sales Tax / VAT Helper',
      icon: Icons.calculate_rounded,
      lenses: <String>[ActivityLensId.moneyShopping],
    ),
    ToolRegistryTool(
      toolId: 'unit_price_helper',
      label: 'Unit Price Helper',
      icon: Icons.local_offer_rounded,
      lenses: <String>[ActivityLensId.moneyShopping],
    ),

    // Quick Tools
    ToolRegistryTool(
      toolId: 'shoe_sizes',
      label: 'Shoe Sizes',
      icon: Icons.directions_walk_rounded,
      isEnabled: true,
      lenses: <String>[ActivityLensId.quickTools, ActivityLensId.oddUseful],
    ),
    ToolRegistryTool(
      toolId: 'clothing_sizes',
      label: 'Clothing Sizes',
      icon: Icons.checkroom_rounded,
      lenses: <String>[ActivityLensId.quickTools, ActivityLensId.oddUseful],
    ),
    ToolRegistryTool(
      toolId: 'paper_sizes',
      label: 'Paper Sizes',
      icon: Icons.description_rounded,
      lenses: <String>[ActivityLensId.quickTools, ActivityLensId.oddUseful],
    ),
    ToolRegistryTool(
      toolId: 'timezone_lookup',
      label: 'Time Zones Lookup',
      icon: Icons.travel_explore_rounded,
      lenses: <String>[ActivityLensId.quickTools, ActivityLensId.oddUseful],
    ),
  ];

  static final Map<String, ToolRegistryTool> byId =
      Map<String, ToolRegistryTool>.unmodifiable({
        for (final t in all) t.toolId: t,
      });

  /// Per-lens tool ordering. Anything not listed falls back to list order.
  static const Map<String, List<String>> toolOrderByLens =
      <String, List<String>>{
        ActivityLensId.travelEssentials: <String>[
          'distance',
          'speed',
          'time',
          'jet_lag_delta',
          'data_storage',
          'temperature',
        ],
        ActivityLensId.foodCooking: <String>[
          'liquid_volume',
          'weight',
          'oven_temperature',
          'cups_grams_estimates',
        ],
        ActivityLensId.healthFitness: <String>[
          'body_weight',
          'height',
          'pace',
          'hydration',
          'energy',
          'distance',
        ],
        ActivityLensId.homeDiy: <String>[
          'length',
          'area',
          'volume',
          'pressure',
          'temperature',
        ],
        ActivityLensId.weatherTime: <String>[
          'weather_summary',
          'world_clock_delta',
          'time',
        ],
        ActivityLensId.moneyShopping: <String>[
          'currency_convert',
          'tip_helper',
          'tax_vat_helper',
          'unit_price_helper',
        ],
        ActivityLensId.quickTools: <String>[
          'shoe_sizes',
          'clothing_sizes',
          'paper_sizes',
          'timezone_lookup',
        ],
      };

  static List<ToolRegistryTool> toolsForLens(String lensId) {
    final tools = all.where((t) => t.lenses.contains(lensId)).toList();
    final order = toolOrderByLens[lensId];
    if (order == null) return tools;

    final indexOf = <String, int>{
      for (var i = 0; i < order.length; i += 1) order[i]: i,
    };

    tools.sort((a, b) {
      final ai = indexOf[a.toolId];
      final bi = indexOf[b.toolId];
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.label.compareTo(b.label);
    });

    return tools;
  }

  /// The Quick Tools surface uses alternate entry points that should not
  /// duplicate tools.
  static const List<String> quickOddButUseful = <String>[
    'shoe_sizes',
    'clothing_sizes',
    'paper_sizes',
    'timezone_lookup',
  ];
}
