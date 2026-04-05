part of 'dashboard_live_data.dart';

class _DashboardWeatherDomain {
  _DashboardWeatherDomain({
    required CityRepository cityRepository,
    required WeatherApiClient weatherApiClient,
    required OpenMeteoClient openMeteoClient,
    required MetNorwayClient metNorwayClient,
  }) : _cityRepository = cityRepository,
       _weatherApi = weatherApiClient,
       _openMeteo = openMeteoClient,
       _metNorway = metNorwayClient;

  static const String _kDevWeatherBackend = 'dev_weather_backend_v1';

  final CityRepository _cityRepository;
  final WeatherApiClient _weatherApi;
  final OpenMeteoClient _openMeteo;
  final MetNorwayClient _metNorway;

  final Map<String, WeatherSnapshot> _weatherByPlaceId = {};
  final Map<String, SunTimesSnapshot> _sunByPlaceId = {};
  final Map<String, WeatherForecastSnapshot> _forecastByPlaceId = {};
  final Map<String, WeatherSecondOpinion> _secondOpinionByPlaceId = {};

  WeatherBackend _backend = DashboardLiveDataController._backendFromEnv();
  WeatherDebugOverride? _debugWeatherOverride;
  WeatherEmergencySeverity? _debugEmergencySeverityOverride;
  Object? _lastError;
  DateTime? _lastErrorAt;
  DateTime? _lastRefreshedAt;

  WeatherBackend get backend => _backend;
  bool get canUseWeatherApi => _weatherApi.isConfigured;
  Object? get lastError => _lastError;
  DateTime? get lastErrorAt => _lastErrorAt;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  WeatherDebugOverride? get debugWeatherOverride => _debugWeatherOverride;
  WeatherEmergencySeverity? get debugEmergencySeverityOverride =>
      _debugEmergencySeverityOverride;

  void recordLastError(Object error, {required DateTime now}) {
    _lastError = error;
    _lastErrorAt = now;
  }

  void recordRefreshSuccess({required DateTime now}) {
    _lastRefreshedAt = now;
    _lastError = null;
    _lastErrorAt = null;
  }

  void debugSetLastRefreshedAt(DateTime? value) {
    _lastRefreshedAt = value;
  }

  void loadPersistedState({
    required SharedPreferences prefs,
    required bool developerToolsEnabled,
  }) {
    final weatherRaw = prefs.getString(_kDevWeatherBackend);
    if (developerToolsEnabled &&
        weatherRaw != null &&
        weatherRaw.trim().isNotEmpty) {
      final norm = weatherRaw.trim().toLowerCase();
      final WeatherBackend next;
      if (norm == 'openmeteo' ||
          norm == 'open_meteo' ||
          norm == 'open-meteo' ||
          norm == 'openmeto') {
        next = WeatherBackend.openMeteo;
      } else if (norm == 'weatherapi' ||
          norm == 'weather_api' ||
          norm == 'weather-api') {
        next = WeatherBackend.weatherApi;
      } else {
        next = WeatherBackend.mock;
      }

      if (next == WeatherBackend.weatherApi && !_weatherApi.isConfigured) {
        _backend = WeatherBackend.openMeteo;
      } else {
        _backend = next;
      }
    }
  }

  void setBackend(WeatherBackend backend) {
    _backend = backend;
  }

  Future<void> persistBackendPreference(SharedPreferences prefs) async {
    await prefs.setString(_kDevWeatherBackend, _backendKey(_backend));
  }

  bool setDebugWeatherOverride(WeatherDebugOverride? value) {
    final next = value;
    final prev = _debugWeatherOverride;
    if (prev == null && next == null) return false;
    if (prev is WeatherDebugOverrideCoarse &&
        next is WeatherDebugOverrideCoarse &&
        prev.condition == next.condition &&
        prev.isNightOverride == next.isNightOverride) {
      return false;
    }
    _debugWeatherOverride = next;
    return true;
  }

