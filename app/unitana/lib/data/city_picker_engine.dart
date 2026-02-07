import 'city_picker_ranking.dart';

class CityPickerEngineEntry<T> {
  final T value;
  final String key;
  final String cityNameNorm;
  final String countryNorm;
  final String countryCode;
  final String timeZoneId;
  final String searchText;
  final bool lowSignal;
  final int baseScore;

  const CityPickerEngineEntry({
    required this.value,
    required this.key,
    required this.cityNameNorm,
    required this.countryNorm,
    required this.countryCode,
    required this.timeZoneId,
    required this.searchText,
    required this.lowSignal,
    required this.baseScore,
  });
}

class CityPickerEngine {
  const CityPickerEngine._();

  static List<CityPickerEngineEntry<T>> buildEntries<T>({
    required List<T> items,
    required String Function(T item) keyOf,
    required String Function(T item) cityNameOf,
    required String Function(T item) countryCodeOf,
    required String Function(T item) countryNameOf,
    required String Function(T item) timeZoneIdOf,
    Iterable<String> Function(T item)? extraSearchTermsOf,
    bool Function(T item)? isCurated,
    int mainstreamCountryBonus = 60,
  }) {
    final out = <CityPickerEngineEntry<T>>[];
    out.length = 0;
    for (final item in items) {
      final key = keyOf(item).trim().toLowerCase();
      if (key.isEmpty) continue;
      final cityRaw = cityNameOf(item);
      final cityNorm = normalizeQuery(cityRaw);
      if (cityNorm.isEmpty) continue;
      final countryCode = countryCodeOf(item).trim().toUpperCase();
      final countryNorm = normalizeQuery(countryNameOf(item));
      final timeZoneId = timeZoneIdOf(item).trim();
      final lowSignal = _isLowSignal(cityRaw);
      var baseScore = 0;
      if (isCurated?.call(item) ?? false) baseScore += 260;
      if (timeZoneId.isNotEmpty) {
        baseScore += CityPickerRanking.hubPriorityBonus(timeZoneId);
      }
      if (CityPickerRanking.isMainstreamCountryCode(countryCode)) {
        baseScore += mainstreamCountryBonus;
      }
      if (lowSignal) baseScore -= 120;
      if (RegExp(r'\d').hasMatch(cityRaw)) baseScore -= 35;
      baseScore -= cityNorm.length ~/ 4;

      final parts = <String>[
        cityRaw,
        countryCode,
        countryNameOf(item),
        if (timeZoneId.isNotEmpty) timeZoneId,
        ...?extraSearchTermsOf?.call(item),
      ];
      final searchText = normalizeQuery(parts.join(' '));
      out.add(
        CityPickerEngineEntry<T>(
          value: item,
          key: key,
          cityNameNorm: cityNorm,
          countryNorm: countryNorm,
          countryCode: countryCode,
          timeZoneId: timeZoneId,
          searchText: searchText,
          lowSignal: lowSignal,
          baseScore: baseScore,
        ),
      );
    }
    return out;
  }

  static List<CityPickerEngineEntry<T>> sortByBaseScore<T>(
    List<CityPickerEngineEntry<T>> entries,
  ) {
    final out = entries.toList(growable: false)
      ..sort((a, b) {
        final byScore = b.baseScore.compareTo(a.baseScore);
        if (byScore != 0) return byScore;
        return a.cityNameNorm.compareTo(b.cityNameNorm);
      });
    return out;
  }

  static List<CityPickerEngineEntry<T>> topEntries<T>({
    required List<CityPickerEngineEntry<T>> rankedEntries,
    int limit = 24,
    Set<String> preferredTimeZoneIds = const <String>{},
    bool dedupeByTimeZone = true,
    bool dedupeByCityToken = true,
    bool includeLowSignal = false,
  }) {
    final out = <CityPickerEngineEntry<T>>[];
    final seenZones = <String>{};
    final seenCityTokens = <String>{};

    bool accept(CityPickerEngineEntry<T> row, {required bool isPreferred}) {
      if (!includeLowSignal && !isPreferred && row.lowSignal) return false;
      if (dedupeByTimeZone &&
          row.timeZoneId.isNotEmpty &&
          !seenZones.add(row.timeZoneId)) {
        return false;
      }
      if (dedupeByCityToken) {
        final token = row.cityNameNorm.replaceAll(' ', '');
        if (token.isNotEmpty && !seenCityTokens.add(token)) return false;
      }
      out.add(row);
      return true;
    }

    for (final row in rankedEntries) {
      if (out.length >= limit) break;
      if (!preferredTimeZoneIds.contains(row.timeZoneId)) continue;
      accept(row, isPreferred: true);
    }
    for (final row in rankedEntries) {
      if (out.length >= limit) break;
      if (preferredTimeZoneIds.contains(row.timeZoneId)) continue;
      accept(row, isPreferred: false);
    }
    return out;
  }

