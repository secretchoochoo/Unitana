import 'package:flutter/material.dart';

/// Activity lenses are UI groupings used for discovery, presets, and microcopy.
///
/// They must not create duplicate converters. A lens is a presentation layer,
/// not a new engine.
class ActivityLensId {
  const ActivityLensId._();

  static const String travelEssentials = 'travel_essentials';
  static const String foodCooking = 'food_cooking';
  static const String healthFitness = 'health_fitness';
  static const String homeDiy = 'home_diy';
  static const String weatherTime = 'weather_time';
  static const String moneyShopping = 'money_shopping';
  static const String quickTools = 'quick_tools';

  /// Back-compat aliases (internal only).
  static const String foodAndCooking = foodCooking;
  static const String healthAndFitness = healthFitness;
  static const String homeAndDiy = homeDiy;
  static const String money = moneyShopping;
  static const String weatherAndTime = weatherTime;
  static const String favorites = quickTools;

  static const List<String> all = <String>[
    travelEssentials,
    foodCooking,
    healthFitness,
    homeDiy,
    weatherTime,
    moneyShopping,
    quickTools,
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
    descriptor: 'Training and body metrics',
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
    descriptor: 'Conditions, clocks, and wind',
    icon: Icons.schedule_rounded,
  );

  static const ActivityLens moneyShopping = ActivityLens(
    id: ActivityLensId.moneyShopping,
    name: 'Money and Shopping',
    descriptor: 'Currency and price comparisons',
    icon: Icons.payments_rounded,
  );

  static const ActivityLens quickTools = ActivityLens(
    id: ActivityLensId.quickTools,
    name: 'Quick Tools',
    descriptor: 'Favorites, recents, and tables',
    icon: Icons.star_rounded,
  );

  static const List<ActivityLens> all = <ActivityLens>[
    travelEssentials,
    foodCooking,
    healthFitness,
    homeDiy,
    weatherTime,
    moneyShopping,
    quickTools,
  ];
}
