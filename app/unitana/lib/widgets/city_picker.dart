import 'package:flutter/material.dart';

import '../data/cities.dart';

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

  String _query = '';

  @override
  void initState() {
    super.initState();
    _curatedIds = {for (final c in kCuratedCities) c.id};
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
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
                  hintText: 'Search city, country, code, timezone',
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
                  hasQuery ? 'Best Matches' : 'Popular Cities',
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
                            'No matches yet. Try city, country, timezone, or EST.',
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
                            leading: selected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : const Icon(Icons.location_city_outlined),
                            title: Text(_sanitizeLabel(city.cityName)),
                            subtitle: Text(_subtitle(city)),
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

  String _sanitizeLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    return trimmed.replaceFirst(RegExp(r"^[^A-Za-z0-9]+"), '');
  }

  List<City> _filter(List<City> all, String queryRaw) {
    final q = _normQuery(queryRaw);
    if (q.isEmpty) {
      // Prefer curated cities when query is empty (no need for kPopularCityIds).
      final popular = <City>[];
      final byId = {for (final c in all) c.id: c};

      for (final curated in kCuratedCities) {
        // Use dataset copy when present; fall back to curated entry.
        popular.add(byId[curated.id] ?? curated);
      }

      return popular.isEmpty ? all.take(150).toList(growable: false) : popular;
    }

    final tokens = _tokenize(q);
    final shortQuery = q.length <= 3;

    bool hasTokenBoundary(String haystack, String token) {
      final escaped = RegExp.escape(token);
      return RegExp('(^| )$escaped').hasMatch(haystack);
    }

    // Safety valve: keep the list snappy on broad searches.
    const maxResults = 220;
    final ranked = <({City city, int score})>[];

    for (final c in all) {
      final haystack = _buildHaystack(c);
      var ok = true;
      for (final t in tokens) {
        if (!haystack.contains(t)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      if (shortQuery &&
          !hasTokenBoundary(haystack, q) &&
          !(c.timeZoneId.toLowerCase().contains(q))) {
        continue;
      }

      var score = 0;
      final cityName = _normQuery(c.cityName);
      final country = _normQuery(c.countryName ?? c.countryCode);
      if (_curatedIds.contains(c.id)) score += 260;
      if (cityName.startsWith(q)) score += 180;
      if (cityName.contains(' $q')) score += 100;
      if (country.startsWith(q) || country.contains(' $q')) score += 70;
      if (c.timeZoneId.toLowerCase().contains(q)) score += 50;
      score -= cityName.length ~/ 4;
      ranked.add((city: c, score: score));
      if (ranked.length >= maxResults) break;
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final an = _normQuery(a.city.cityName);
      final bn = _normQuery(b.city.cityName);
      return an.compareTo(bn);
    });

    return ranked.map((r) => r.city).toList(growable: false);
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
      c.timeZoneId,
      ..._tzAbbrsFor(c.timeZoneId),
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

  List<String> _tzAbbrsFor(String iana) {
    switch (iana) {
      case 'America/New_York':
        return const ['est', 'edt'];
      case 'America/Chicago':
        return const ['cst', 'cdt'];
      case 'America/Denver':
        return const ['mst', 'mdt'];
      case 'America/Los_Angeles':
        return const ['pst', 'pdt'];
      case 'Europe/London':
        return const ['gmt', 'bst'];
      case 'Europe/Lisbon':
        return const ['wet', 'west'];
      case 'Europe/Paris':
        return const ['cet', 'cest'];
      default:
        return const [];
    }
  }
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