  static List<CityPickerEngineEntry<T>> searchEntries<T>({
    required List<CityPickerEngineEntry<T>> entries,
    required String queryRaw,
    Set<String> preferredTimeZoneIds = const <String>{},
    Set<String> aliasTimeZoneIds = const <String>{},
    int maxCandidates = 220,
    int maxResults = 100,
    bool shortQueryAllowsTimeZonePrefix = false,
    bool dedupeByTimeZone = false,
  }) {
    final query = normalizeQuery(queryRaw);
    if (query.isEmpty) return <CityPickerEngineEntry<T>>[];
    final tokens = tokenize(query);
    final shortQuery = query.length <= 3;
    final scored = <({CityPickerEngineEntry<T> row, int score})>[];

    for (final row in entries) {
      final haystack = row.searchText;
      var matches = true;
      for (final token in tokens) {
        if (!haystack.contains(token)) {
          matches = false;
          break;
        }
      }
      if (!matches && !aliasTimeZoneIds.contains(row.timeZoneId)) continue;

      if (shortQuery &&
          !aliasTimeZoneIds.contains(row.timeZoneId) &&
          !hasTokenBoundary(row.cityNameNorm, query) &&
          !row.cityNameNorm.startsWith(query) &&
          !hasTokenBoundary(row.countryNorm, query) &&
          !row.countryNorm.startsWith(query) &&
          !(shortQueryAllowsTimeZonePrefix &&
              row.timeZoneId.toLowerCase().startsWith(
                queryRaw.toLowerCase(),
              ))) {
        continue;
      }

      var score = row.baseScore;
      if (preferredTimeZoneIds.contains(row.timeZoneId)) score += 260;
      if (aliasTimeZoneIds.contains(row.timeZoneId)) score += 220;
      if (row.cityNameNorm.startsWith(query)) score += 180;
      if (row.cityNameNorm.contains(' $query')) score += 100;
      if (row.countryNorm.startsWith(query) ||
          row.countryNorm.contains(' $query')) {
        score += 70;
      }
      if (row.timeZoneId.toLowerCase().contains(queryRaw.toLowerCase())) {
        score += 50;
      }
      scored.add((row: row, score: score));
      if (scored.length >= maxCandidates) break;
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.row.cityNameNorm.compareTo(b.row.cityNameNorm);
    });

    final out = <CityPickerEngineEntry<T>>[];
    final seenKeys = <String>{};
    final seenZones = <String>{};
    for (final row in scored) {
      if (out.length >= maxResults) break;
      if (!seenKeys.add(row.row.key)) continue;
      if (dedupeByTimeZone &&
          row.row.timeZoneId.isNotEmpty &&
          !seenZones.add(row.row.timeZoneId)) {
        continue;
      }
      out.add(row.row);
    }
    return out;
  }

  static bool hasTokenBoundary(String haystack, String token) {
    final escaped = RegExp.escape(token);
    return RegExp('(^| )$escaped').hasMatch(haystack);
  }

  static List<String> tokenize(String query) {
    final raw = query
        .split(' ')
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false);
    if (raw.length >= 2 && raw.every((t) => t.length == 1)) {
      return <String>[raw.join()];
    }
    return raw;
  }

  static String normalizeQuery(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';
    s = foldDiacritics(s).toLowerCase();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String foldDiacritics(String input) {
    var s = input;
    const map = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'Ç': 'C',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ñ': 'N',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ý': 'Y',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  static bool _isLowSignal(String cityRaw) {
    final clean = cityRaw.trim();
    if (clean.isEmpty) return true;
    if (RegExp(r'^[^A-Za-z0-9]').hasMatch(clean)) return true;
    if (RegExp(r'\d{2,}').hasMatch(clean)) return true;
    return false;
  }

  static String continentName(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'NA':
        return 'north america';
      case 'SA':
        return 'south america';
      case 'EU':
        return 'europe';
      case 'AF':
        return 'africa';
      case 'AS':
        return 'asia';
      case 'OC':
        return 'oceania';
      default:
        return '';
    }
  }
}
