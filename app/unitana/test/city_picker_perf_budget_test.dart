import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/cities.dart';
import 'package:unitana/data/city_picker_engine.dart';
import 'package:unitana/features/dashboard/models/time_zone_catalog.dart';
import 'package:unitana/models/place.dart';

const _dataPath = 'assets/data/cities_v1.json';

const _maxWizardBuildMs = 1500;
const _maxTimeBuildMs = 1500;
const _maxSearchMs = 250;

void main() {
  List<City> loadCities() {
    final decoded =
        jsonDecode(File(_dataPath).readAsStringSync()) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList(growable: false);
  }

  int measureMs(void Function() run) {
    final sw = Stopwatch()..start();
    run();
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  int bestOf3(void Function() run) {
    final runs = <int>[for (var i = 0; i < 3; i++) measureMs(run)]..sort();
    return runs.first;
  }

  test(
    'city picker engine meets baseline perf budgets on canonical dataset',
    () {
      final cities = loadCities();
      expect(cities.length, greaterThan(30000));

      final curatedIds = {for (final city in kCuratedCities) city.id};
      late List<CityPickerEngineEntry<City>> wizardEntries;

      final wizardBuildMs = bestOf3(() {
        wizardEntries = CityPickerEngine.sortByBaseScore(
          CityPickerEngine.buildEntries<City>(
            items: cities,
            keyOf: (c) => c.id,
            cityNameOf: (c) => c.cityName,
            countryCodeOf: (c) => c.countryCode,
            countryNameOf: (c) => c.countryName ?? c.countryCode,
            timeZoneIdOf: (c) => c.timeZoneId,
            isCurated: (c) => curatedIds.contains(c.id),
            mainstreamCountryBonus: 60,
            extraSearchTermsOf: (c) => <String>[
              c.iso3 ?? '',
              c.admin1Name ?? '',
              c.admin1Code ?? '',
              c.continent ?? '',
              CityPickerEngine.continentName(c.continent),
              c.currencyCode,
            ],
          ),
        );
      });

      final defaultTop = CityPickerEngine.topEntries(
        rankedEntries: wizardEntries,
        limit: 24,
        dedupeByTimeZone: true,
        dedupeByCityToken: true,
      );
      expect(defaultTop.length, lessThanOrEqualTo(24));

      final tokyoMs = bestOf3(() {
        final result = CityPickerEngine.searchEntries(
          entries: wizardEntries,
          queryRaw: 'tokyo',
          maxCandidates: 220,
          maxResults: 100,
        );
        expect(result, isNotEmpty);
      });

      const home = Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: true,
      );
      const destination = Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Lisbon',
        countryCode: 'PT',
        timeZoneId: 'Europe/Lisbon',
        unitSystem: 'metric',
        use24h: false,
      );

      final cityOptions = TimeZoneCatalog.cityOptions(
        home: home,
        destination: destination,
      );
      late List<CityPickerEngineEntry<TimeZoneCityOption>> timeEntries;
      final timeBuildMs = bestOf3(() {
        timeEntries = CityPickerEngine.sortByBaseScore(
          CityPickerEngine.buildEntries<TimeZoneCityOption>(
            items: cityOptions,
            keyOf: (o) => o.key,
            cityNameOf: (o) => o.label,
            countryCodeOf: (o) => o.countryCode,
            countryNameOf: (o) => o.countryCode,
            timeZoneIdOf: (o) => o.timeZoneId,
            extraSearchTermsOf: (o) => <String>[o.subtitle],
            mainstreamCountryBonus: 70,
          ),
        );
      });

      final estAliasMs = bestOf3(() {
        final result = CityPickerEngine.searchEntries(
          entries: timeEntries,
          queryRaw: 'EST',
          aliasTimeZoneIds: const {'America/New_York'},
          maxCandidates: 260,
          maxResults: 40,
          shortQueryAllowsTimeZonePrefix: true,
          dedupeByTimeZone: true,
        );
        expect(result.any((e) => e.timeZoneId == 'America/New_York'), isTrue);
      });

      final tzPrefixMs = bestOf3(() {
        final result = CityPickerEngine.searchEntries(
          entries: timeEntries,
          queryRaw: 'asia/tokyo',
          maxCandidates: 260,
          maxResults: 40,
          shortQueryAllowsTimeZonePrefix: true,
          dedupeByTimeZone: true,
        );
        expect(result.any((e) => e.timeZoneId == 'Asia/Tokyo'), isTrue);
      });

      // Keep explicit perf snapshots in test logs for baseline updates.
      // ignore: avoid_print
      print(
        'city-picker-perf '
        'cities=${cities.length} '
        'wizardBuildMs=$wizardBuildMs '
        'timeBuildMs=$timeBuildMs '
        'tokyoMs=$tokyoMs '
        'estAliasMs=$estAliasMs '
        'tzPrefixMs=$tzPrefixMs',
      );

      expect(wizardBuildMs, lessThanOrEqualTo(_maxWizardBuildMs));
      expect(timeBuildMs, lessThanOrEqualTo(_maxTimeBuildMs));
      expect(tokyoMs, lessThanOrEqualTo(_maxSearchMs));
      expect(estAliasMs, lessThanOrEqualTo(_maxSearchMs));
      expect(tzPrefixMs, lessThanOrEqualTo(_maxSearchMs));
    },
  );
}
