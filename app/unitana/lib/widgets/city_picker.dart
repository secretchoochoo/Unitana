import 'package:flutter/material.dart';

import '../data/cities.dart';

/// Bottom-sheet city picker.
///
/// Returns a [City] via `Navigator.pop(city)` or returns null on Cancel.
class CityPicker extends StatefulWidget {
  final List<City> cities;
  final City? selected;

  const CityPicker({super.key, required this.cities, this.selected});

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final TextEditingController _queryCtrl = TextEditingController();
  String _q = '';

  late final List<City> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = List<City>.from(widget.cities)
      ..sort(
        (a, b) => a.display.toLowerCase().compareTo(b.display.toLowerCase()),
      );
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _clearQuery() {
    setState(() {
      _queryCtrl.clear();
      _q = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _sorted
        : _sorted
              .where((c) {
                final hay =
                    '${c.display} ${c.timeZoneId} ${c.countryCode} ${c.currencyCode}'
                        .toLowerCase();
                return hay.contains(q);
              })
              .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose a city',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search city, country, time zone…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clearQuery,
                              icon: const Icon(Icons.close),
                              tooltip: 'Clear',
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = widget.selected?.id == c.id;
                      return ListTile(
                        title: Text(c.display),
                        subtitle: Text('${c.timeZoneId} · ${c.currencyCode}'),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
