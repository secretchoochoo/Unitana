import 'package:flutter/material.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/data/cities.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/widgets/city_picker.dart';

class FirstRunScreen extends StatefulWidget {
  final UnitanaAppState state;

  const FirstRunScreen({super.key, required this.state});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  int _step = 0; // 0 welcome, 1 home, 2 destination, 3 review
  bool _saving = false;

  late final TextEditingController _profileCtrl;

  City? _homeCity;
  City? _destCity;

  // Place fields
  String _homeUnit = 'imperial';
  String _destUnit = 'metric';

  bool _homeUse24h = false;
  bool _destUse24h = true;

  // Track whether the user has manually changed a toggle (so city selection
  // does not override user intent).
  bool _homeUnitTouched = false;
  bool _destUnitTouched = false;
  bool _homeClockTouched = false;
  bool _destClockTouched = false;

  @override
  void initState() {
    super.initState();
    _profileCtrl = TextEditingController(text: widget.state.profileName);
    _seedFromState();
  }

  @override
  void dispose() {
    _profileCtrl.dispose();
    super.dispose();
  }

  void _seedFromState() {
    // Prefer existing places from app state if present.
    final living = _firstWhereOrNull(
      widget.state.places,
      (p) => p.type == PlaceType.living,
    );
    final visiting = _firstWhereOrNull(
      widget.state.places,
      (p) => p.type == PlaceType.visiting,
    );

    if (living != null) {
      _homeCity =
          _findCity(living.cityName, living.countryCode) ?? _defaultHomeCity();
      _homeUnit = living.unitSystem;
      _homeUse24h = living.use24h;
      _homeUnitTouched = true;
      _homeClockTouched = true;
    } else {
      _homeCity = _defaultHomeCity();
      _applyCityDefaults(home: true);
    }

    if (visiting != null) {
      _destCity =
          _findCity(visiting.cityName, visiting.countryCode) ??
          _defaultDestCity();
      _destUnit = visiting.unitSystem;
      _destUse24h = visiting.use24h;
      _destUnitTouched = true;
      _destClockTouched = true;
    } else {
      _destCity = _defaultDestCity();
      _applyCityDefaults(home: false);
    }

    // If destination has not been touched, keep it opposite by default.
    if (!_destUnitTouched) {
      _destUnit = (_homeUnit == 'metric') ? 'imperial' : 'metric';
    }
    if (!_destClockTouched) {
      _destUse24h = !_homeUse24h;
    }
  }

  City _defaultHomeCity() {
    return kCities.firstWhere(
      (c) => c.id == 'denver_us',
      orElse: () => kCities.first,
    );
  }

  City _defaultDestCity() {
    return kCities.firstWhere(
      (c) => c.id == 'lisbon_pt',
      orElse: () => kCities.first,
    );
  }

  City? _findCity(String cityName, String countryCode) {
    return _firstWhereOrNull(
      kCities,
      (c) => c.cityName == cityName && c.countryCode == countryCode,
    );
  }

  T? _firstWhereOrNull<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  void _applyCityDefaults({required bool home}) {
    final city = home ? _homeCity : _destCity;
    if (city == null) return;

    if (home) {
      if (!_homeUnitTouched) _homeUnit = city.defaultUnitSystem;
      if (!_homeClockTouched) _homeUse24h = city.defaultUse24h;
    } else {
      if (!_destUnitTouched) _destUnit = city.defaultUnitSystem;
      if (!_destClockTouched) _destUse24h = city.defaultUse24h;
    }
  }

  bool get _canContinue {
    if (_step == 0) return true; // profile optional
    if (_step == 1) return _homeCity != null;
    if (_step == 2) return _destCity != null;
    return true;
  }

  void _goTo(int step) => setState(() => _step = step);

  void _back() {
    if (_step <= 0) return;
    _goTo(_step - 1);
  }

  void _next() {
    if (_step >= 3) return;
    if (!_canContinue) return;
    _goTo(_step + 1);
  }

  String _unitLabel(String u) => u == 'metric' ? 'Metric' : 'Imperial';

  String _clockLabel(bool use24h) => use24h ? '24-hour' : '12-hour';

  String _timeSamplePrimary(bool use24h) => use24h ? '19:55' : '7:55 PM';

  String _timeSampleSecondary(bool use24h) => use24h ? '7:55 PM' : '19:55';

  String _tempPreview(String unitSystem) {
    const f = 68;
    const c = 20;
    return unitSystem == 'metric' ? '$c°C ($f°F)' : '$f°F ($c°C)';
  }

  String _windPreview(String unitSystem) {
    const mph = 12;
    const kmh = 19;
    return unitSystem == 'metric'
        ? '$kmh km/h ($mph mph)'
        : '$mph mph ($kmh km/h)';
  }

  Future<void> _pickCity({required bool home}) async {
    final selected = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          CityPicker(cities: kCities, selected: home ? _homeCity : _destCity),
    );

    if (selected == null) return;

