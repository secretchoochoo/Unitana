import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/city_picker_engine.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/time_zone_catalog.dart';
import 'package:unitana/features/dashboard/models/tool_time_helpers.dart';
import 'package:unitana/models/place.dart';

void main() {
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

  test('resolveTimeToolDefaults respects saved selection and reality', () {
    final options = TimeZoneCatalog.options(
      home: home,
      destination: destination,
    );

    final saved = resolveTimeToolDefaults(
      options: options,
      home: home,
      destination: destination,
      reality: DashboardReality.home,
      savedSelection: const TimeZoneWidgetSelection(
        fromZoneId: 'Asia/Tokyo',
        toZoneId: 'Europe/Lisbon',
      ),
      isJetLagTool: false,
    );
    final destinationReality = resolveTimeToolDefaults(
      options: options,
      home: home,
      destination: destination,
      reality: DashboardReality.destination,
      savedSelection: null,
      isJetLagTool: false,
    );
    final jetLag = resolveTimeToolDefaults(
      options: options,
      home: home,
      destination: destination,
      reality: DashboardReality.destination,
      savedSelection: null,
      isJetLagTool: true,
    );

    expect(saved.fromZoneId, 'Asia/Tokyo');
    expect(saved.toZoneId, 'Europe/Lisbon');
    expect(destinationReality.fromZoneId, 'Europe/Lisbon');
    expect(destinationReality.toZoneId, 'America/Denver');
    expect(jetLag.fromZoneId, 'America/Denver');
    expect(jetLag.toZoneId, 'Europe/Lisbon');
  });

  test('time helpers parse, format, rebase, and convert local times', () {
    final parsed = parseLocalDateTime('2026-06-01 12:00');
    final invalid = parseLocalDateTime('2026-99-99 99:99');
    final rebased = rebaseTimeConverterInput(
      rawInput: '2026-06-01 12:00',
      oldFromZoneId: 'America/Denver',
      newFromZoneId: 'Europe/Lisbon',
    );
    final converted = convertTimeZoneInput(
      rawInput: '2026-06-01 12:00',
      fromZoneId: 'America/Denver',
      toZoneId: 'Europe/Lisbon',
      use24h: true,
    );

    expect(parsed, isNotNull);
    expect(formatLocalDateTime(parsed!), '2026-06-01 12:00');
    expect(invalid, isNull);
    expect(rebased, isNotNull);
    expect(rebased, isNot('2026-06-01 12:00'));
    expect(converted, isNotNull);
    expect(converted!.inputLabel, '2026-06-01 12:00');
    expect(converted.outputLabel, startsWith('2026-06-01 '));
  });

  test('time picker helpers support alias and city-first search', () {
    final zoneOptions = TimeZoneCatalog.options(
      home: home,
      destination: destination,
    );
    final cityOptions = TimeZoneCatalog.cityOptions(
      home: home,
      destination: destination,
    );
    final featuredCityOptions = featuredTimeZoneCityOptions(
      cityOptions: cityOptions,
      home: home,
      destination: destination,
    );
    final allCityEntries = CityPickerEngine.sortByBaseScore(
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
    final cityEntryByKey = <String, CityPickerEngineEntry<TimeZoneCityOption>>{
      for (final entry in allCityEntries) entry.key: entry,
    };
    final featuredCityEntries = featuredCityOptions
        .map((o) => cityEntryByKey[o.key])
        .whereType<CityPickerEngineEntry<TimeZoneCityOption>>()
        .toList(growable: false);
    final zoneEntries = CityPickerEngine.sortByBaseScore(
      CityPickerEngine.buildEntries<TimeZoneOption>(
        items: zoneOptions,
        keyOf: (o) => o.id,
        cityNameOf: (o) => o.label,
        countryCodeOf: (_) => '',
        countryNameOf: (_) => '',
        timeZoneIdOf: (o) => o.id,
        extraSearchTermsOf: (o) => <String>[o.subtitle ?? '', o.id],
        mainstreamCountryBonus: 0,
      ),
    );

    final aliasMatches = aliasZonesForQuery('EST');
    final cityMatches = searchTimeZoneCityOptions(
      rawQuery: 'tokyo',
      featured: featuredCityOptions,
      allEntries: allCityEntries,
      featuredEntries: featuredCityEntries,
      home: home,
      destination: destination,
    );
    final zoneMatches = searchTimeZoneOptions(
      rawQuery: 'asia/tokyo',
      entries: zoneEntries,
      home: home,
      destination: destination,
    );

    expect(aliasMatches, contains('America/New_York'));
    expect(cityMatches.any((o) => o.timeZoneId == 'Asia/Tokyo'), isTrue);
    expect(zoneMatches.any((o) => o.id == 'Asia/Tokyo'), isTrue);
  });
}
