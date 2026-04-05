import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

enum WeatherBucket {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  rain,
  snow,
  storm,
  unknown,
}

extension WeatherBucketLabel on WeatherBucket {
  String get label => switch (this) {
    WeatherBucket.clear => 'Clear',
    WeatherBucket.partlyCloudy => 'Partly cloudy',
    WeatherBucket.cloudy => 'Cloudy',
    WeatherBucket.fog => 'Fog / low visibility',
    WeatherBucket.rain => 'Rain',
    WeatherBucket.snow => 'Snow',
    WeatherBucket.storm => 'Storm',
    WeatherBucket.unknown => 'Unknown',
  };
}

class BenchmarkCity {
  const BenchmarkCity({
    required this.id,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.icao,
    this.continent,
    this.stationSource,
  });

  final String id;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String? icao;
  final String? continent;
  final String? stationSource;

  factory BenchmarkCity.fromJson(Map<String, dynamic> json) {
    return BenchmarkCity(
      id: json['id'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      icao: json['icao'] as String?,
      continent: json['continent'] as String?,
      stationSource: json['stationSource'] as String?,
    );
  }

  String get label => '$city, $country';

  BenchmarkCity copyWith({String? icao, String? stationSource}) {
    return BenchmarkCity(
      id: id,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      icao: icao ?? this.icao,
      continent: continent,
      stationSource: stationSource ?? this.stationSource,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'icao': icao,
      'continent': continent,
      'stationSource': stationSource,
    };
  }
}

class DatasetCity {
  const DatasetCity({
    required this.id,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.continent,
  });

  final String id;
  final String city;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String continent;

  factory DatasetCity.fromJson(Map<String, dynamic> json) {
    return DatasetCity(
      id: json['id'] as String,
      city: json['cityName'] as String,
      country:
          (json['countryName'] as String?) ?? (json['countryCode'] as String),
      countryCode: json['countryCode'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      continent: ((json['continent'] as String?) ?? 'unknown').toUpperCase(),
    );
  }

  BenchmarkCity toBenchmarkCity() {
    return BenchmarkCity(
      id: id,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      continent: continent,
    );
  }
}

class StationInfo {
  const StationInfo({
    required this.icao,
    required this.site,
    required this.latitude,
    required this.longitude,
    this.priority,
  });

  final String icao;
  final String site;
  final double latitude;
  final double longitude;
  final int? priority;

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      icao: (json['icaoId'] as String?) ?? (json['id'] as String),
      site: (json['site'] as String?) ?? '',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      priority: (json['priority'] as num?)?.toInt(),
    );
  }
}

class ProviderSnapshot {
  const ProviderSnapshot({
    required this.provider,
    required this.sampledAtUtc,
    required this.bucket,
    required this.summary,
    this.temperatureC,
    this.windKmh,
    this.cloudCoverPercent,
    this.visibilityKm,
    this.raw,
  });

  final String provider;
  final DateTime sampledAtUtc;
  final WeatherBucket bucket;
  final String summary;
  final double? temperatureC;
  final double? windKmh;
  final double? cloudCoverPercent;
  final double? visibilityKm;
  final String? raw;

  bool get isError => summary.startsWith('ERROR:');

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'sampledAtUtc': sampledAtUtc.toIso8601String(),
      'bucket': bucket.name,
      'summary': summary,
      'temperatureC': temperatureC,
      'windKmh': windKmh,
      'cloudCoverPercent': cloudCoverPercent,
      'visibilityKm': visibilityKm,
      'raw': raw,
    };
  }
}

class ProviderScore {
  const ProviderScore({
    required this.provider,
    required this.composite,
    required this.bucketSimilarity,
    this.temperatureErrorC,
    this.windErrorKmh,
    this.cloudErrorPercent,
  });

  final String provider;
  final double composite;
  final double bucketSimilarity;
  final double? temperatureErrorC;
  final double? windErrorKmh;
  final double? cloudErrorPercent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'composite': composite,
      'bucketSimilarity': bucketSimilarity,
      'temperatureErrorC': temperatureErrorC,
      'windErrorKmh': windErrorKmh,
      'cloudErrorPercent': cloudErrorPercent,
    };
  }
}

class ProviderAggregate {
  const ProviderAggregate({
    required this.provider,
    required this.sampleCount,
    required this.winCount,
    required this.averageComposite,
    required this.averageTemperatureErrorC,
    required this.averageWindErrorKmh,
    required this.averageCloudErrorPercent,
    required this.exactBucketMatchRate,
    required this.fogFalsePositives,
    required this.fogFalseNegatives,
  });

  final String provider;
  final int sampleCount;
  final int winCount;
  final double averageComposite;
  final double? averageTemperatureErrorC;
  final double? averageWindErrorKmh;
  final double? averageCloudErrorPercent;
  final double exactBucketMatchRate;
  final int fogFalsePositives;
  final int fogFalseNegatives;
}

class ProviderPrior {
  const ProviderPrior({
    required this.provider,
    required this.weight,
    required this.rawScore,
  });

  final String provider;
  final double weight;
  final double rawScore;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'weight': weight,
      'rawScore': rawScore,
    };
  }
}

class CityBenchmarkResult {
  const CityBenchmarkResult({
    required this.city,
    required this.observation,
    required this.providers,
    required this.scores,
  });

  final BenchmarkCity city;
  final ProviderSnapshot? observation;
  final Map<String, ProviderSnapshot> providers;
  final Map<String, ProviderScore> scores;

