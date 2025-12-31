import 'package:flutter/material.dart';

/// Activity lenses are UI groupings used for discovery, presets, and microcopy.
///
/// They must not create duplicate converters. A lens is a presentation layer,
/// not a new engine.
class ActivityLensId {
  const ActivityLensId._();

  static const String travelEssentials = 'travel_essentials';
  static const String foodAndCooking = 'food_and_cooking';
  static const String healthAndFitness = 'health_and_fitness';
  static const String homeAndDiy = 'home_and_diy';
  static const String money = 'money';
  static const String weatherAndTime = 'weather_and_time';
  static const String favorites = 'favorites';

  static const List<String> all = <String>[
    travelEssentials,
    foodAndCooking,
    healthAndFitness,
    homeAndDiy,
    money,
    weatherAndTime,
    favorites,
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

  static const ActivityLens foodAndCooking = ActivityLens(
    id: ActivityLensId.foodAndCooking,
    name: 'Food and Cooking',
    descriptor: 'Kitchen conversions and presets',
    icon: Icons.restaurant_rounded,
  );

  static const ActivityLens healthAndFitness = ActivityLens(
    id: ActivityLensId.healthAndFitness,
    name: 'Health and Fitness',
    descriptor: 'Training and body metrics',
    icon: Icons.directions_run_rounded,
  );

  static const ActivityLens homeAndDiy = ActivityLens(
    id: ActivityLensId.homeAndDiy,
    name: 'Home and DIY',
    descriptor: 'Projects, space, and measurements',
    icon: Icons.handyman_rounded,
  );

  static const ActivityLens money = ActivityLens(
    id: ActivityLensId.money,
    name: 'Money',
    descriptor: 'Currency and price comparisons',
    icon: Icons.payments_rounded,
  );

  static const ActivityLens weatherAndTime = ActivityLens(
    id: ActivityLensId.weatherAndTime,
    name: 'Weather and Time',
    descriptor: 'Conditions, clocks, and wind',
    icon: Icons.cloud_queue_rounded,
  );

  static const ActivityLens favorites = ActivityLens(
    id: ActivityLensId.favorites,
    name: 'Favorites',
    descriptor: 'Pinned tools you use most',
    icon: Icons.star_rounded,
  );

  static const List<ActivityLens> all = <ActivityLens>[
    travelEssentials,
    foodAndCooking,
    healthAndFitness,
    homeAndDiy,
    money,
    weatherAndTime,
    favorites,
  ];
}
