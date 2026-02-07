import 'package:flutter/material.dart';

import '../common/debug/picker_perf_trace.dart';
import '../data/cities.dart';
import '../data/city_picker_engine.dart';
import '../data/city_label_utils.dart';
import '../l10n/city_picker_copy.dart';

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
  late List<CityPickerEngineEntry<City>> _indexedCities;
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
    final hasQuery = CityPickerEngine.normalizeQuery(_query).isNotEmpty;

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
                  Expanded(
                    child: Text(
                      CityPickerCopy.title(
                        context,
                        mode: CityPickerMode.cityOnly,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: CityPickerCopy.closeTooltip(context),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: CityPickerCopy.searchHint(
                    context,
                    mode: CityPickerMode.cityOnly,
                  ),
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
                  hasQuery
                      ? CityPickerCopy.bestMatchesHeader(context)
                      : CityPickerCopy.topHeader(context),
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
                            CityPickerCopy.emptyHint(
                              context,
                              mode: CityPickerMode.cityOnly,
                            ),
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
    final sw = PickerPerfTrace.start('wizard_city_filter');
    final q = CityPickerEngine.normalizeQuery(queryRaw);
    if (q.isEmpty) {
      PickerPerfTrace.logElapsed(
        'wizard_city_filter',
        sw,
        extra: 'query=empty results=${_defaultTopCities.length}',
      );
      return _defaultTopCities;
    }

    final results = CityPickerEngine.searchEntries(
      entries: _indexedCities,
      queryRaw: q,
      maxCandidates: 220,
      maxResults: 100,
      dedupeByTimeZone: false,
      dedupeByCityCountry: true,
    );
    final deduped = results.map((r) => r.value).toList(growable: false);
    PickerPerfTrace.logElapsed(
      'wizard_city_filter',
      sw,
      extra: 'query="$q" results=${deduped.length}',
      minMs: 6,
    );
    return deduped;
  }

  void _rebuildIndex() {
    final sw = PickerPerfTrace.start('wizard_city_index');
    _indexedCities = CityPickerEngine.buildEntries<City>(
      items: widget.cities,
      keyOf: (c) => c.id,
      cityNameOf: (c) => c.cityName,
      countryCodeOf: (c) => c.countryCode,
      countryNameOf: (c) => c.countryName ?? c.countryCode,
      timeZoneIdOf: (c) => c.timeZoneId,
      isCurated: (c) => _curatedIds.contains(c.id),
      mainstreamCountryBonus: 60,
      extraSearchTermsOf: (c) => <String>[
        c.iso3 ?? '',
        c.admin1Name ?? '',
        c.admin1Code ?? '',
        c.continent ?? '',
        CityPickerEngine.continentName(c.continent),
        c.currencyCode,
        c.currencySymbol ?? '',
        c.currencySymbolNarrow ?? '',
        c.currencySymbolNative ?? '',
        if (c.countryCode.toUpperCase() == 'US') ...const <String>[
          'USA',
          'UNITED STATES',
          'U S',
        ],
        if (c.countryCode.toUpperCase() == 'GB') ...const <String>[
          'UK',
          'UNITED KINGDOM',
          'GREAT BRITAIN',
        ],
      ],
    );
    _indexedCities = CityPickerEngine.sortByBaseScore(_indexedCities);
    _defaultTopCities = _buildDefaultTopCities();
    PickerPerfTrace.logElapsed(
      'wizard_city_index',
      sw,
      extra: 'cities=${widget.cities.length} top=${_defaultTopCities.length}',
      minMs: 4,
    );
  }

  List<City> _buildDefaultTopCities() {
    final top = CityPickerEngine.topEntries(
      rankedEntries: _indexedCities,
      limit: 24,
      dedupeByTimeZone: true,
      dedupeByCityToken: true,
    );
    return top.map((e) => e.value).toList(growable: false);
  }
}

/// Shared helpers, kept separate so CityRepository can reuse without importing UI.
class CityPickerUtils {
  static String foldDiacritics(String input) {
    return CityPickerEngine.foldDiacritics(input);
  }
}
