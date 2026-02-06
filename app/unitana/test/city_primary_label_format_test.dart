import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/data/cities.dart';

void main() {
  test('primaryLabel prefers admin1Name when available', () {
    const city = City(
      id: 'porto',
      cityName: 'Porto',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      currencyCode: 'EUR',
      admin1Code: '17',
      admin1Name: 'Porto',
    );

    expect(city.primaryLabel, 'Porto, Porto, PT');
  });

  test('primaryLabel suppresses numeric-only admin1Code', () {
    const city = City(
      id: 'porto_code_only',
      cityName: 'Porto',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      currencyCode: 'EUR',
      admin1Code: '17',
    );

    expect(city.primaryLabel, 'Porto, PT');
  });

  test('primaryLabel keeps alpha admin1Code when no admin1Name', () {
    const city = City(
      id: 'denver',
      cityName: 'Denver',
      countryCode: 'US',
      timeZoneId: 'America/Denver',
      currencyCode: 'USD',
      admin1Code: 'CO',
    );

    expect(city.primaryLabel, 'Denver, CO, US');
  });
}
