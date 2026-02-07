import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/cities.dart';
import 'package:unitana/data/city_picker_engine.dart';

class _Row {
  final String id;
  final String city;
  final String countryCode;
  final String countryName;
  final String timeZoneId;

  const _Row({
    required this.id,
    required this.city,
    required this.countryCode,
    required this.countryName,
    required this.timeZoneId,
  });
}

void main() {
  List<CityPickerEngineEntry<_Row>> buildRows(List<_Row> rows) {
    return CityPickerEngine.sortByBaseScore(
      CityPickerEngine.buildEntries<_Row>(
        items: rows,
        keyOf: (r) => r.id,
        cityNameOf: (r) => r.city,
        countryCodeOf: (r) => r.countryCode,
        countryNameOf: (r) => r.countryName,
        timeZoneIdOf: (r) => r.timeZoneId,
        mainstreamCountryBonus: 0,
      ),
    );
  }

  test('search prefers exact city-name match over loose prefix variants', () {
    final entries = buildRows(const [
      _Row(
        id: 'springfield-us',
        city: 'Springfield',
        countryCode: 'US',
        countryName: 'United States',
        timeZoneId: 'America/Chicago',
      ),
      _Row(
        id: 'springfield-gardens-us',
        city: 'Springfield Gardens',
        countryCode: 'US',
        countryName: 'United States',
        timeZoneId: 'America/New_York',
      ),
    ]);

    final results = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: 'springfield',
      dedupeByTimeZone: false,
    );

    expect(results, isNotEmpty);
    expect(results.first.key, 'springfield-us');
  });

  test('search can dedupe duplicate-feeling same city+country rows', () {
    final entries = buildRows(const [
      _Row(
        id: 'santiago-cl-america-santiago',
        city: 'Santiago',
        countryCode: 'CL',
        countryName: 'Chile',
        timeZoneId: 'America/Santiago',
      ),
      _Row(
        id: 'santiago-cl-alt-zone',
        city: 'Santiago',
        countryCode: 'CL',
        countryName: 'Chile',
        timeZoneId: 'Etc/GMT+4',
      ),
      _Row(
        id: 'santiago-do-america-santo-domingo',
        city: 'Santiago',
        countryCode: 'DO',
        countryName: 'Dominican Republic',
        timeZoneId: 'America/Santo_Domingo',
      ),
    ]);

    final results = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: 'santiago',
      dedupeByTimeZone: false,
      dedupeByCityCountry: true,
    );

    final keys = results.map((e) => e.key).toList(growable: false);
    expect(keys, isNot(contains('santiago-cl-alt-zone')));
    expect(keys, contains('santiago-cl-america-santiago'));
    expect(keys, contains('santiago-do-america-santo-domingo'));
  });

  test('city-name matches outrank timezone-only matches for city queries', () {
    final entries = buildRows(const [
      _Row(
        id: 'london-gb',
        city: 'London',
        countryCode: 'GB',
        countryName: 'United Kingdom',
        timeZoneId: 'Europe/London',
      ),
      _Row(
        id: 'new-london-us',
        city: 'New London',
        countryCode: 'US',
        countryName: 'United States',
        timeZoneId: 'America/New_York',
      ),
      _Row(
        id: 'ayr-gb',
        city: 'Ayr',
        countryCode: 'GB',
        countryName: 'United Kingdom',
        timeZoneId: 'Europe/London',
      ),
    ]);

    final results = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: 'london',
      dedupeByTimeZone: false,
      dedupeByCityCountry: false,
    );

    final keys = results.map((r) => r.key).toList(growable: false);
    expect(keys, containsAll(<String>['london-gb', 'new-london-us', 'ayr-gb']));
    expect(keys.indexOf('london-gb'), lessThan(keys.indexOf('ayr-gb')));
    expect(keys.indexOf('new-london-us'), lessThan(keys.indexOf('ayr-gb')));
  });

  test('real dataset ambiguity keeps alternatives and honors country hint', () {
    final decoded =
        jsonDecode(File('assets/data/cities_v1.json').readAsStringSync())
            as List<dynamic>;
    final cities = decoded
        .whereType<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList(growable: false);
    expect(cities.length, greaterThan(30000));

    final entries = CityPickerEngine.sortByBaseScore(
      CityPickerEngine.buildEntries<City>(
        items: cities,
        keyOf: (c) => c.id,
        cityNameOf: (c) => c.cityName,
        countryCodeOf: (c) => c.countryCode,
        countryNameOf: (c) => c.countryName ?? c.countryCode,
        timeZoneIdOf: (c) => c.timeZoneId,
        mainstreamCountryBonus: 60,
      ),
    );

    final plain = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: 'santiago',
      dedupeByCityCountry: true,
      maxResults: 40,
    );
    final plainCountryCodes = plain
        .map((e) => e.countryCode)
        .where((cc) => cc.isNotEmpty)
        .toSet();
    expect(plainCountryCodes, contains('CL'));
    expect(plainCountryCodes.length, greaterThan(1));

    final withCountryHint = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: 'santiago cl',
      dedupeByCityCountry: true,
      maxResults: 20,
    );
    expect(withCountryHint, isNotEmpty);
    expect(withCountryHint.first.countryCode, 'CL');
  });

  test(
    'ambiguity v3 families honor exact city/country and mainstream zone',
    () {
      final decoded =
          jsonDecode(File('assets/data/cities_v1.json').readAsStringSync())
              as List<dynamic>;
      final cities = decoded
          .whereType<Map<String, dynamic>>()
          .map(City.fromJson)
          .toList(growable: false);

      final entries = CityPickerEngine.sortByBaseScore(
        CityPickerEngine.buildEntries<City>(
          items: cities,
          keyOf: (c) => c.id,
          cityNameOf: (c) => c.cityName,
          countryCodeOf: (c) => c.countryCode,
          countryNameOf: (c) => c.countryName ?? c.countryCode,
          timeZoneIdOf: (c) => c.timeZoneId,
          mainstreamCountryBonus: 60,
        ),
      );

      final sanJose = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'san jose',
        dedupeByCityCountry: true,
        maxResults: 12,
      );
      expect(sanJose, isNotEmpty);
      expect(sanJose.first.cityNameNorm, 'san jose');
      expect(
        sanJose.take(3).every((r) => r.cityNameNorm.contains('san jose')),
        isTrue,
      );

      final sanJoseCr = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'san jose cr',
        dedupeByCityCountry: true,
        maxResults: 12,
      );
      expect(sanJoseCr, isNotEmpty);
      expect(sanJoseCr.first.countryCode, 'CR');

      final london = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'london',
        dedupeByCityCountry: true,
        maxResults: 16,
      );
      expect(london, isNotEmpty);
      expect(london.first.cityNameNorm, 'london');
      expect(london.first.countryCode, 'GB');

      final londonCa = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'london ca',
        dedupeByCityCountry: true,
        maxResults: 12,
      );
      expect(londonCa, isNotEmpty);
      expect(londonCa.first.countryCode, 'CA');

      final vancouver = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'vancouver',
        dedupeByCityCountry: true,
        maxResults: 12,
      );
      expect(vancouver, isNotEmpty);
      expect(vancouver.first.cityNameNorm, 'vancouver');
      expect(vancouver.first.countryCode, 'CA');

      final portland = CityPickerEngine.searchEntries(
        entries: entries,
        queryRaw: 'portland',
        dedupeByCityCountry: true,
        maxResults: 12,
      );
      expect(portland, isNotEmpty);
      expect(portland.first.cityNameNorm, 'portland');
      expect(portland.first.countryCode, 'US');
      expect(portland.first.timeZoneId, 'America/Los_Angeles');
    },
  );
}
