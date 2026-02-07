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
}