  String? get winner {
    if (scores.isEmpty) return null;
    final ordered = scores.values.toList()
      ..sort((a, b) => b.composite.compareTo(a.composite));
    return ordered.first.provider;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'city': city.toJson(),
      'observation': observation?.toJson(),
      'providers': providers.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
      ),
      'scores': scores.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
      ),
      'winner': winner,
    };
  }
}

class BenchmarkConfig {
  const BenchmarkConfig({
    required this.citiesPath,
    required this.datasetCitiesPath,
    required this.stationCachePath,
    required this.referenceTimeUtc,
    required this.timeout,
    this.outputMarkdownPath,
    this.outputJsonPath,
    this.cityFilter,
    this.limit,
    this.sampleSize,
    this.sampleSeed = 42,
  });

  final String citiesPath;
  final String datasetCitiesPath;
  final String stationCachePath;
  final DateTime referenceTimeUtc;
  final Duration timeout;
  final String? outputMarkdownPath;
  final String? outputJsonPath;
  final String? cityFilter;
  final int? limit;
  final int? sampleSize;
  final int sampleSeed;

  bool get usesExpandedSampling => sampleSize != null;

  static BenchmarkConfig parse(List<String> args) {
    String citiesPath = 'tool/fixtures/weather_benchmark_cities.json';
    String datasetCitiesPath = 'assets/data/cities_v1.json';
    String stationCachePath = '../tmp/weather_station_cache.json';
    String? outputMarkdownPath;
    String? outputJsonPath;
    String? cityFilter;
    int? limit;
    int? sampleSize;
    var sampleSeed = 42;
    var timeoutSeconds = 20;
    DateTime referenceTimeUtc = DateTime.now().toUtc();

    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      switch (arg) {
        case '--cities':
          citiesPath = args[++i];
        case '--dataset-cities':
          datasetCitiesPath = args[++i];
        case '--station-cache':
          stationCachePath = args[++i];
        case '--output':
          outputMarkdownPath = args[++i];
        case '--json-output':
          outputJsonPath = args[++i];
        case '--city':
          cityFilter = args[++i];
        case '--limit':
          limit = int.parse(args[++i]);
        case '--sample-size':
          sampleSize = int.parse(args[++i]);
        case '--sample-seed':
          sampleSeed = int.parse(args[++i]);
        case '--timeout-seconds':
          timeoutSeconds = int.parse(args[++i]);
        case '--at':
          referenceTimeUtc = DateTime.parse(args[++i]).toUtc();
        case '--help':
          _printUsageAndExit();
      }
    }

    return BenchmarkConfig(
      citiesPath: citiesPath,
      datasetCitiesPath: datasetCitiesPath,
      stationCachePath: stationCachePath,
      referenceTimeUtc: referenceTimeUtc,
      timeout: Duration(seconds: timeoutSeconds),
      outputMarkdownPath: outputMarkdownPath,
      outputJsonPath: outputJsonPath,
      cityFilter: cityFilter,
      limit: limit,
      sampleSize: sampleSize,
      sampleSeed: sampleSeed,
    );
  }

  static Never _printUsageAndExit() {
    stdout.writeln('''
Usage: dart run tool/weather_provider_benchmark.dart [options]

Options:
  --cities <path>          Curated benchmark fixture path
  --dataset-cities <path>  Full city dataset path for auto-sampling
  --station-cache <path>   JSON cache for nearest METAR station lookups
  --output <path>          Write markdown report to path
  --json-output <path>     Write raw JSON results to path
  --city <name-or-id>      Filter to one city/id substring
  --limit <n>              Limit selected cities
  --sample-size <n>        Sample n cities from the full dataset instead of the curated fixture
  --sample-seed <n>        Deterministic seed for dataset sampling (default: 42)
  --timeout-seconds <n>    Per-request timeout (default: 20)
  --at <iso8601>           Reference time in UTC or with offset
  --help                   Show this message
''');
    exit(0);
  }
}

Future<void> main(List<String> args) async {
  final config = BenchmarkConfig.parse(args);
  final client = http.Client();
  try {
    final preparedCities = await prepareBenchmarkCities(
      client: client,
      config: config,
    );
    final selected = _selectCities(
      preparedCities,
      cityFilter: config.cityFilter,
      limit: config.limit,
    );

    if (selected.isEmpty) {
      stderr.writeln('No benchmark cities matched the requested filter.');
      exitCode = 2;
      return;
    }

    final results = await runWeatherProviderBenchmark(
      client: client,
      cities: selected,
      referenceTimeUtc: config.referenceTimeUtc,
      timeout: config.timeout,
    );
    final aggregates = aggregateProviderScores(results);
    final priors = deriveProviderPriors(aggregates);
    final markdown = renderBenchmarkMarkdown(
      config: config,
      results: results,
      priors: priors,
    );
    final jsonOutput = jsonEncode(<String, dynamic>{
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'referenceTimeUtc': config.referenceTimeUtc.toIso8601String(),
      'cities': selected.length,
      'mode': config.usesExpandedSampling ? 'expanded-sample' : 'fixture',
      'providerPriors': priors.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
      ),
      'results': results.map((r) => r.toJson()).toList(),
    });

    if (config.outputMarkdownPath != null) {
      final file = File(config.outputMarkdownPath!);
      await file.parent.create(recursive: true);
      await file.writeAsString(markdown);
      stdout.writeln('Wrote markdown report to ${file.path}');
    } else {
      stdout.writeln(markdown);
    }

    if (config.outputJsonPath != null) {
      final file = File(config.outputJsonPath!);
      await file.parent.create(recursive: true);
      await file.writeAsString('$jsonOutput\n');
      stdout.writeln('Wrote JSON report to ${file.path}');
    }
  } finally {
    client.close();
  }
}