  bool setDebugEmergencySeverityOverride(WeatherEmergencySeverity? value) {
    if (_debugEmergencySeverityOverride == value) return false;
    _debugEmergencySeverityOverride = value;
    return true;
  }

  bool setDebugWeatherApiOverride({
    required int code,
    required bool isNight,
    required String text,
  }) {
    final next = WeatherDebugOverrideWeatherApi(
      code: code,
      isNight: isNight,
      text: text,
    );

    final prev = _debugWeatherOverride;
    if (prev is WeatherDebugOverrideWeatherApi &&
        prev.code == code &&
        prev.isNight == isNight &&
        prev.text == text) {
      return false;
    }

    _debugWeatherOverride = next;
    return true;
  }

  WeatherSnapshot? weatherFor(Place? place) {
    if (place == null) return null;
    final snap = _weatherByPlaceId[place.id];
    if (snap == null) return null;

    final override = _debugWeatherOverride;
    if (override == null) return snap;

    if (override is WeatherDebugOverrideCoarse) {
      return WeatherSnapshot(
        temperatureC: snap.temperatureC,
        windKmh: snap.windKmh,
        gustKmh: snap.gustKmh,
        sceneKey: WeatherConditionSceneKeyMapper.fromWeatherCondition(
          override.condition,
        ),
        cloudCoverPercent: snap.cloudCoverPercent,
        visibilityKm: snap.visibilityKm,
        conditionText: _coarseLabelFor(override.condition),
        conditionCode: snap.conditionCode,
      );
    }

    final api = override as WeatherDebugOverrideWeatherApi;
    return WeatherSnapshot(
      temperatureC: snap.temperatureC,
      windKmh: snap.windKmh,
      gustKmh: snap.gustKmh,
      sceneKey: WeatherApiSceneKeyMapper.fromWeatherApi(
        code: api.code,
        text: api.text,
      ),
      cloudCoverPercent: snap.cloudCoverPercent,
      visibilityKm: snap.visibilityKm,
      conditionText: api.text,
      conditionCode: api.code,
    );
  }

  SunTimesSnapshot? sunFor(Place? place) {
    if (place == null) return null;
    return _sunByPlaceId[place.id];
  }

  WeatherForecastSnapshot? forecastFor(Place? place) {
    if (place == null) return null;
    return _forecastByPlaceId[place.id];
  }

  WeatherSecondOpinion? secondOpinionFor(Place? place) {
    if (place == null) return null;
    return _secondOpinionByPlaceId[place.id];
  }

  WeatherEmergencyAssessment emergencyFor({
    required Place? place,
    required EnvSnapshot? env,
  }) {
    final forced = _debugEmergencySeverityOverride;
    if (forced != null) {
      return WeatherEmergencyAssessment(
        severity: forced,
        reasonKey: switch (forced) {
          WeatherEmergencySeverity.none => 'none',
          WeatherEmergencySeverity.advisory => 'provider_advisory',
          WeatherEmergencySeverity.watch => 'provider_watch',
          WeatherEmergencySeverity.warning => 'provider_warning',
          WeatherEmergencySeverity.emergency => 'tornado',
        },
        source: 'debug',
      );
    }
    if (place == null) {
      return const WeatherEmergencyAssessment(
        severity: WeatherEmergencySeverity.none,
        reasonKey: 'none',
        source: 'fallback',
      );
    }
    return WeatherEmergencyTaxonomy.assess(
      weather: weatherFor(place),
      env: env,
    );
  }

  bool ensureSeeded({
    required List<Place> places,
    required DateTime nowUtc,
    required bool weatherNetworkEnabled,
    required _DashboardEnvDomain envDomain,
  }) {
    var changed = false;
    for (final p in places) {
      if (!_weatherByPlaceId.containsKey(p.id)) {
        _weatherByPlaceId[p.id] = _seedWeather(p);
        changed = true;
      }
      if (!_sunByPlaceId.containsKey(p.id)) {
        _sunByPlaceId[p.id] = _seedSunTimes(p, nowUtc);
        changed = true;
      }
      changed = envDomain.ensureSeededForPlace(p) || changed;
      if (!_forecastByPlaceId.containsKey(p.id)) {
        _forecastByPlaceId[p.id] = _seedForecast(p, nowUtc);
        changed = true;
      }
    }

    if (!weatherNetworkEnabled) {
      // no-op here; root controller decides whether this should count as a refresh
    }
    return changed;
  }

