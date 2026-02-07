import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../data/city_label_utils.dart';
import '../data/city_picker_ranking.dart';

class CityPicker extends StatefulWidget {
  final List<City> cities;
  final City? selected;

  const CityPicker({super.key, required this.cities, this.selected});

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _curatedIds;
  late List<_IndexedCity> _indexedCities;
  late List<City> _defaultTopCities;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _curatedIds = {for (final c in kCuratedCities) c.id};
    _rebuildIndex();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void didUpdateWidget(covariant CityPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cities, widget.cities)) {
      _rebuildIndex();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = _filter(widget.cities, _query);
    final hasQuery = _normQuery(_query).isNotEmpty;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose a city',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search city or country',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hasQuery ? 'Best Matches' : 'Top Cities',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: cities.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                          child: Text(
                            'No matches yet. Try city or country.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final selected = widget.selected?.id == city.id;

                          return ListTile(
                            leading: const Icon(Icons.location_city_outlined),
                            title: Text(
                              [
                                CityLabelUtils.countryFlag(city.countryCode),
                                CityLabelUtils.cleanCityName(city.cityName),
                              ].where((part) => part.isNotEmpty).join(' '),
                            ),
                            subtitle: Text(_subtitle(city)),
                            trailing: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(city),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(City city) {
    final parts = <String>[
      if ((city.admin1Name ?? '').isNotEmpty) city.admin1Name!,
      if ((city.countryName ?? '').isNotEmpty) city.countryName!,
      if (city.countryName == null || city.countryName!.isEmpty)
        city.countryCode,
    ];

    // Add quick timezone hint without making the line too long.
    final tz = city.timeZoneId;
    if (tz.isNotEmpty) {
      parts.add(tz);
    }

    return parts.join(' • ');
  }

  List<City> _filter(List<City> all, String queryRaw) {
    final q = _normQuery(queryRaw);
    if (q.isEmpty) {
      return _defaultTopCities;
    }

    final tokens = _tokenize(q);
    final shortQuery = q.length <= 3;

    bool hasTokenBoundary(String haystack, String token) {
      final escaped = RegExp.escape(token);
      return RegExp('(^| )$escaped').hasMatch(haystack);
    }

    // Safety valve: keep the list snappy on broad searches.
    const maxResults = 220;
    final ranked = <({City city, int score, String sortKey})>[];
    for (final idx in _indexedCities) {
      var ok = true;
      for (final t in tokens) {
        if (!idx.haystack.contains(t)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      if (shortQuery &&
          !hasTokenBoundary(idx.cityNameNorm, q) &&
          !idx.cityNameNorm.startsWith(q) &&
          !hasTokenBoundary(idx.countryNorm, q) &&
          !idx.countryNorm.startsWith(q)) {
        continue;
      }
      var score = idx.baseScore;
      if (idx.cityNameNorm.startsWith(q)) score += 180;
      if (idx.cityNameNorm.contains(' $q')) score += 100;
      if (idx.countryNorm.startsWith(q) || idx.countryNorm.contains(' $q')) {
        score += 70;
      }
      ranked.add((city: idx.city, score: score, sortKey: idx.cityNameNorm));
      if (ranked.length >= maxResults) break;
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.sortKey.compareTo(b.sortKey);
    });

    final deduped = <City>[];
    final seen = <String>{};
    for (final row in ranked) {
      final key =
          '${_normQuery(row.city.cityName)}|${row.city.countryCode.toUpperCase()}|${row.city.timeZoneId}';
      if (!seen.add(key)) continue;
      deduped.add(row.city);
      if (deduped.length >= 100) break;
    }
    return deduped;
  }

  String _buildHaystack(City c) {
    final parts = <String>[
      c.cityName,
      c.countryCode,
      c.countryName ?? '',
      c.iso3 ?? '',
      c.admin1Name ?? '',
      c.admin1Code ?? '',
      c.continent ?? '',
      _continentName(c.continent),
      c.currencyCode,
      c.currencySymbol ?? '',
      c.currencySymbolNarrow ?? '',
      c.currencySymbolNative ?? '',
    ];

    // Add common shorthand.
    if (c.countryCode.toUpperCase() == 'US') {
      parts.addAll(['USA', 'UNITED STATES', 'U S']);
    }
    if (c.countryCode.toUpperCase() == 'GB') {
      parts.addAll(['UK', 'UNITED KINGDOM', 'GREAT BRITAIN']);
    }

    return _normQuery(parts.join(' '));
  }

  void _rebuildIndex() {
    _indexedCities = widget.cities
        .map((city) {
          final cityNorm = _normQuery(city.cityName);
          final countryNorm = _normQuery(city.countryName ?? city.countryCode);
          var baseScore = 0;
          if (_curatedIds.contains(city.id)) baseScore += 260;
          baseScore += CityPickerRanking.hubPriorityBonus(city.timeZoneId);
          if (CityPickerRanking.isMainstreamCountryCode(city.countryCode)) {
            baseScore += 60;
          }
          if (RegExp(r'^[^A-Za-z0-9]').hasMatch(city.cityName.trim())) {
            baseScore -= 120;
          }
          if (RegExp(r'\d').hasMatch(city.cityName)) baseScore -= 35;
          baseScore -= cityNorm.length ~/ 4;
          return _IndexedCity(
            city: city,
            haystack: _buildHaystack(city),
            cityNameNorm: cityNorm,
            countryNorm: countryNorm,
            baseScore: baseScore,
          );
        })
        .toList(growable: false);
    _defaultTopCities = _buildDefaultTopCities();
  }

  List<City> _buildDefaultTopCities() {
    final ranked = _indexedCities.toList(growable: false)
      ..sort((a, b) {
        final byScore = b.baseScore.compareTo(a.baseScore);
        if (byScore != 0) return byScore;
        return a.cityNameNorm.compareTo(b.cityNameNorm);
      });
    final out = <City>[];
    final seenZones = <String>{};
    final seenCityTokens = <String>{};
    for (final row in ranked) {
      if (!seenZones.add(row.city.timeZoneId)) continue;
      final cityToken = row.cityNameNorm.split(' ').join();
      if (cityToken.isNotEmpty && !seenCityTokens.add(cityToken)) continue;
      out.add(row.city);
      if (out.length >= 24) break;
    }
    return out;
  }

  List<String> _tokenize(String q) {
    final raw = q
        .split(' ')
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false);

    // If the user typed an abbreviation as spaced letters ("u s a"), collapse it.
    if (raw.length >= 2 && raw.every((t) => t.length == 1)) {
      return [raw.join()];
    }

    return raw;
  }

  String _normQuery(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';

    // Fold diacritics.
    s = CityPickerUtils.foldDiacritics(s);

    // Keep letters/numbers, turn other chars into spaces.
    s = s.toLowerCase();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  String _continentName(String? code) {
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

class _IndexedCity {
  final City city;
  final String haystack;
  final String cityNameNorm;
  final String countryNorm;
  final int baseScore;

  const _IndexedCity({
    required this.city,
    required this.haystack,
    required this.cityNameNorm,
    required this.countryNorm,
    required this.baseScore,
  });
}

/// Shared helpers, kept separate so CityRepository can reuse without importing UI.
class CityPickerUtils {
  static String foldDiacritics(String input) {
    var s = input;
    const map = {
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

    map.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    return s;
  }
}