Future<List<BenchmarkCity>> prepareBenchmarkCities({
  required http.Client client,
  required BenchmarkConfig config,
}) async {
  final baseCities = config.usesExpandedSampling
      ? await sampleBenchmarkCitiesFromDataset(
          config.datasetCitiesPath,
          sampleSize: config.sampleSize!,
          seed: config.sampleSeed,
        )
      : await loadBenchmarkCities(config.citiesPath);
  return resolveObservationStations(
    client: client,
    cities: baseCities,
    cachePath: config.stationCachePath,
    timeout: config.timeout,
  );
}

Future<List<BenchmarkCity>> loadBenchmarkCities(String path) async {
  final raw = await File(path).readAsString();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .cast<Map<String, dynamic>>()
      .map(BenchmarkCity.fromJson)
      .toList(growable: false);
}

Future<List<DatasetCity>> loadDatasetCities(String path) async {
  final raw = await File(path).readAsString();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .cast<Map<String, dynamic>>()
      .map(DatasetCity.fromJson)
      .where(
        (city) => city.city.trim().isNotEmpty && city.country.trim().isNotEmpty,
      )
      .toList(growable: false);
}

Future<List<BenchmarkCity>> sampleBenchmarkCitiesFromDataset(
  String datasetPath, {
  required int sampleSize,
  required int seed,
}) async {
  final dataset = await loadDatasetCities(datasetPath);
  final unique = <String>{};
  final buckets = <String, List<DatasetCity>>{};
  for (final city in dataset) {
    final key =
        '${city.city.toLowerCase()}|${city.countryCode.toLowerCase()}|${city.continent}';
    if (!unique.add(key)) continue;
    buckets.putIfAbsent(city.continent, () => <DatasetCity>[]).add(city);
  }

  final random = math.Random(seed);
  for (final list in buckets.values) {
    list.shuffle(random);
  }

  final continents = buckets.keys.toList()..sort();
  final sampled = <BenchmarkCity>[];
  final usedCountries = <String, int>{};

  while (sampled.length < sampleSize) {
    var addedThisRound = false;
    for (final continent in continents) {
      final list = buckets[continent];
      if (list == null || list.isEmpty) continue;
      final nextIndex = list.indexWhere(
        (city) => (usedCountries[city.countryCode] ?? 0) < 2,
      );
      final DatasetCity chosen;
      if (nextIndex >= 0) {
        chosen = list.removeAt(nextIndex);
      } else {
        chosen = list.removeAt(0);
      }
      sampled.add(chosen.toBenchmarkCity());
      usedCountries.update(
        chosen.countryCode,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      addedThisRound = true;
      if (sampled.length >= sampleSize) break;
    }
    if (!addedThisRound) break;
  }

  return sampled;
}

List<BenchmarkCity> _selectCities(
  List<BenchmarkCity> cities, {
  String? cityFilter,
  int? limit,
}) {
  Iterable<BenchmarkCity> result = cities;
  final filter = cityFilter?.trim().toLowerCase();
  if (filter != null && filter.isNotEmpty) {
    result = result.where((city) {
      final haystack =
          '${city.id} ${city.city} ${city.country} ${city.icao ?? ''}'
              .toLowerCase();
      return haystack.contains(filter);
    });
  }
  if (limit != null && limit >= 0) {
    result = result.take(limit);
  }
  return result.toList(growable: false);
}

Future<List<BenchmarkCity>> resolveObservationStations({
  required http.Client client,
  required List<BenchmarkCity> cities,
  required String cachePath,
  required Duration timeout,
}) async {
  final cache = await _loadStationCache(cachePath);
  final resolved = <BenchmarkCity>[];
  var dirty = false;
  for (final city in cities) {
    if (city.icao != null && city.icao!.trim().isNotEmpty) {
      resolved.add(city);
      continue;
    }
    final cached = cache[city.id];
    if (cached is Map<String, dynamic>) {
      resolved.add(
        city.copyWith(
          icao: cached['icao'] as String?,
          stationSource: cached['stationSource'] as String?,
        ),
      );
      continue;
    }

    final station = await findNearestMetarStation(
      client: client,
      latitude: city.latitude,
      longitude: city.longitude,
      timeout: timeout,
    );
    cache[city.id] = <String, dynamic>{
      'icao': station?.icao,
      'stationSource': station == null ? null : 'stationinfo:auto',
    };
    dirty = true;
    resolved.add(
      city.copyWith(
        icao: station?.icao,
        stationSource: station == null ? null : 'stationinfo:auto',
      ),
    );
  }

  if (dirty) {
    final file = File(cachePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(cache));
  }

  return resolved;
}

Future<Map<String, dynamic>> _loadStationCache(String path) async {
  final file = File(path);
  if (!await file.exists()) return <String, dynamic>{};
  final raw = await file.readAsString();
  if (raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  return <String, dynamic>{};
}

Future<StationInfo?> findNearestMetarStation({
  required http.Client client,
  required double latitude,
  required double longitude,
  required Duration timeout,
}) async {
  for (final radius in <double>[0.75, 1.5, 3.0, 6.0]) {
    final candidates = await fetchNearbyMetarStations(
      client: client,
      latitude: latitude,
      longitude: longitude,
      radiusDegrees: radius,
      timeout: timeout,
    );
    final best = chooseBestStationForCity(
      latitude: latitude,
      longitude: longitude,
      stations: candidates,
    );
    if (best != null) return best;
  }
  return null;
}

Future<List<StationInfo>> fetchNearbyMetarStations({
  required http.Client client,
  required double latitude,
  required double longitude,
  required double radiusDegrees,
  required Duration timeout,
}) async {
  final minLat = (latitude - radiusDegrees).clamp(-90.0, 90.0);
  final maxLat = (latitude + radiusDegrees).clamp(-90.0, 90.0);
  final minLon = (longitude - radiusDegrees).clamp(-180.0, 180.0);
  final maxLon = (longitude + radiusDegrees).clamp(-180.0, 180.0);
  final uri = Uri.https('aviationweather.gov', '/api/data/stationinfo', <
    String,
    String
  >{
    'bbox':
        '${minLat.toStringAsFixed(4)},${minLon.toStringAsFixed(4)},${maxLat.toStringAsFixed(4)},${maxLon.toStringAsFixed(4)}',
    'format': 'json',
  });
  final response = await client
      .get(uri, headers: _benchmarkHeaders)
      .timeout(timeout);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return const <StationInfo>[];
  }
  final body = response.body.trim();
  if (body.isEmpty) return const <StationInfo>[];
  final decoded = jsonDecode(body);
  if (decoded is! List) return const <StationInfo>[];
  return decoded
      .whereType<Map<String, dynamic>>()
      .where((item) {
        final types =
            (item['siteType'] as List?)?.cast<dynamic>() ?? const <dynamic>[];
        return types.contains('METAR');
      })
      .map(StationInfo.fromJson)
      .toList(growable: false);
}

StationInfo? chooseBestStationForCity({
  required double latitude,
  required double longitude,
  required List<StationInfo> stations,
}) {
  if (stations.isEmpty) return null;
  final ordered = stations.toList()
    ..sort((a, b) {
      final distanceA = haversineKm(
        latitude1: latitude,
        longitude1: longitude,
        latitude2: a.latitude,
        longitude2: a.longitude,
      );
      final distanceB = haversineKm(
        latitude1: latitude,
        longitude1: longitude,
        latitude2: b.latitude,
        longitude2: b.longitude,
      );
      final distanceCompare = distanceA.compareTo(distanceB);
      if (distanceCompare != 0) return distanceCompare;
      return (a.priority ?? 999).compareTo(b.priority ?? 999);
    });
  return ordered.first;
}

double haversineKm({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(latitude2 - latitude1);
  final dLon = _degToRad(longitude2 - longitude1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(latitude1)) *
          math.cos(_degToRad(latitude2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double value) => value * math.pi / 180;

Future<List<CityBenchmarkResult>> runWeatherProviderBenchmark({
  required http.Client client,
  required List<BenchmarkCity> cities,
  required DateTime referenceTimeUtc,
  required Duration timeout,
}) async {
  final results = <CityBenchmarkResult>[];
  for (final city in cities) {
    stdout.writeln(
      'Benchmarking ${city.label} (${city.icao ?? 'no-metar-station'})...',
    );
    ProviderSnapshot? observation;
    if (city.icao != null && city.icao!.trim().isNotEmpty) {
      try {
        observation = await fetchMetarObservation(
          client: client,
          city: city,
          timeout: timeout,
        );
      } catch (error) {
        stderr.writeln('METAR observation unavailable for ${city.id}: $error');
      }
    }
    final openMeteo = await _fetchProviderSnapshotOrError(
      provider: 'Open-Meteo',
      referenceTimeUtc: referenceTimeUtc,
      fetch: () =>
          fetchOpenMeteoSnapshot(client: client, city: city, timeout: timeout),
    );
    final metNorway = await _fetchProviderSnapshotOrError(
      provider: 'MET Norway',
      referenceTimeUtc: observation?.sampledAtUtc ?? referenceTimeUtc,
      fetch: () => fetchMetNorwaySnapshot(
        client: client,
        city: city,
        timeout: timeout,
        referenceTimeUtc: observation?.sampledAtUtc ?? referenceTimeUtc,
      ),
    );

    final providers = <String, ProviderSnapshot>{
      openMeteo.provider: openMeteo,
      metNorway.provider: metNorway,
    };
    final scores = <String, ProviderScore>{};
    if (observation != null) {
      for (final entry in providers.entries) {
        if (entry.value.isError) continue;
        scores[entry.key] = scoreProviderAgainstObservation(
          provider: entry.value,
          observation: observation,
        );
      }
    }

    results.add(
      CityBenchmarkResult(
        city: city,
        observation: observation,
        providers: providers,
        scores: scores,
      ),
    );
  }
  return results;
}

Future<ProviderSnapshot> _fetchProviderSnapshotOrError({
  required String provider,
  required DateTime referenceTimeUtc,
  required Future<ProviderSnapshot> Function() fetch,
}) async {
  try {
    return await fetch();
  } catch (error) {
    stderr.writeln('$provider unavailable: $error');
    return ProviderSnapshot(
      provider: provider,
      sampledAtUtc: referenceTimeUtc,
      bucket: WeatherBucket.unknown,
      summary: 'ERROR: $error',
    );
  }
}

Future<ProviderSnapshot> fetchOpenMeteoSnapshot({
  required http.Client client,
  required BenchmarkCity city,
  required Duration timeout,
}) async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
    'latitude': city.latitude.toStringAsFixed(4),
    'longitude': city.longitude.toStringAsFixed(4),
    'current':
        'temperature_2m,weather_code,wind_speed_10m,cloud_cover,visibility,is_day',
    'timezone': 'UTC',
  });
  final response = await client
      .get(uri, headers: _benchmarkHeaders)
      .timeout(timeout);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Open-Meteo failed for ${city.id} (${response.statusCode})',
    );
  }
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final current = decoded['current'] as Map<String, dynamic>;
  final weatherCode = (current['weather_code'] as num?)?.toInt() ?? -1;
  final visibilityMeters = (current['visibility'] as num?)?.toDouble();
  return ProviderSnapshot(
    provider: 'Open-Meteo',
    sampledAtUtc: DateTime.parse(current['time'] as String).toUtc(),
    bucket: normalizeOpenMeteoBucket(weatherCode),
    summary: 'WMO $weatherCode',
    temperatureC: (current['temperature_2m'] as num?)?.toDouble(),
    windKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
    cloudCoverPercent: (current['cloud_cover'] as num?)?.toDouble(),
    visibilityKm: visibilityMeters == null ? null : visibilityMeters / 1000,
    raw: response.body,
  );
}

