import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../models/place.dart';
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
  final livingHomeTzCtrl = TextEditingController(text: 'America/Denver');
  final livingLocalTzCtrl = TextEditingController(text: 'Europe/Lisbon');
  UnitSystem livingHomeSystem = UnitSystem.imperial;
  UnitSystem livingLocalSystem = UnitSystem.metric;

  // Visiting
  final visitingNameCtrl = TextEditingController(text: 'Visiting');
  final visitingHomeTzCtrl = TextEditingController(); // will inherit living
  final visitingLocalTzCtrl = TextEditingController(text: 'Europe/Lisbon');
  UnitSystem visitingHomeSystem = UnitSystem.imperial; // will inherit living
  UnitSystem visitingLocalSystem = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    _syncVisitingFromLiving();
  }

  void _syncVisitingFromLiving() {
    visitingHomeTzCtrl.text = livingHomeTzCtrl.text;
    visitingHomeSystem = livingHomeSystem;
  }

  @override
  void dispose() {
    livingNameCtrl.dispose();
    livingHomeTzCtrl.dispose();
    livingLocalTzCtrl.dispose();
    visitingNameCtrl.dispose();
    visitingHomeTzCtrl.dispose();
    visitingLocalTzCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeIanaTz(String s) {
    // lightweight check: "Region/City"
    if (!s.contains('/')) return false;
    if (s.length < 3) return false;
    return true;
  }

  String? _validateStep() {
    if (step == 0) {
      if (livingNameCtrl.text.trim().isEmpty) return 'Give your Living Place a name.';
      if (!_looksLikeIanaTz(livingHomeTzCtrl.text.trim())) return 'Living home time zone should look like America/Denver.';
      if (!_looksLikeIanaTz(livingLocalTzCtrl.text.trim())) return 'Living local time zone should look like Europe/Lisbon.';
      return null;
    } else {
      if (visitingNameCtrl.text.trim().isEmpty) return 'Give your Visiting Place a name.';
      if (!_looksLikeIanaTz(visitingHomeTzCtrl.text.trim())) return 'Visiting home time zone should look like America/Denver.';
      if (!_looksLikeIanaTz(visitingLocalTzCtrl.text.trim())) return 'Visiting local time zone should look like Europe/Lisbon.';
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
        // Helpful: visiting local tz defaults to living local tz unless user changes it
        if (visitingLocalTzCtrl.text.trim().isEmpty) {
          visitingLocalTzCtrl.text = livingLocalTzCtrl.text.trim();
        }
        visitingLocalSystem = livingLocalSystem;
      });
      return;
    }

    // Step 1: Persist both places
    final living = Place(
      id: 'living_v1',
      type: PlaceType.living,
      name: livingNameCtrl.text.trim(),
      homeTimeZone: livingHomeTzCtrl.text.trim(),
      localTimeZone: livingLocalTzCtrl.text.trim(),
      homeSystem: livingHomeSystem.name,
      localSystem: livingLocalSystem.name,
    );

    final visiting = Place(
      id: 'visiting_v1',
      type: PlaceType.visiting,
      name: visitingNameCtrl.text.trim(),
      homeTimeZone: visitingHomeTzCtrl.text.trim(),
      localTimeZone: visitingLocalTzCtrl.text.trim(),
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
      livingNameCtrl.text = 'Living (US)';
      livingHomeTzCtrl.text = 'America/Denver';
      livingLocalTzCtrl.text = 'Europe/Lisbon';
      livingHomeSystem = UnitSystem.imperial;
      livingLocalSystem = UnitSystem.metric;

      visitingNameCtrl.text = 'Visiting (Portugal)';
      visitingHomeTzCtrl.text = livingHomeTzCtrl.text;
      visitingLocalTzCtrl.text = 'Europe/Lisbon';
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

  @override
  Widget build(BuildContext context) {
    final isLiving = step == 0;
    final title = isLiving ? 'Create Living Place' : 'Create Visiting Place';
    final subtitle = isLiving
        ? 'Your default reference setup. You can change this later.'
        : 'A second Place for travel or comparison.';

    final nameCtrl = isLiving ? livingNameCtrl : visitingNameCtrl;
    final homeTzCtrl = isLiving ? livingHomeTzCtrl : visitingHomeTzCtrl;
    final localTzCtrl = isLiving ? livingLocalTzCtrl : visitingLocalTzCtrl;

    final homeSystem = isLiving ? livingHomeSystem : visitingHomeSystem;
    final localSystem = isLiving ? livingLocalSystem : visitingLocalSystem;

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
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Place name',
              hintText: 'Living',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: homeTzCtrl,
            decoration: const InputDecoration(
              labelText: 'Home time zone (IANA)',
              hintText: 'America/Denver',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: localTzCtrl,
            decoration: const InputDecoration(
              labelText: 'Local time zone (IANA)',
              hintText: 'Europe/Lisbon',
            ),
          ),
          const SizedBox(height: 20),

          const Text('Home unit system'),
          const SizedBox(height: 8),
          _segmentedUnit(homeSystem, (v) {
            setState(() {
              if (isLiving) {
                livingHomeSystem = v;
                _syncVisitingFromLiving();
              } else {
                visitingHomeSystem = v;
              }
            });
          }),
          const SizedBox(height: 16),

          const Text('Local unit system'),
          const SizedBox(height: 8),
          _segmentedUnit(localSystem, (v) {
            setState(() {
              if (isLiving) {
                livingLocalSystem = v;
              } else {
                visitingLocalSystem = v;
              }
            });
          }),

          const SizedBox(height: 28),

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

