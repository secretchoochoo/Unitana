import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unitana/data/cities.dart';

class CityPicker extends StatefulWidget {
  final List<City> cities;
  final City? selected;

  const CityPicker({super.key, required this.cities, this.selected});

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  static const int _maxResults = 200;

  final TextEditingController _queryCtrl = TextEditingController();

  Timer? _debounce;
  String _q = '';

  late List<City> _sorted;
  late Map<String, String> _searchIndexById;

  @override
  void initState() {
    super.initState();
    _rehydrateIndexes(widget.cities);
  }

  @override
  void didUpdateWidget(covariant CityPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cities != widget.cities) {
      _rehydrateIndexes(widget.cities);
    }
  }

  void _rehydrateIndexes(List<City> cities) {
    _sorted = List<City>.from(cities)
      ..sort((a, b) => a.display.toLowerCase().compareTo(b.display.toLowerCase()));

    _searchIndexById = {
      for (final c in _sorted) c.id: _buildSearchIndex(c),
    };
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() => _q = v);
    });
  }

  String _buildSearchIndex(City c) {
    final tokens = <String>[
      c.cityName,
      c.countryCode,
      c.countryName,
      c.timeZoneId,
      c.currencyCode,
      if (c.admin1Code != null) c.admin1Code!,
      if (c.admin1Name != null) c.admin1Name!,
      ..._countryAliases(c),
      ..._timeZoneAliases(c.timeZoneId),
      ..._currencyAliases(c.currencyCode),
    ];

    final joined = tokens
        .where((t) => t.trim().isNotEmpty)
        .join(' ')
        .toLowerCase();

    return joined;
  }

  List<String> _countryAliases(City c) {
    // Keep this conservative and obvious.
    // Expand as we learn real user queries.
    final cc = c.countryCode.toUpperCase();
    if (cc == 'US') return const ['usa', 'u.s.', 'united states', 'america'];
    if (cc == 'GB') return const ['uk', 'u.k.', 'united kingdom', 'britain'];
    if (cc == 'PT') return const ['portugal'];
    return const [];
  }

  List<String> _currencyAliases(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (code == 'EUR') return const ['euro', 'eu'];
    if (code == 'USD') return const ['dollar', 'usd'];
    if (code == 'GBP') return const ['pound', 'sterling'];
    if (code == 'CAD') return const ['canadian dollar'];
    return const [];
  }

  List<String> _timeZoneAliases(String timeZoneId) {
    // MVP mapping: add common acronyms as search tokens.
    // This does not attempt to model DST precisely; it only improves findability.
    switch (timeZoneId) {
      case 'America/Denver':
        return const ['mst', 'mdt', 'mountain'];
      case 'America/Los_Angeles':
        return const ['pst', 'pdt', 'pacific'];
      case 'America/New_York':
        return const ['est', 'edt', 'eastern'];
      case 'America/Chicago':
        return const ['cst', 'cdt', 'central'];
      case 'Europe/Lisbon':
        return const ['wet', 'west', 'gmt'];
      case 'Europe/London':
        return const ['gmt', 'bst'];
      case 'Europe/Paris':
        return const ['cet', 'cest'];
      default:
        return const [];
    }
  }

  String _subtitleFor(City c) {
    final country = c.countryName.trim().isEmpty ? c.countryCode : c.countryName;

    final regionParts = <String>[];
    if ((c.admin1Name ?? '').trim().isNotEmpty) regionParts.add(c.admin1Name!.trim());
    if ((c.admin1Code ?? '').trim().isNotEmpty) regionParts.add(c.admin1Code!.trim());

    final region = regionParts.isEmpty ? null : regionParts.join(' · ');
    final left = region == null ? country : '$country · $region';

    return '$left · ${c.timeZoneId} · ${c.currencyCode}';
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();

    final matches = q.isEmpty
        ? _sorted
        : _sorted
            .where((c) => (_searchIndexById[c.id] ?? '').contains(q))
            .toList(growable: false);

    final limited = matches.length > _maxResults
        ? matches.take(_maxResults).toList(growable: false)
        : matches;

    final countLabel = matches.length > _maxResults
        ? 'Showing $_maxResults of ${matches.length} matches'
        : '${matches.length} matches';

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a city',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop<City?>(null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _queryCtrl,
                decoration: InputDecoration(
                  hintText: 'Search city, country, region, time zone, currency…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _queryCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _debounce?.cancel();
                              _queryCtrl.clear();
                              _q = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear',
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  countLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: limited.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = limited[i];
                    final isSelected = widget.selected?.id == c.id;

                    return ListTile(
                      title: Text(c.display),
                      subtitle: Text(_subtitleFor(c)),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop<City>(c),
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
}