Future<ProviderSnapshot> fetchMetNorwaySnapshot({
  required http.Client client,
  required BenchmarkCity city,
  required Duration timeout,
  required DateTime referenceTimeUtc,
}) async {
  final uri = Uri.https(
    'api.met.no',
    '/weatherapi/locationforecast/2.0/compact',
    <String, String>{
      'lat': city.latitude.toStringAsFixed(4),
      'lon': city.longitude.toStringAsFixed(4),
    },
  );
  final response = await client
      .get(uri, headers: _benchmarkHeaders)
      .timeout(timeout);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'MET Norway failed for ${city.id} (${response.statusCode})',
    );
  }
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final properties = decoded['properties'] as Map<String, dynamic>;
  final timeseries = (properties['timeseries'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final point = _pickClosestMetNorwayTimeseries(
    timeseries: timeseries,
    referenceTimeUtc: referenceTimeUtc,
  );
  final data = point['data'] as Map<String, dynamic>;
  final instant = data['instant'] as Map<String, dynamic>;
  final details = instant['details'] as Map<String, dynamic>;
  final next1 = data['next_1_hours'] as Map<String, dynamic>?;
  final next6 = data['next_6_hours'] as Map<String, dynamic>?;
  final next12 = data['next_12_hours'] as Map<String, dynamic>?;
  final symbolCode =
      ((next1?['summary'] as Map<String, dynamic>?)?['symbol_code']
          as String?) ??
      ((next6?['summary'] as Map<String, dynamic>?)?['symbol_code']
          as String?) ??
      ((next12?['summary'] as Map<String, dynamic>?)?['symbol_code']
          as String?) ??
      'unknown';
  return ProviderSnapshot(
    provider: 'MET Norway',
    sampledAtUtc: DateTime.parse(point['time'] as String).toUtc(),
    bucket: normalizeMetNorwayBucket(symbolCode),
    summary: symbolCode,
    temperatureC: (details['air_temperature'] as num?)?.toDouble(),
    windKmh: ((details['wind_speed'] as num?)?.toDouble()) == null
        ? null
        : ((details['wind_speed'] as num).toDouble() * 3.6),
    cloudCoverPercent: (details['cloud_area_fraction'] as num?)?.toDouble(),
    visibilityKm: null,
    raw: jsonEncode(point),
  );
}

Map<String, dynamic> _pickClosestMetNorwayTimeseries({
  required List<Map<String, dynamic>> timeseries,
  required DateTime referenceTimeUtc,
}) {
  Map<String, dynamic>? best;
  Duration? bestDelta;
  for (final point in timeseries.take(12)) {
    final time = DateTime.parse(point['time'] as String).toUtc();
    final delta = time.difference(referenceTimeUtc).abs();
    if (best == null || delta < bestDelta!) {
      best = point;
      bestDelta = delta;
    }
  }
  return best ?? timeseries.first;
}

Future<ProviderSnapshot?> fetchMetarObservation({
  required http.Client client,
  required BenchmarkCity city,
  required Duration timeout,
}) async {
  final icao = city.icao;
  if (icao == null || icao.trim().isEmpty) return null;
  final uri = Uri.https(
    'aviationweather.gov',
    '/api/data/metar',
    <String, String>{'ids': icao, 'format': 'json'},
  );
  final response = await client
      .get(uri, headers: _benchmarkHeaders)
      .timeout(timeout);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('METAR failed for ${city.id} (${response.statusCode})');
  }
  final body = response.body.trim();
  if (body.isEmpty) return null;
  final dynamic parsed;
  try {
    parsed = jsonDecode(body);
  } on FormatException {
    return null;
  }
  final decoded = parsed as List<dynamic>;
  if (decoded.isEmpty) return null;
  final report = decoded.first as Map<String, dynamic>;
  final rawOb = (report['rawOb'] as String?)?.trim() ?? '';
  final visibilityMiles = _asDouble(report['visib']);
  final cover = (report['cover'] as String?)?.trim();
  final visibilityKm = cover?.toUpperCase() == 'CAVOK'
      ? 10.0
      : (visibilityMiles == null ? null : (visibilityMiles * 1.60934));
  final bucket = normalizeMetarBucket(
    rawObservation: rawOb,
    visibilityKm: visibilityKm,
    cover: cover,
  );
  return ProviderSnapshot(
    provider: 'METAR',
    sampledAtUtc: (report['reportTime'] as String?) != null
        ? DateTime.parse(report['reportTime'] as String).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(
            (((report['obsTime'] as num?)?.toInt() ?? 0) * 1000),
            isUtc: true,
          ),
    bucket: bucket,
    summary: cover ?? rawOb,
    temperatureC: _asDouble(report['temp']),
    windKmh: _asDouble(report['wspd']) == null
        ? null
        : (_asDouble(report['wspd'])! * 1.852),
    cloudCoverPercent: normalizeMetarCloudCoverPercent(cover),
    visibilityKm: visibilityKm,
    raw: rawOb,
  );
}