  void clearPlaceSnapshots() {
    _weatherByPlaceId.clear();
    _sunByPlaceId.clear();
    _forecastByPlaceId.clear();
    _secondOpinionByPlaceId.clear();
  }

  Future<bool> refreshPlaces({
    required List<Place> places,
    required int refreshGeneration,
    required bool weatherNetworkEnabled,
    required _DashboardEnvDomain envDomain,
    required bool Function(int refreshGeneration) isCurrentRefresh,
    required void Function(
      Object error,
      StackTrace stackTrace,
      String contextLabel,
    )
    recordRefreshError,
    required DateTime nowUtc,
  }) async {
    if (_useWeatherApi(weatherNetworkEnabled) ||
        _useOpenMeteo(weatherNetworkEnabled)) {
      await _cityRepository.load();
      if (!isCurrentRefresh(refreshGeneration)) {
        return false;
      }

      var didApplyAnyLiveWeatherUpdate = false;
      for (final p in places) {
        if (!isCurrentRefresh(refreshGeneration)) {
          return false;
        }
        try {
          final city = _cityRepository.byPlace(
            p.cityName,
            countryCode: p.countryCode,
          );

          final lat = city?.lat;
          final lon = city?.lon;
          final query = (lat != null && lon != null)
              ? '$lat,$lon'
              : '${p.cityName},${p.countryCode}';

          final override = _debugWeatherOverride;

          if (_useWeatherApi(weatherNetworkEnabled)) {
            final api = await _weatherApi.fetchTodayForecast(query: query);
            if (!isCurrentRefresh(refreshGeneration)) {
              return false;
            }

            final SceneKey sceneKey;
            final String conditionText;
            final int conditionCode;

            if (override == null) {
              sceneKey = WeatherApiSceneKeyMapper.fromWeatherApi(
                code: api.conditionCode,
                text: api.conditionText,
              );
              conditionText = api.conditionText;
              conditionCode = api.conditionCode;
            } else if (override is WeatherDebugOverrideCoarse) {
              sceneKey = WeatherConditionSceneKeyMapper.fromWeatherCondition(
                override.condition,
              );
              conditionText = _coarseLabelFor(override.condition);
              conditionCode = api.conditionCode;
            } else {
              final w = override as WeatherDebugOverrideWeatherApi;
              sceneKey = WeatherApiSceneKeyMapper.fromWeatherApi(
                code: w.code,
                text: w.text,
              );
              conditionText = w.text;
              conditionCode = w.code;
            }

            _weatherByPlaceId[p.id] = WeatherSnapshot(
              temperatureC: api.temperatureC,
              windKmh: api.windKmh,
              gustKmh: api.gustKmh,
              sceneKey: sceneKey,
              cloudCoverPercent: api.cloudCoverPercent,
              visibilityKm: api.visibilityKm,
              conditionText: conditionText,
              conditionCode: conditionCode,
            );
            _sunByPlaceId[p.id] = SunTimesSnapshot(
              sunriseUtc: api.sunriseUtc,
              sunsetUtc: api.sunsetUtc,
            );
            _forecastByPlaceId[p.id] = _fromWeatherApiForecast(api);
            await _maybeRefreshSecondOpinion(
              place: p,
              latitude: lat,
              longitude: lon,
              primarySceneKey: sceneKey,
              refreshGeneration: refreshGeneration,
              isCurrentRefresh: isCurrentRefresh,
            );
            recordRefreshSuccess(now: DateTime.now());
            didApplyAnyLiveWeatherUpdate = true;
          } else {
            if (lat == null || lon == null) {
              ensureFallbackSnapshotsForPlace(
                p,
                nowUtc: nowUtc,
                envDomain: envDomain,
              );
              continue;
            }

            final om = await _openMeteo.fetchTodayForecast(
              latitude: lat,
              longitude: lon,
            );
            if (!isCurrentRefresh(refreshGeneration)) {
              return false;
            }

            final effectiveOverride = override is WeatherDebugOverrideCoarse
                ? override
                : null;

            final SceneKey sceneKey;
            final String conditionText;
            final int conditionCode = om.weatherCode;

            if (effectiveOverride == null) {
              sceneKey = OpenMeteoSceneKeyMapper.fromWmoCode(om.weatherCode);
              conditionText = OpenMeteoSceneKeyMapper.labelFor(om.weatherCode);
            } else {
              sceneKey = WeatherConditionSceneKeyMapper.fromWeatherCondition(
                effectiveOverride.condition,
              );
              conditionText = _coarseLabelFor(effectiveOverride.condition);
            }

            _weatherByPlaceId[p.id] = WeatherSnapshot(
              temperatureC: om.temperatureC,
              windKmh: om.windKmh,
              gustKmh: om.gustKmh,
              sceneKey: sceneKey,
              cloudCoverPercent: om.cloudCoverPercent,
              visibilityKm: om.visibilityKm,
              conditionText: conditionText,
              conditionCode: conditionCode,
            );
            _sunByPlaceId[p.id] = SunTimesSnapshot(
              sunriseUtc: om.sunriseUtc,
              sunsetUtc: om.sunsetUtc,
            );
            _forecastByPlaceId[p.id] = _fromOpenMeteoForecast(om);
            await _maybeRefreshSecondOpinion(
              place: p,
              latitude: lat,
              longitude: lon,
              primarySceneKey: sceneKey,
              refreshGeneration: refreshGeneration,
              isCurrentRefresh: isCurrentRefresh,
            );
            recordRefreshSuccess(now: DateTime.now());
            didApplyAnyLiveWeatherUpdate = true;
          }

          await envDomain.maybeRefreshForPlace(
            place: p,
            latitude: lat,
            longitude: lon,
            refreshGeneration: refreshGeneration,
            weatherNetworkEnabled: weatherNetworkEnabled,
            isCurrentRefresh: isCurrentRefresh,
            reportRefreshError: (error, stackTrace, contextLabel) {
              recordRefreshError(error, stackTrace, contextLabel);
            },
          );
          if (!isCurrentRefresh(refreshGeneration)) {
            return false;
          }
          envDomain.ensureSeededForPlace(p);
        } catch (error, stackTrace) {
          if (!isCurrentRefresh(refreshGeneration)) {
            return false;
          }
          recordLastError(error, now: DateTime.now());
          recordRefreshError(
            error,
            stackTrace,
            'while refreshing weather for ${p.id}',
          );
          ensureFallbackSnapshotsForPlace(
            p,
            nowUtc: nowUtc,
            envDomain: envDomain,
          );
        }
      }
      return didApplyAnyLiveWeatherUpdate;
    }

    for (final p in places) {
      if (!isCurrentRefresh(refreshGeneration)) {
        return false;
      }
      _weatherByPlaceId[p.id] = _refreshWeather(p);
      envDomain.putSeeded(p);
      _sunByPlaceId[p.id] = _seedSunTimes(p, nowUtc);
      _forecastByPlaceId[p.id] = _seedForecast(p, nowUtc);
    }
    return true;
  }

