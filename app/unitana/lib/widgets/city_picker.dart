import 'package:flutter/material.dart';
import '../data/cities.dart';

Future<City?> showCityPicker(BuildContext context, {City? initial}) async {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CityPickerSheet(initial: initial),
  );
}

class _CityPickerSheet extends StatefulWidget {
  final City? initial;
  const _CityPickerSheet({this.initial});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? kCities
        : kCities.where((c) {
            final hay = '${c.name} ${c.country} ${c.timeZone}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search city',
                hintText: 'Lisbon, Denver, Tokyo…',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final city = filtered[i];
                  return ListTile(
                    title: Text(city.label),
                    subtitle: Text(city.timeZone),
                    onTap: () => Navigator.of(context).pop(city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

