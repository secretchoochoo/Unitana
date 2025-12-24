import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../models/place.dart';
import '../../widgets/city_picker.dart';
import '../../data/cities.dart';
import '../dashboard/dashboard_screen.dart';

enum UnitSystem { imperial, metric }

class FirstRunScreen extends StatefulWidget {
  final UnitanaAppState state;
  const FirstRunScreen({super.key, required this.state});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  int step = 0; // 0 = Living, 1 = Visiting

  // Living
  final livingNameCtrl = TextEditingController(text: 'Living');
  City? livingHomeCity = const City(name: 'Denver', country: 'US', timeZone: 'America/Denver');
  City? livingLocalCity = const City(name: 'Lisbon', country: 'PT', timeZone: 'Europe/Lisbon');
  UnitSystem livingHomeSystem = UnitSystem.imperial;
  UnitSystem livingLocalSystem = UnitSystem.metric; // advanced only

  // Visiting
  final visitingNameCtrl = TextEditingController(text: 'Visiting');
  City? visitingHomeCity; // inherits living home
  City? visitingLocalCity = const City(name: 'Lisbon', country: 'PT', timeZone: 'Europe/Lisbon');
  UnitSystem visitingHomeSystem = UnitSystem.imperial; // advanced only
  UnitSystem visitingLocalSystem = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    _syncVisitingFromLiving();
  }

  void _syncVisitingFromLiving() {
    visitingHomeCity = livingHomeCity;
    visitingHomeSystem = livingHomeSystem;
  }

  @override
  void dispose() {
    livingNameCtrl.dispose();
    visitingNameCtrl.dispose();
    super.dispose();
  }

  String? _validateStep() {
    if (step == 0) {
      if (livingNameCtrl.text.trim().isEmpty) return 'Give your Living Place a name.';
      if (livingHomeCity == null) return 'Pick a Home city for Living.';
      if (livingLocalCity == null) return 'Pick a Local city for Living.';
      return null;
    } else {
      if (visitingNameCtrl.text.trim().isEmpty) return 'Give your Visiting Place a name.';
      if (visitingHomeCity == null) return 'Pick a Home city for Visiting.';
      if (visitingLocalCity == null) return 'Pick a Local city for Visiting.';
      return null;
    }
  }

  Future<void> _saveAndContinue() async {
    final err = _validateStep();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    if (step == 0) {
      setState(() {
        step = 1;
        _syncVisitingFromLiving();
        // Default Visiting local city to Living local if user already picked one
        visitingLocalCity = visitingLocalCity ?? livingLocalCity;
        visitingLocalSystem = visitingLocalSystem; // keep
      });
      return;
    }

    final living = Place(
      id: 'living_v1',
      type: PlaceType.living,
      name: livingNameCtrl.text.trim(),
      homeTimeZone: livingHomeCity!.timeZone,
      localTimeZone: livingLocalCity!.timeZone,
      homeSystem: livingHomeSystem.name,
      localSystem: livingLocalSystem.name,
    );

    final visiting = Place(
      id: 'visiting_v1',
      type: PlaceType.visiting,
      name: visitingNameCtrl.text.trim(),
      homeTimeZone: visitingHomeCity!.timeZone,
      localTimeZone: visitingLocalCity!.timeZone,
      homeSystem: visitingHomeSystem.name,
      localSystem: visitingLocalSystem.name,
    );

    await widget.state.setPlaces(
      newPlaces: [living, visiting],
      newDefaultPlaceId: living.id,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardScreen(state: widget.state)),
    );
  }

  void _prefillExample() {
    setState(() {
      livingNameCtrl.text = 'Living';
      livingHomeCity = const City(name: 'Denver', country: 'US', timeZone: 'America/Denver');
      livingLocalCity = const City(name: 'Lisbon', country: 'PT', timeZone: 'Europe/Lisbon');
      livingHomeSystem = UnitSystem.imperial;
      livingLocalSystem = UnitSystem.metric;

      visitingNameCtrl.text = 'Visiting';
      visitingHomeCity = livingHomeCity;
      visitingLocalCity = const City(name: 'Porto', country: 'PT', timeZone: 'Europe/Lisbon');
      visitingHomeSystem = livingHomeSystem;
      visitingLocalSystem = UnitSystem.metric;
    });
  }

  Widget _segmentedUnit(UnitSystem value, ValueChanged<UnitSystem> onChanged) {
    return SegmentedButton<UnitSystem>(
      segments: const [
        ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
        ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
      ],
      selected: <UnitSystem>{value},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }

  Widget _cityRow({
    required String label,
    required City? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? 'Choose a city' : '${value.label}  •  ${value.timeZone}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiving = step == 0;
    final title = isLiving ? 'Create Living Place' : 'Create Visiting Place';
    final subtitle = isLiving
        ? 'This is your default baseline setup. You can change it later.'
        : 'A second Place for travel or comparison.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _prefillExample,
            child: const Text('Prefill'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(subtitle),
          const SizedBox(height: 16),

          TextField(
            controller: isLiving ? livingNameCtrl : visitingNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Place name',
              hintText: 'Living',
            ),
          ),
          const SizedBox(height: 16),

          // City selection (replaces manual IANA entry)
          _cityRow(
            label: 'Home city',
            value: isLiving ? livingHomeCity : visitingHomeCity,
            onTap: () async {
              final picked = await showCityPicker(context, initial: isLiving ? livingHomeCity : visitingHomeCity);
              if (picked == null) return;
              setState(() {
                if (isLiving) {
                  livingHomeCity = picked;
                  _syncVisitingFromLiving();
                } else {
                  visitingHomeCity = picked;
                }
              });
            },
          ),
          _cityRow(
            label: 'Local city',
            value: isLiving ? livingLocalCity : visitingLocalCity,
            onTap: () async {
              final picked = await showCityPicker(context, initial: isLiving ? livingLocalCity : visitingLocalCity);
              if (picked == null) return;
              setState(() {
                if (isLiving) {
                  livingLocalCity = picked;
                } else {
                  visitingLocalCity = picked;
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // Simplified unit selection:
          // Living: show Home units only (Local units in Advanced)
          // Visiting: show Local units only (Home units in Advanced)
          if (isLiving) ...[
            const Text('Home unit system'),
            const SizedBox(height: 8),
            _segmentedUnit(livingHomeSystem, (v) {
              setState(() {
                livingHomeSystem = v;
                _syncVisitingFromLiving();
              });
            }),
          ] else ...[
            const Text('Local unit system'),
            const SizedBox(height: 8),
            _segmentedUnit(visitingLocalSystem, (v) {
              setState(() => visitingLocalSystem = v);
            }),
          ],

          const SizedBox(height: 20),

          ExpansionTile(
            title: const Text('Advanced'),
            childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
            children: [
              if (isLiving) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Local unit system (optional)'),
                ),
                const SizedBox(height: 8),
                _segmentedUnit(livingLocalSystem, (v) => setState(() => livingLocalSystem = v)),
                const SizedBox(height: 16),
              ] else ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Home unit system (optional)'),
                ),
                const SizedBox(height: 8),
                _segmentedUnit(visitingHomeSystem, (v) => setState(() => visitingHomeSystem = v)),
                const SizedBox(height: 16),
              ],

              // Show the IANA time zones for transparency
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isLiving
                      ? 'Living time zones: ${livingHomeCity?.timeZone} → ${livingLocalCity?.timeZone}'
                      : 'Visiting time zones: ${visitingHomeCity?.timeZone} → ${visitingLocalCity?.timeZone}',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              if (!isLiving)
                TextButton(
                  onPressed: () => setState(() => step = 0),
                  child: const Text('Back'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveAndContinue,
                child: Text(isLiving ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

