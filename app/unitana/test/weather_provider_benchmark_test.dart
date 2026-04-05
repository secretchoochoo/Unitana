import 'package:flutter_test/flutter_test.dart';

import '../tool/weather_provider_benchmark.dart';

void main() {
  group('weather provider benchmark normalization', () {
    test('Open-Meteo fog code maps to fog bucket', () {
      expect(normalizeOpenMeteoBucket(45), WeatherBucket.fog);
      expect(normalizeOpenMeteoBucket(0), WeatherBucket.clear);
      expect(normalizeOpenMeteoBucket(3), WeatherBucket.cloudy);
    });

    test('MET Norway symbol mapping matches expected sky buckets', () {
      expect(normalizeMetNorwayBucket('fair_day'), WeatherBucket.partlyCloudy);
      expect(normalizeMetNorwayBucket('clearsky_day'), WeatherBucket.clear);
      expect(normalizeMetNorwayBucket('fog'), WeatherBucket.fog);
      expect(
        normalizeMetNorwayBucket('heavyrainshowers_day'),
        WeatherBucket.rain,
      );
    });

    test('METAR normalization treats fog and clear correctly', () {
      expect(
        normalizeMetarBucket(
          rawObservation: 'METAR LPPR 050630Z VRB02KT 7000 NSC 07/06 Q1022',
          visibilityKm: 7.0,
          cover: 'NSC',
        ),
        WeatherBucket.clear,
      );

      expect(
        normalizeMetarBucket(
          rawObservation:
              'METAR EGLL 050650Z 00000KT 0200 FG VV001 08/08 Q1021',
          visibilityKm: 0.2,
          cover: 'VV',
        ),
        WeatherBucket.fog,
      );
    });

    test('CAVOK cover maps to clear sky for observation scoring', () {
      expect(normalizeMetarCloudCoverPercent('CAVOK'), 0);
      expect(
        normalizeMetarBucket(
          rawObservation: 'METAR BIRK 050600Z 10002KT CAVOK M06/M11 Q0999',
          visibilityKm: 10.0,
          cover: 'CAVOK',
        ),
        WeatherBucket.clear,
      );
    });

    test('bucket similarity favors close sky states over hard mismatches', () {
      expect(
        scoreBucketSimilarity(WeatherBucket.partlyCloudy, WeatherBucket.clear),
        greaterThan(0.5),
      );
      expect(scoreBucketSimilarity(WeatherBucket.fog, WeatherBucket.clear), 0);
    });

    test(
      'benchmark sampler returns requested count with continent spread',
      () async {
        final sampled = await sampleBenchmarkCitiesFromDataset(
          '/Users/codypritchard/unitana/app/unitana/assets/data/cities_v1.json',
          sampleSize: 12,
          seed: 7,
        );
        expect(sampled, hasLength(12));
        final continents = sampled
            .map((city) => city.continent)
            .whereType<String>()
            .toSet();
        expect(continents.length, greaterThanOrEqualTo(4));
      },
    );

    test('nearest-station chooser prefers closest METAR station', () {
      final chosen = chooseBestStationForCity(
        latitude: 41.15,
        longitude: -8.61,
        stations: const <StationInfo>[
          StationInfo(
            icao: 'FAR1',
            site: 'Far',
            latitude: 42.0,
            longitude: -8.0,
            priority: 1,
          ),
          StationInfo(
            icao: 'NEAR',
            site: 'Near',
            latitude: 41.23,
            longitude: -8.68,
            priority: 3,
          ),
        ],
      );
      expect(chosen?.icao, 'NEAR');
    });

    test('provider priors normalize into weights', () {
      final priors = deriveProviderPriors(<String, ProviderAggregate>{
        'Open-Meteo': const ProviderAggregate(
          provider: 'Open-Meteo',
          sampleCount: 50,
          winCount: 30,
          averageComposite: 0.8,
          averageTemperatureErrorC: 1.2,
          averageWindErrorKmh: 5.0,
          averageCloudErrorPercent: 20.0,
          exactBucketMatchRate: 0.6,
          fogFalsePositives: 1,
          fogFalseNegatives: 0,
        ),
        'MET Norway': const ProviderAggregate(
          provider: 'MET Norway',
          sampleCount: 50,
          winCount: 20,
          averageComposite: 0.7,
          averageTemperatureErrorC: 1.4,
          averageWindErrorKmh: 6.0,
          averageCloudErrorPercent: 25.0,
          exactBucketMatchRate: 0.5,
          fogFalsePositives: 2,
          fogFalseNegatives: 0,
        ),
      });
      final total = priors.values.fold<double>(
        0,
        (sum, item) => sum + item.weight,
      );
      expect(total, closeTo(1.0, 0.0001));
      expect(
        priors['Open-Meteo']!.weight,
        greaterThan(priors['MET Norway']!.weight),
      );
    });
  });
}
