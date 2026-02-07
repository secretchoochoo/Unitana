import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/time_zone_catalog.dart';
import 'package:unitana/models/place.dart';

void main() {
  test('TimeZoneCatalog includes seeded cities and broader options', () {
    const home = Place(
      id: 'home',
      type: PlaceType.living,
      name: 'Home',
      cityName: 'Denver',
      countryCode: 'US',
      timeZoneId: 'America/Denver',
      unitSystem: 'imperial',
      use24h: false,
    );
    const destination = Place(
      id: 'dest',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: 'Lisbon',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    );

    final options = TimeZoneCatalog.options(
      home: home,
      destination: destination,
    );

    expect(options, isNotEmpty);
    expect(options.first.id, 'America/Denver');
    expect(options.first.label, 'Denver, US');
    expect(options[1].id, 'Europe/Lisbon');
    expect(options[1].label, 'Lisbon, PT');
    expect(options.any((o) => o.id == 'Asia/Tokyo'), isTrue);
    expect(options.any((o) => o.id == 'UTC'), isTrue);
  });

  test('TimeZoneCatalog provides city-first picker options', () {
    const home = Place(
      id: 'home',
      type: PlaceType.living,
      name: 'Home',
      cityName: 'Denver',
      countryCode: 'US',
      timeZoneId: 'America/Denver',
      unitSystem: 'imperial',
      use24h: false,
    );
    const destination = Place(
      id: 'dest',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: 'Lisbon',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    );

    final options = TimeZoneCatalog.cityOptions(
      home: home,
      destination: destination,
    );

    expect(options, isNotEmpty);
    expect(options.first.timeZoneId, 'America/Denver');
    expect(options.first.subtitle, 'America/Denver');
    expect(options[1].timeZoneId, 'Europe/Lisbon');
    expect(options[1].subtitle, 'Europe/Lisbon');
    expect(options.any((o) => o.timeZoneId == 'Asia/Tokyo'), isTrue);
  });

  test('TimeZoneCatalog mainstream defaults prioritize seeded + hubs', () {
    const home = Place(
      id: 'home',
      type: PlaceType.living,
      name: 'Home',
      cityName: 'Denver',
      countryCode: 'US',
      timeZoneId: 'America/Denver',
      unitSystem: 'imperial',
      use24h: false,
    );
    const destination = Place(
      id: 'dest',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: 'Lisbon',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    );

    final featured = TimeZoneCatalog.mainstreamCityOptions(
      home: home,
      destination: destination,
      limit: 18,
    );
    final topZoneIds = featured.take(8).map((o) => o.timeZoneId).toList();

    expect(featured, isNotEmpty);
    expect(featured.first.timeZoneId, 'America/Denver');
    expect(featured[1].timeZoneId, 'Europe/Lisbon');
    expect(topZoneIds, contains('America/New_York'));
    expect(topZoneIds, contains('America/Los_Angeles'));
    expect(topZoneIds, contains('Europe/London'));
    expect(topZoneIds, contains('Asia/Tokyo'));
    expect(
      featured.take(12).any((o) => RegExp(r'^[^A-Za-z0-9]').hasMatch(o.label)),
      isFalse,
    );
  });
}
