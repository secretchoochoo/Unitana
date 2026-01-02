import 'package:flutter/material.dart';

/// Activity lenses are UI groupings used for discovery, presets, and microcopy.
///
/// They must not create duplicate converters. A lens is a presentation layer,
/// not a new engine.
class ActivityLensId {
  const ActivityLensId._();

  // Canonical lens IDs (stable; used for Keys/persistence/tests).
  static const String travelEssentials = 'travel_essentials';
  static const String foodCooking = 'food_cooking';
  static const String healthFitness = 'health_fitness';
  static const String homeDiy = 'home_diy';
  static const String weatherTime = 'weather_time';
  static const String moneyShopping = 'money_shopping';
  static const String oddUseful = 'odd_useful';

  // Legacy aliases kept to avoid churn if older code paths still reference them.
  // (These should not be used for new code.)
  static const String foodAndCooking = foodCooking;
  static const String healthAndFitness = healthFitness;
  static const String homeAndDiy = homeDiy;
  static const String weatherAndTime = weatherTime;
  static const String money = moneyShopping;

  /// Deprecated surface. Favorites were removed from the picker UX.
  ///
  /// Kept as a stable constant in case older persisted state or tests reference
  /// it; it should not appear in lens ordering.
  static const String favorites = 'favorites';

  /// Deprecated surface. Quick Tools lens was removed from the picker once
  /// “Most Recent” + Search covered the discovery use-case.
  ///
  /// Kept as a stable constant in case older persisted state references it.
  static const String quickTools = 'quick_tools';

  static const List<String> all = <String>[
    travelEssentials,
    foodCooking,
    healthFitness,
    homeDiy,
    weatherTime,
    moneyShopping,
    oddUseful,
  ];
}

@immutable
class ActivityLens {
  final String id;
  final String name;
  final String descriptor;
  final IconData icon;

  const ActivityLens({
    required this.id,
    required this.name,
    required this.descriptor,
    required this.icon,
  });
}

class ActivityLenses {
  const ActivityLenses._();

  /// Returns the lens metadata for a stable lens id, or null if unknown.
  ///
  /// Kept dependency-free for use in widgets/tests.
  static ActivityLens? byId(String id) {
    if (id == ActivityLensId.quickTools) return quickTools;
    for (final lens in all) {
      if (lens.id == id) return lens;
    }
    return null;
  }

  static const ActivityLens travelEssentials = ActivityLens(
    id: ActivityLensId.travelEssentials,
    name: 'Travel Essentials',
    descriptor: 'The core travel decoder ring',
    icon: Icons.flight_takeoff_rounded,
  );

  static const ActivityLens foodCooking = ActivityLens(
    id: ActivityLensId.foodCooking,
    name: 'Food and Cooking',
    descriptor: 'Kitchen conversions and presets',
    icon: Icons.restaurant_rounded,
  );

  static const ActivityLens healthFitness = ActivityLens(
    id: ActivityLensId.healthFitness,
    name: 'Health and Fitness',
    descriptor: 'Training, body metrics, and hydration',
    icon: Icons.fitness_center_rounded,
  );

  static const ActivityLens homeDiy = ActivityLens(
    id: ActivityLensId.homeDiy,
    name: 'Home and DIY',
    descriptor: 'Projects, space, and measurements',
    icon: Icons.handyman_rounded,
  );

  static const ActivityLens weatherTime = ActivityLens(
    id: ActivityLensId.weatherTime,
    name: 'Weather and Time',
    descriptor: 'Conditions, clocks, and deltas',
    icon: Icons.schedule_rounded,
  );

  static const ActivityLens moneyShopping = ActivityLens(
    id: ActivityLensId.moneyShopping,
    name: 'Money and Shopping',
    descriptor: 'Currency, tax, and price comparisons',
    icon: Icons.payments_rounded,
  );

  static const ActivityLens oddUseful = ActivityLens(
    id: ActivityLensId.oddUseful,
    name: 'Odd But Useful',
    descriptor: 'Little lookups that save a trip to the web',
    icon: Icons.auto_fix_high_rounded,
  );

  static const ActivityLens quickTools = ActivityLens(
    id: ActivityLensId.quickTools,
    name: 'Quick Tools',
    descriptor: 'Most recently used tools and shortcuts',
    icon: Icons.star_rounded,
  );

  static const List<ActivityLens> all = <ActivityLens>[
    travelEssentials,
    foodCooking,
    healthFitness,
    homeDiy,
    weatherTime,
    moneyShopping,
    oddUseful,
  ];
}