    setState(() {
      if (home) {
        _homeCity = selected;
        _applyCityDefaults(home: true);

        // If destination has not been touched, keep it opposite by default.
        if (!_destUnitTouched) {
          _destUnit = (_homeUnit == 'metric') ? 'imperial' : 'metric';
        }
        if (!_destClockTouched) {
          _destUse24h = !_homeUse24h;
        }
      } else {
        _destCity = selected;
        _applyCityDefaults(home: false);
      }
    });
  }

  Future<void> _finish() async {
    final home = _homeCity;
    final dest = _destCity;
    if (home == null || dest == null) return;

    setState(() => _saving = true);
    try {
      await widget.state.setProfileName(_profileCtrl.text);

      final homePlace = Place(
        id: 'living',
        type: PlaceType.living,
        name: 'Home',
        cityName: home.cityName,
        countryCode: home.countryCode,
        timeZoneId: home.timeZoneId,
        unitSystem: _homeUnit,
        use24h: _homeUse24h,
      );

      final destPlace = Place(
        id: 'visiting',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: dest.cityName,
        countryCode: dest.countryCode,
        timeZoneId: dest.timeZoneId,
        unitSystem: _destUnit,
        use24h: _destUse24h,
      );

      await widget.state.overwritePlaces(
        newPlaces: [homePlace, destPlace],
        defaultId: homePlace.id,
      );

      // No navigation necessary. UnitanaApp listens to state changes and will
      // swap FirstRunScreen for DashboardScreen.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _placeCard({
    required String title,
    required City city,
    required String unitSystem,
    required bool use24h,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              _kvRow('City', city.display),
              _kvRow('Units', _unitLabel(unitSystem)),
              _kvRow('Clock', _clockLabel(use24h)),
              _kvRow(
                'Time',
                '${_timeSamplePrimary(use24h)} (${_timeSampleSecondary(use24h)})',
              ),
              _kvRow('Temp', _tempPreview(unitSystem)),
              _kvRow('Wind', _windPreview(unitSystem)),
              _kvRow('Currency', city.currencyCode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepWelcome() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Set up a Home and a Destination so Unitana can show your dual reality side by side.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _profileCtrl,
            decoration: const InputDecoration(
              labelText: 'Profile name (optional)',
              hintText: 'Ex: Portugal Move, Japan Trip',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          const Text(
            'You can change all of this later. This just gets you to a useful dashboard quickly.',
          ),
        ],
      ),
    );
  }

  Widget _stepHome() {
    final city = _homeCity;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Home', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Pick the place that feels like your baseline.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickCity(home: true),
            icon: const Icon(Icons.location_city),
            label: Text(city == null ? 'Choose a city' : city.display),
          ),
          const SizedBox(height: 16),
          Text('Units', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'imperial', label: Text('Imperial')),
              ButtonSegment(value: 'metric', label: Text('Metric')),
            ],
            selected: {_homeUnit},
            onSelectionChanged: (v) {
              setState(() {
                _homeUnit = v.first;
                _homeUnitTouched = true;
                if (!_destUnitTouched) {
                  _destUnit = (_homeUnit == 'metric') ? 'imperial' : 'metric';
                }
              });
            },
          ),
          const SizedBox(height: 18),
          Text('Clock', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('12-hour')),
              ButtonSegment(value: true, label: Text('24-hour')),
            ],
            selected: {_homeUse24h},
            onSelectionChanged: (v) {
              setState(() {
                _homeUse24h = v.first;
                _homeClockTouched = true;
                if (!_destClockTouched) {
                  _destUse24h = !_homeUse24h;
                }
              });
            },
          ),
          const SizedBox(height: 18),
          if (city != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _kvRow('Time', _timeSamplePrimary(_homeUse24h)),
                    _kvRow('Temp', _tempPreview(_homeUnit)),
                    _kvRow('Wind', _windPreview(_homeUnit)),
                    _kvRow('Currency', city.currencyCode),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepDestination() {
    final city = _destCity;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Destination', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Pick the place you are traveling to or learning next.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickCity(home: false),
            icon: const Icon(Icons.flight_takeoff),
            label: Text(city == null ? 'Choose a city' : city.display),
          ),
          const SizedBox(height: 16),
          Text('Units', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'imperial', label: Text('Imperial')),
              ButtonSegment(value: 'metric', label: Text('Metric')),
            ],
            selected: {_destUnit},
            onSelectionChanged: (v) {
              setState(() {
                _destUnit = v.first;
                _destUnitTouched = true;
              });
            },
          ),
          const SizedBox(height: 18),
          Text('Clock', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('12-hour')),
              ButtonSegment(value: true, label: Text('24-hour')),
            ],
            selected: {_destUse24h},
            onSelectionChanged: (v) {
              setState(() {
                _destUse24h = v.first;
                _destClockTouched = true;
              });
            },
          ),
          const SizedBox(height: 18),
          if (city != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _kvRow('Time', _timeSamplePrimary(_destUse24h)),
                    _kvRow('Temp', _tempPreview(_destUnit)),
                    _kvRow('Wind', _windPreview(_destUnit)),
                    _kvRow('Currency', city.currencyCode),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepReview() {
    final home = _homeCity;
    final dest = _destCity;
    final profile = _profileCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Tap any card to edit it.'),
          const SizedBox(height: 14),
          Card(
            child: InkWell(
              onTap: () => _goTo(0),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.badge),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        profile.isEmpty ? 'My Places' : profile,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          if (home != null)
            _placeCard(
              title: 'Home',
              city: home,
              unitSystem: _homeUnit,
              use24h: _homeUse24h,
              onTap: () => _goTo(1),
            ),
          if (dest != null)
            _placeCard(
              title: 'Destination',
              city: dest,
              unitSystem: _destUnit,
              use24h: _destUse24h,
              onTap: () => _goTo(2),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _stepWelcome(),
      _stepHome(),
      _stepDestination(),
      _stepReview(),
    ];

    final isLast = _step == 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        leading: _step == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / 4),
            Expanded(child: SingleChildScrollView(child: steps[_step])),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(onPressed: _back, child: const Text('Back')),
                  const Spacer(),
                  if (!isLast)
                    FilledButton(
                      onPressed: _canContinue ? _next : null,
                      child: const Text('Continue'),
                    )
                  else
                    FilledButton.icon(
                      onPressed:
                          (_homeCity != null && _destCity != null && !_saving)
                          ? _finish
                          : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Saving' : 'Finish'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