ProviderScore scoreProviderAgainstObservation({
  required ProviderSnapshot provider,
  required ProviderSnapshot observation,
}) {
  final temperatureError = _absoluteError(
    provider.temperatureC,
    observation.temperatureC,
  );
  final windError = _absoluteError(provider.windKmh, observation.windKmh);
  final cloudError = _absoluteError(
    provider.cloudCoverPercent,
    observation.cloudCoverPercent,
  );
  final bucketSimilarity = scoreBucketSimilarity(
    provider.bucket,
    observation.bucket,
  );

  final weighted = <double, double>{
    if (temperatureError != null)
      _normalizedErrorScore(temperatureError, 8): 0.35,
    if (windError != null) _normalizedErrorScore(windError, 20): 0.2,
    if (cloudError != null) _normalizedErrorScore(cloudError, 100): 0.15,
    bucketSimilarity: 0.3,
  };

  var weightedTotal = 0.0;
  var weightTotal = 0.0;
  weighted.forEach((score, weight) {
    weightedTotal += score * weight;
    weightTotal += weight;
  });

  return ProviderScore(
    provider: provider.provider,
    composite: weightTotal == 0 ? 0 : weightedTotal / weightTotal,
    bucketSimilarity: bucketSimilarity,
    temperatureErrorC: temperatureError,
    windErrorKmh: windError,
    cloudErrorPercent: cloudError,
  );
}

