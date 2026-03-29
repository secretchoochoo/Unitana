import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/cities.dart';
import 'package:unitana/data/city_label_utils.dart';

void main() {
  test('cleanCityName removes noisy leading punctuation', () {
    expect(CityLabelUtils.cleanCityName("'Ādamatā"), 'Ādamatā');
    expect(CityLabelUtils.cleanCityName('  ...Chicago'), 'Chicago');
  });

  test('cleanCityName title-cases all-caps labels', () {
    expect(CityLabelUtils.cleanCityName('NEW YORK'), 'New York');
  });

  test('cleanTimeZoneLabel replaces underscores in IANA labels', () {
    expect(
      CityLabelUtils.cleanTimeZoneLabel('America/New_York'),
      'America/New York',
    );
    expect(
      CityLabelUtils.cleanTimeZoneLabel('America/Port_of_Spain'),
      'America/Port of Spain',
    );
    expect(CityLabelUtils.cleanTimeZoneLabel('UTC'), 'UTC');
  });

  test('City.secondaryLabel uses cleaned timezone labels', () {
    const city = City(
      id: 'new_york_us',
      cityName: 'New York',
      countryCode: 'US',
      timeZoneId: 'America/New_York',
      currencyCode: 'USD',
      lat: 40.7128,
      lon: -74.0060,
    );

    expect(city.secondaryLabel, 'America/New York · \$ USD');
  });
}