  void ensureFallbackSnapshotsForPlace(
    Place p, {
    required DateTime nowUtc,
    required _DashboardEnvDomain envDomain,
  }) {
    _weatherByPlaceId.putIfAbsent(p.id, () => _seedWeather(p));
    _sunByPlaceId.putIfAbsent(p.id, () => _seedSunTimes(p, nowUtc));
    envDomain.ensureSeededForPlace(p);
    _forecastByPlaceId.putIfAbsent(p.id, () => _seedForecast(p, nowUtc));
    _secondOpinionByPlaceId.remove(p.id);
  }

  bool _useWeatherApi(bool weatherNetworkEnabled) =>
      weatherNetworkEnabled &&
      _backend == WeatherBackend.weatherApi &&
      _weatherApi.isConfigured;

  bool _useOpenMeteo(bool weatherNetworkEnabled) =>
      weatherNetworkEnabled && _backend == WeatherBackend.openMeteo;

  static String _backendKey(WeatherBackend b) {
    switch (b) {
      case WeatherBackend.openMeteo:
        return 'openmeteo';
      case WeatherBackend.weatherApi:
        return 'weatherapi';
      case WeatherBackend.mock:
        return 'mock';
    }
  }

  static String _coarseLabelFor(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.partlyCloudy:
        return 'Partly cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.overcast:
        return 'Overcast';
      case WeatherCondition.drizzle:
        return 'Drizzle';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorm';
      case WeatherCondition.snow:
        return 'Snow';
      case WeatherCondition.sleet:
        return 'Sleet';
      case WeatherCondition.hail:
        return 'Hail';
      case WeatherCondition.fog:
        return 'Fog';
      case WeatherCondition.mist:
        return 'Mist';
      case WeatherCondition.haze:
        return 'Haze';
      case WeatherCondition.smoke:
        return 'Smoke';
      case WeatherCondition.dust:
        return 'Dust';
      case WeatherCondition.sand:
        return 'Sand';
      case WeatherCondition.ash:
        return 'Ash';
      case WeatherCondition.squall:
        return 'Squall';
      case WeatherCondition.tornado:
        return 'Tornado';
      case WeatherCondition.windy:
        return 'Windy';
    }
  }

  Future<void> _maybeRefreshSecondOpinion({
    required Place place,
    required double? latitude,
    required double? longitude,
    required SceneKey primarySceneKey,
    required int refreshGeneration,
    required bool Function(int refreshGeneration) isCurrentRefresh,
  }) async {
    if (!_shouldFetchSecondOpinion(primarySceneKey) ||
        latitude == null ||
        longitude == null) {
      _secondOpinionByPlaceId.remove(place.id);
      return;
    }
    try {
      final opinion = await _metNorway.fetchCurrentConditions(
        latitude: latitude,
        longitude: longitude,
      );
      if (!isCurrentRefresh(refreshGeneration)) return;
      _secondOpinionByPlaceId[place.id] = WeatherSecondOpinion(
        provider: 'MET Norway',
        sampledAtUtc: opinion.sampledAtUtc,
        sceneKey: MetNorwaySceneKeyMapper.fromSymbolCode(opinion.symbolCode),
        conditionText: opinion.symbolCode,
        temperatureC: opinion.temperatureC,
        windKmh: opinion.windKmh,
        cloudCoverPercent: opinion.cloudCoverPercent,
      );
    } catch (_) {
      // Advisory only: confidence should still work without a second opinion.
      _secondOpinionByPlaceId.remove(place.id);
    }
  }

  bool _shouldFetchSecondOpinion(SceneKey sceneKey) {
    switch (sceneKey) {
      case SceneKey.fog:
      case SceneKey.mist:
      case SceneKey.hazeDust:
      case SceneKey.smokeWildfire:
      case SceneKey.ashfall:
      case SceneKey.thunderRain:
      case SceneKey.thunderSnow:
      case SceneKey.blizzard:
      case SceneKey.tornado:
      case SceneKey.squall:
        return true;
      default:
        return false;
    }
  }

  WeatherForecastSnapshot _fromWeatherApiForecast(WeatherApiForecast f) {
    return WeatherForecastSnapshot(
      hourly: f.hourly
          .map(
            (h) => HourlyForecastPoint(
              timeUtc: h.timeUtc,
              temperatureC: h.temperatureC,
              precipitationChancePercent: h.precipitationChancePercent,
            ),
          )
          .toList(),
      daily: f.daily
          .map(
            (d) => DailyForecastPoint(
              dayUtc: d.dayUtc,
              maxTemperatureC: d.maxTemperatureC,
              minTemperatureC: d.minTemperatureC,
              precipitationChancePercent: d.precipitationChancePercent,
            ),
          )
          .toList(),
    );
  }

  WeatherForecastSnapshot _fromOpenMeteoForecast(OpenMeteoTodayForecast f) {
    return WeatherForecastSnapshot(
      hourly: f.hourly
          .map(
            (h) => HourlyForecastPoint(
              timeUtc: h.timeUtc,
              temperatureC: h.temperatureC,
              precipitationChancePercent: h.precipitationChancePercent,
            ),
          )
          .toList(),
      daily: f.daily
          .map(
            (d) => DailyForecastPoint(
              dayUtc: d.dayUtc,
              maxTemperatureC: d.maxTemperatureC,
              minTemperatureC: d.minTemperatureC,
              precipitationChancePercent: d.precipitationChancePercent,
            ),
          )
          .toList(),
    );
  }

  WeatherSnapshot _seedWeather(Place p) {
    if (p.cityName.toLowerCase() == 'lisbon') {
      return const WeatherSnapshot(
        temperatureC: 20.0,
        windKmh: 7.0,
        gustKmh: 11.0,
        sceneKey: SceneKey.partlyCloudy,
        cloudCoverPercent: 38,
        visibilityKm: 10.0,
        conditionText: 'Partly cloudy',
      );
    }
    if (p.cityName.toLowerCase() == 'denver') {
      return const WeatherSnapshot(
        temperatureC: 3.0,
        windKmh: 22.0,
        gustKmh: 34.0,
        sceneKey: SceneKey.clear,
        cloudCoverPercent: 12,
        visibilityKm: 16.0,
        conditionText: 'Clear',
      );
    }

    final seed = p.id.hashCode ^ p.cityName.hashCode;
    final temp = 12.0 + ((seed % 180) / 10.0);
    final wind = 4.0 + ((seed % 70) / 10.0);
    return WeatherSnapshot(
      temperatureC: temp,
      windKmh: wind,
      gustKmh: wind + 4.0,
      sceneKey: SceneKey.partlyCloudy,
      cloudCoverPercent: 40 + (seed.abs() % 25),
      visibilityKm: 10.0,
      conditionText: 'Partly cloudy',
    );
  }

  SunTimesSnapshot _seedSunTimes(Place p, DateTime nowUtc) {
    final localNow = TimezoneUtils.nowInZone(
      p.timeZoneId,
      nowUtc: nowUtc,
    ).local;
    final localDay = DateTime.utc(localNow.year, localNow.month, localNow.day);

    DateTime toUtc(DateTime localWallClock) =>
        TimezoneUtils.localToUtc(p.timeZoneId, localWallClock);

    DateTime wall(int h, int m) =>
        DateTime.utc(localDay.year, localDay.month, localDay.day, h, m);

    final city = p.cityName.toLowerCase();
    if (city == 'lisbon') {
      return SunTimesSnapshot(
        sunriseUtc: toUtc(wall(7, 52)),
        sunsetUtc: toUtc(wall(17, 29)),
      );
    }
    if (city == 'denver') {
      return SunTimesSnapshot(
        sunriseUtc: toUtc(wall(7, 5)),
        sunsetUtc: toUtc(wall(17, 5)),
      );
    }

    final seed = p.id.hashCode ^ (p.cityName.hashCode << 1);
    final sunriseMinutes = 360 + (seed.abs() % 150);
    final sunsetMinutes = 990 + (seed.abs() % 120);

    final sunriseLocal = localDay.add(Duration(minutes: sunriseMinutes));
    final sunsetLocal = localDay.add(Duration(minutes: sunsetMinutes));

    return SunTimesSnapshot(
      sunriseUtc: toUtc(sunriseLocal),
      sunsetUtc: toUtc(sunsetLocal),
    );
  }

  WeatherSnapshot _refreshWeather(Place p) {
    final current = _weatherByPlaceId[p.id] ?? _seedWeather(p);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final phase = (p.id.hashCode ^ (p.cityName.hashCode << 1)) % 900000;
    final drift = math.sin((nowMs + phase) / 60000) * 0.8;
    return WeatherSnapshot(
      temperatureC: (current.temperatureC + drift).clamp(-30.0, 45.0),
      windKmh: current.windKmh,
      gustKmh: current.gustKmh,
      sceneKey: current.sceneKey,
      cloudCoverPercent: current.cloudCoverPercent,
      visibilityKm: current.visibilityKm,
      conditionText: current.conditionText,
      conditionCode: current.conditionCode,
    );
  }

  WeatherForecastSnapshot _seedForecast(Place p, DateTime nowUtc) {
    final seed = (p.id.hashCode ^ p.cityName.hashCode).abs();
    final base =
        _weatherByPlaceId[p.id]?.temperatureC ?? _seedWeather(p).temperatureC;

    final hourly = <HourlyForecastPoint>[];
    for (var i = 1; i <= 24; i += 1) {
      final temp =
          base +
          math.sin((i / 24.0) * math.pi * 2.0) * 3.5 +
          ((seed % 7) - 3) * 0.1;
      hourly.add(
        HourlyForecastPoint(
          timeUtc: nowUtc.add(Duration(hours: i)),
          temperatureC: temp.clamp(-35.0, 48.0),
          precipitationChancePercent: _seedHourlyPrecipChance(
            cityName: p.cityName,
            seed: seed,
            hourOffset: i,
          ),
        ),
      );
    }

    final daily = <DailyForecastPoint>[];
    for (var i = 0; i < 7; i += 1) {
      final trend = (i - 3) * 0.6;
      final max = (base + 4.0 + trend + ((seed + i) % 5) * 0.2).clamp(
        -30.0,
        50.0,
      );
      final min = (base - 4.0 + trend - ((seed + i) % 4) * 0.2).clamp(
        -40.0,
        42.0,
      );
      final day = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
      ).add(Duration(days: i));
      daily.add(
        DailyForecastPoint(
          dayUtc: day,
          maxTemperatureC: max,
          minTemperatureC: min,
          precipitationChancePercent: _seedDailyPrecipChance(
            cityName: p.cityName,
            seed: seed,
            dayOffset: i,
          ),
        ),
      );
    }

    return WeatherForecastSnapshot(hourly: hourly, daily: daily);
  }

  int _seedHourlyPrecipChance({
    required String cityName,
    required int seed,
    required int hourOffset,
  }) {
    final city = cityName.toLowerCase();
    if (city == 'lisbon' || city == 'porto') {
      final scripted = <int>[55, 48, 36, 28, 20, 15];
      if (hourOffset - 1 < scripted.length) return scripted[hourOffset - 1];
    }
    if (city == 'denver') {
      final scripted = <int>[12, 10, 8, 6, 4, 4];
      if (hourOffset - 1 < scripted.length) return scripted[hourOffset - 1];
    }
    return (seed + hourOffset * 17) % 65;
  }

  int _seedDailyPrecipChance({
    required String cityName,
    required int seed,
    required int dayOffset,
  }) {
    final city = cityName.toLowerCase();
    if (city == 'lisbon' || city == 'porto') {
      final scripted = <int>[55, 44, 35, 30, 24, 18, 22];
      return scripted[dayOffset.clamp(0, scripted.length - 1)];
    }
    if (city == 'denver') {
      final scripted = <int>[15, 12, 10, 18, 22, 16, 14];
      return scripted[dayOffset.clamp(0, scripted.length - 1)];
    }
    return (seed + dayOffset * 23) % 70;
  }
}