double scoreBucketSimilarity(WeatherBucket predicted, WeatherBucket observed) {
  if (predicted == observed) return 1.0;
  final skyBuckets = <WeatherBucket>{
    WeatherBucket.clear,
    WeatherBucket.partlyCloudy,
    WeatherBucket.cloudy,
  };
  if (skyBuckets.contains(predicted) && skyBuckets.contains(observed)) {
    if ((predicted == WeatherBucket.clear &&
            observed == WeatherBucket.partlyCloudy) ||
        (predicted == WeatherBucket.partlyCloudy &&
            observed == WeatherBucket.clear) ||
        (predicted == WeatherBucket.partlyCloudy &&
            observed == WeatherBucket.cloudy) ||
        (predicted == WeatherBucket.cloudy &&
            observed == WeatherBucket.partlyCloudy)) {
      return 0.55;
    }
    return 0.2;
  }
  return 0.0;
}

double? _absoluteError(double? a, double? b) {
  if (a == null || b == null) return null;
  return (a - b).abs();
}

double _normalizedErrorScore(double error, double cap) {
  final normalized = 1 - (error / cap);
  if (normalized < 0) return 0;
  if (normalized > 1) return 1;
  return normalized;
}

WeatherBucket normalizeOpenMeteoBucket(int weatherCode) {
  if (weatherCode == 0) return WeatherBucket.clear;
  if (weatherCode == 1 || weatherCode == 2) return WeatherBucket.partlyCloudy;
  if (weatherCode == 3) return WeatherBucket.cloudy;
  if (weatherCode == 45 || weatherCode == 48) return WeatherBucket.fog;
  if (<int>{
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
  }.contains(weatherCode)) {
    return WeatherBucket.rain;
  }
  if (<int>{71, 73, 75, 77, 85, 86}.contains(weatherCode)) {
    return WeatherBucket.snow;
  }
  if (<int>{95, 96, 99}.contains(weatherCode)) {
    return WeatherBucket.storm;
  }
  return WeatherBucket.unknown;
}

WeatherBucket normalizeMetNorwayBucket(String symbolCode) {
  final value = symbolCode.toLowerCase();
  if (value.contains('thunder')) return WeatherBucket.storm;
  if (value.contains('snow') || value.contains('sleet')) {
    return WeatherBucket.snow;
  }
  if (value.contains('rain') ||
      value.contains('drizzle') ||
      value.contains('showers')) {
    return WeatherBucket.rain;
  }
  if (value.contains('fog')) return WeatherBucket.fog;
  if (value.contains('clearsky')) return WeatherBucket.clear;
  if (value.contains('fair') || value.contains('partlycloudy')) {
    return WeatherBucket.partlyCloudy;
  }
  if (value.contains('cloudy')) return WeatherBucket.cloudy;
  return WeatherBucket.unknown;
}

WeatherBucket normalizeMetarBucket({
  required String rawObservation,
  required double? visibilityKm,
  required String? cover,
}) {
  final upper = rawObservation.toUpperCase();
  if (upper.contains(' TS')) return WeatherBucket.storm;
  if (_containsAny(upper, <String>[' SN', ' SG', ' PL', ' IC'])) {
    return WeatherBucket.snow;
  }
  if (_containsAny(upper, <String>[' RA', ' DZ', ' SH', ' UP'])) {
    return WeatherBucket.rain;
  }
  if (upper.contains(' FG') || (visibilityKm != null && visibilityKm <= 1.0)) {
    return WeatherBucket.fog;
  }
  final cloudCover = normalizeMetarCloudCoverPercent(cover);
  if (cloudCover == null) return WeatherBucket.unknown;
  if (cloudCover < 20) return WeatherBucket.clear;
  if (cloudCover < 70) return WeatherBucket.partlyCloudy;
  return WeatherBucket.cloudy;
}

