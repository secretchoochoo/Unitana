import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/time_zone_catalog.dart';
import 'package:unitana/models/place.dart';

void main() {
  test('TimeZoneCatalog includes home/destination and broader options', () {
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
    expect(options.first.label, contains('Home'));
    expect(options[1].id, 'Europe/Lisbon');
    expect(options[1].label, contains('Destination'));
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
    expect(options.first.subtitle, 'Home');
    expect(options[1].timeZoneId, 'Europe/Lisbon');
    expect(options[1].subtitle, 'Destination');
    expect(options.any((o) => o.timeZoneId == 'Asia/Tokyo'), isTrue);
  });
}