bool _containsAny(String value, List<String> needles) {
  for (final needle in needles) {
    if (value.contains(needle)) return true;
  }
  return false;
}

double? normalizeMetarCloudCoverPercent(String? cover) {
  if (cover == null || cover.isEmpty) return null;
  return switch (cover.toUpperCase()) {
    'CLR' || 'SKC' || 'NSC' || 'CAVOK' => 0,
    'FEW' => 20,
    'SCT' => 50,
    'BKN' => 87.5,
    'OVC' || 'VV' => 100,
    _ => null,
  };
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final direct = double.tryParse(normalized);
    if (direct != null) return direct;
    final cleaned = normalized.replaceAll(RegExp(r'[^0-9+.\-]'), '');
    if (cleaned.isEmpty || cleaned == '+' || cleaned == '-' || cleaned == '.') {
      return null;
    }
    final strippedPlus = cleaned.endsWith('+')
        ? cleaned.substring(0, cleaned.length - 1)
        : cleaned;
    return double.tryParse(strippedPlus);
  }
  return null;
}

Map<String, ProviderAggregate> aggregateProviderScores(
  List<CityBenchmarkResult> results,
) {
  final providerNames = <String>{};
  for (final result in results) {
    providerNames.addAll(result.providers.keys);
  }
  final aggregates = <String, ProviderAggregate>{};
  for (final provider in providerNames) {
    final relevant = results.where(
      (result) => result.scores.containsKey(provider),
    );
    final scoreList = relevant
        .map((result) => result.scores[provider]!)
        .toList();
    if (scoreList.isEmpty) continue;

    final wins = results.where((result) => result.winner == provider).length;
    final exactBucketMatches = relevant.where((result) {
      return result.providers[provider]!.bucket == result.observation!.bucket;
    }).length;
    final fogFalsePositives = relevant.where((result) {
      return result.providers[provider]!.bucket == WeatherBucket.fog &&
          result.observation!.bucket != WeatherBucket.fog;
    }).length;
    final fogFalseNegatives = relevant.where((result) {
      return result.providers[provider]!.bucket != WeatherBucket.fog &&
          result.observation!.bucket == WeatherBucket.fog;
    }).length;

    aggregates[provider] = ProviderAggregate(
      provider: provider,
      sampleCount: scoreList.length,
      winCount: wins,
      averageComposite: _average(scoreList.map((score) => score.composite)),
      averageTemperatureErrorC: _averageNullable(
        scoreList.map((score) => score.temperatureErrorC),
      ),
      averageWindErrorKmh: _averageNullable(
        scoreList.map((score) => score.windErrorKmh),
      ),
      averageCloudErrorPercent: _averageNullable(
        scoreList.map((score) => score.cloudErrorPercent),
      ),
      exactBucketMatchRate: exactBucketMatches / scoreList.length,
      fogFalsePositives: fogFalsePositives,
      fogFalseNegatives: fogFalseNegatives,
    );
  }
  return aggregates;
}

Map<String, ProviderPrior> deriveProviderPriors(
  Map<String, ProviderAggregate> aggregates,
) {
  if (aggregates.isEmpty) return const <String, ProviderPrior>{};
  final rawScores = <String, double>{};
  aggregates.forEach((provider, aggregate) {
    final winRate = aggregate.sampleCount == 0
        ? 0.0
        : aggregate.winCount / aggregate.sampleCount;
    final fogPenalty = aggregate.sampleCount == 0
        ? 0.0
        : (aggregate.fogFalsePositives / aggregate.sampleCount);
    final raw =
        (aggregate.averageComposite * 0.55) +
        (aggregate.exactBucketMatchRate * 0.25) +
        (winRate * 0.20) -
        (fogPenalty * 0.10);
    rawScores[provider] = raw.clamp(0.0, 1.0);
  });

  final total = rawScores.values.fold<double>(0.0, (sum, value) => sum + value);
  if (total <= 0) {
    final uniformWeight = 1 / rawScores.length;
    return rawScores.map(
      (provider, raw) => MapEntry(
        provider,
        ProviderPrior(provider: provider, weight: uniformWeight, rawScore: raw),
      ),
    );
  }

  return rawScores.map(
    (provider, raw) => MapEntry(
      provider,
      ProviderPrior(provider: provider, weight: raw / total, rawScore: raw),
    ),
  );
}

String renderBenchmarkMarkdown({
  required BenchmarkConfig config,
  required List<CityBenchmarkResult> results,
  required Map<String, ProviderPrior> priors,
}) {
  final generatedAt = DateTime.now().toUtc();
  final aggregates = aggregateProviderScores(results);
  final observedCount = results
      .where((result) => result.observation != null)
      .length;
  final missingObsCount = results.length - observedCount;
  final buffer = StringBuffer()
    ..writeln('# Weather Provider Benchmark')
    ..writeln()
    ..writeln('- Generated at (UTC): `${generatedAt.toIso8601String()}`')
    ..writeln(
      '- Reference time (UTC): `${config.referenceTimeUtc.toIso8601String()}`',
    )
    ..writeln('- Cities evaluated: `${results.length}`')
    ..writeln(
      '- Selection mode: `${config.usesExpandedSampling ? 'expanded-sample' : 'fixture'}`',
    )
    ..writeln(
      '- Fixture/source: `${config.usesExpandedSampling ? config.datasetCitiesPath : config.citiesPath}`',
    )
    ..writeln('- Observation proxy: `METAR airport observations`')
    ..writeln('- Observation coverage: `$observedCount/${results.length}`')
    ..writeln('- Observation gaps: `$missingObsCount`')
    ..writeln(
      config.usesExpandedSampling
          ? '- Sample seed: `${config.sampleSeed}`'
          : '- Sample seed: `n/a`',
    )
    ..writeln()
    ..writeln('## Caveats')
    ..writeln()
    ..writeln('- This is a research harness, not a CI gate.')
    ..writeln(
      '- The airport METAR is a practical observation proxy, not perfect city-center truth.',
    )
    ..writeln(
      '- MET Norway is compared via nearest `Locationforecast` timeseries point to the observation/reference time.',
    )
    ..writeln('- Open-Meteo is compared via its current conditions endpoint.')
    ..writeln(
      '- In expanded-sample mode, nearest METAR stations are resolved automatically through AviationWeather station metadata and may not be city-center stations.',
    )
    ..writeln()
    ..writeln('## Provider Summary')
    ..writeln()
    ..writeln(
      '| Provider | Samples | Wins | Avg composite | Avg temp error (C) | Avg wind error (km/h) | Avg cloud error (%) | Exact bucket match | Fog false + | Fog false - |',
    )
    ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');

  final aggregateValues = aggregates.values.toList()
    ..sort((a, b) => b.averageComposite.compareTo(a.averageComposite));
  for (final aggregate in aggregateValues) {
    buffer.writeln(
      '| ${aggregate.provider} | ${aggregate.sampleCount} | ${aggregate.winCount} | ${aggregate.averageComposite.toStringAsFixed(3)} | ${_formatNullable(aggregate.averageTemperatureErrorC)} | ${_formatNullable(aggregate.averageWindErrorKmh)} | ${_formatNullable(aggregate.averageCloudErrorPercent)} | ${(aggregate.exactBucketMatchRate * 100).toStringAsFixed(0)}% | ${aggregate.fogFalsePositives} | ${aggregate.fogFalseNegatives} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Provider Priors')
    ..writeln()
    ..writeln(
      'These priors are the benchmark-derived provider weights intended to feed a future runtime confidence score. They should not override live disagreement signals, but they can bias the system toward the better-performing provider when other signals are close.',
    )
    ..writeln()
    ..writeln('| Provider | Prior weight | Raw score |')
    ..writeln('|---|---:|---:|');

  final priorValues = priors.values.toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));
  for (final prior in priorValues) {
    buffer.writeln(
      '| ${prior.provider} | ${(prior.weight * 100).toStringAsFixed(1)}% | ${prior.rawScore.toStringAsFixed(3)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Per-City Results')
    ..writeln();

  for (final result in results) {
    buffer.writeln(
      '### ${result.city.label} (`${result.city.icao ?? 'no-metar-station'}`)',
    );
    if (result.observation == null) {
      buffer
        ..writeln()
        ..writeln(
          'No METAR observation was available for this city at run time.',
        )
        ..writeln();
      continue;
    }
    final observation = result.observation!;
    buffer
      ..writeln()
      ..writeln(
        '- Observation: `${observation.bucket.label}` at `${observation.sampledAtUtc.toIso8601String()}`',
      )
      ..writeln('- Observation detail: `${observation.summary}`')
      ..writeln('- Winner: `${result.winner ?? 'n/a'}`')
      ..writeln()
      ..writeln(
        '| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |',
      )
      ..writeln('|---|---|---|---:|---:|---:|---:|---:|---|');

    buffer.writeln(
      '| METAR | ${observation.sampledAtUtc.toIso8601String()} | ${observation.bucket.label} | ${_formatNullable(observation.temperatureC)} | ${_formatNullable(observation.windKmh)} | ${_formatNullable(observation.cloudCoverPercent)} | ${_formatNullable(observation.visibilityKm)} | — | ${_escapePipe(observation.summary)} |',
    );
    final providers = result.providers.values.toList()
      ..sort((a, b) => a.provider.compareTo(b.provider));
    for (final provider in providers) {
      final score = result.scores[provider.provider];
      buffer.writeln(
        '| ${provider.provider} | ${provider.sampledAtUtc.toIso8601String()} | ${provider.bucket.label} | ${_formatNullable(provider.temperatureC)} | ${_formatNullable(provider.windKmh)} | ${_formatNullable(provider.cloudCoverPercent)} | ${_formatNullable(provider.visibilityKm)} | ${score == null ? '—' : score.composite.toStringAsFixed(3)} | ${_escapePipe(provider.summary)} |',
      );
    }
    buffer.writeln();
  }

  return buffer.toString();
}

String _formatNullable(double? value) {
  if (value == null) return '—';
  return value.toStringAsFixed(1);
}

double _average(Iterable<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

double? _averageNullable(Iterable<double?> values) {
  final actual = values.whereType<double>().toList();
  if (actual.isEmpty) return null;
  return _average(actual);
}

String _escapePipe(String value) => value.replaceAll('|', '\\|');

const Map<String, String> _benchmarkHeaders = <String, String>{
  'User-Agent': 'UnitanaCodex/1.0 (weather benchmark)',
  'Accept': 'application/json',
};
