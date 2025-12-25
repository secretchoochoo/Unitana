import 'package:flutter/material.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/data/cities.dart';
import 'package:unitana/data/city_repository.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/widgets/city_picker.dart';

class FirstRunScreen extends StatefulWidget {
  final UnitanaAppState state;

  const FirstRunScreen({super.key, required this.state});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  // 0: Splash
  // 1: Profile name
  // 2: Home
  // 3: Destination
  // 4: Review
  int _step = 0;

  final TextEditingController _profileCtrl = TextEditingController();

  List<City> _allCities = const <City>[];

  City? _homeCity;
  City? _destCity;

  String _homeUnit = 'imperial';
  String _destUnit = 'metric';

  bool _homeUse24h = false;
  bool _destUse24h = true;

  bool _homeUnitTouched = false;
  bool _destUnitTouched = false;
  bool _homeClockTouched = false;
  bool _destClockTouched = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrapFromState();
  }

  @override
  void dispose() {
    _profileCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapFromState() async {
    // Load cities first so all subsequent logic can search across the authoritative list.
    final cities = await CityRepository.loadCities();

    final places = widget.state.places;
    final profile = widget.state.profileName;

    if (!mounted) return;

    setState(() {
      _allCities = cities;

      _profileCtrl.text = (profile == 'My Places') ? '' : profile;

      if (places.isNotEmpty) {
        final home = places.firstWhere(
          (p) => p.type == PlaceType.living,
          orElse: () => places.first,
        );
        final dest = places.firstWhere(
          (p) => p.type == PlaceType.visiting,
          orElse: () => places.length > 1 ? places[1] : places.first,
        );

        _homeUnit = home.unitSystem;
        _homeUse24h = home.use24h;
        _homeUnitTouched = true;
        _homeClockTouched = true;
        _homeCity = _cityForPlace(home) ?? _fallbackHomeCity();

        _destUnit = dest.unitSystem;
        _destUse24h = dest.use24h;
        _destUnitTouched = true;
        _destClockTouched = true;
        _destCity = _cityForPlace(dest) ?? _fallbackDestCity();
      } else {
        _homeCity = _fallbackHomeCity();
        _destCity = _fallbackDestCity();
        _applyCityDefaults(home: true);
        _applyCityDefaults(home: false);
      }

      _loading = false;
    });
  }

  List<City> get _citiesOrFallback =>
      _allCities.isNotEmpty ? _allCities : kCities;

  City _fallbackHomeCity() {
    final list = _citiesOrFallback;
    return list.firstWhere(
      (c) => c.id == 'denver_us',
      orElse: () => list.first,
    );
  }

  City _fallbackDestCity() {
    final list = _citiesOrFallback;
    return list.firstWhere(
      (c) => c.id == 'lisbon_pt',
      orElse: () => list.first,
    );
  }

  City? _cityForPlace(Place place) {
    // Place stores cityName/countryCode/timeZoneId (no cityId).
    final list = _citiesOrFallback;

    // Try strict match first.
    for (final c in list) {
      if (c.cityName == place.cityName &&
          c.countryCode == place.countryCode &&
          c.timeZoneId == place.timeZoneId) {
        return c;
      }
    }

    // Fallback: city + country (timezone might differ in future).
    for (final c in list) {
      if (c.cityName == place.cityName && c.countryCode == place.countryCode) {
        return c;
      }
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

  String _appBarTitle() {
    switch (_step) {
      case 0:
        return 'Unitana';
      case 1:
        return 'What should we call it?';
      case 2:
        return 'Where are you from?';
      case 3:
        return 'Where are you going?';
      case 4:
        return 'Any changes?';
      default:
        return 'Unitana';
    }
  }

  double _progressValue() => (_step.clamp(0, 4)) / 4.0;

  bool get _canContinue {
    if (_step == 0) return true;
    if (_step == 1) return true;
    if (_step == 2) return _homeCity != null;
    if (_step == 3) return _destCity != null;
    return true;
  }

  void _next() {
    if (_step < 4 && _canContinue) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  String _unitLabel(String u) => u == 'metric' ? 'Metric' : 'Imperial';
  String _clockLabel(bool use24h) => use24h ? '24-hour' : '12-hour';
  String _timeSamplePrimary(bool use24h) => use24h ? '19:55' : '7:55 PM';
  String _timeSampleSecondary(bool use24h) => use24h ? '7:55 PM' : '19:55';

  String _tempPreview(String unitSystem) {
    const f = 68;
    const c = 20;
    if (unitSystem == 'metric') return '$c°C ($f°F)';
    return '$f°F ($c°C)';
  }

  String _windPreview(String unitSystem) {
    const mph = 12;
    const kmh = 19;
    if (unitSystem == 'metric') return '$kmh km/h ($mph mph)';
    return '$mph mph ($kmh km/h)';
  }

  String _tzDiffLabel({required String fromTz, required String toTz}) {
    // Lightweight approximate offsets for MVP preview only.
    const offsets = <String, int>{
      'Europe/Amsterdam': 1,
      'Europe/Madrid': 1,
      'Europe/Berlin': 1,
      'Europe/Copenhagen': 1,
      'Europe/Lisbon': 0,
      'Europe/London': 0,
      'America/Chicago': -6,
      'America/Denver': -7,
      'America/New_York': -5,
      'America/Los_Angeles': -8,
      'Europe/Paris': 1,
      'Europe/Rome': 1,
      'Europe/Stockholm': 1,
      'Europe/Oslo': 1,
    };

    final a = offsets[fromTz];
    final b = offsets[toTz];
    if (a == null || b == null) return '';

    final diff = b - a;
    if (diff == 0) return 'same time';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff}h';
  }

  String _currencyExample({required String fromCode, required String toCode}) {
    const rates = <String, double>{
      'EUR:USD': 1.10,
      'USD:EUR': 0.91,
      'GBP:USD': 1.28,
      'USD:GBP': 0.78,
      'EUR:GBP': 0.86,
      'GBP:EUR': 1.16,
      'CAD:USD': 0.74,
      'USD:CAD': 1.35,
    };

    const symbols = <String, String>{
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'DKK': 'kr',
      'CAD': r'$',
    };

    final rate = rates['$fromCode:$toCode'];
    if (rate == null) return fromCode;

    const fromAmount = 10.0;
    final toAmount = (fromAmount * rate).round();

    final fromSym = symbols[fromCode] ?? '';
    final toSym = symbols[toCode] ?? '';

    final fromText = fromSym.isEmpty
        ? '$fromCode ${fromAmount.toStringAsFixed(0)}'
        : '$fromSym${fromAmount.toStringAsFixed(0)}';

    final toText = toSym.isEmpty ? '$toCode $toAmount' : '$toSym$toAmount';

    return '$fromText ≈ $toText';
  }

  Future<void> _pickCity({required bool home}) async {
    final selected = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CityPicker(
        cities: _citiesOrFallback,
        selected: home ? _homeCity : _destCity,
      ),
    );

    if (selected == null) return;

    setState(() {
      if (home) {
        _homeCity = selected;
        _applyCityDefaults(home: true);

        // Nice onboarding nudge: if destination not touched yet, invert defaults.
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

  Future<void> _saveAndFinish() async {
    final home = _homeCity;
    final dest = _destCity;
    if (home == null || dest == null) return;

    await widget.state.setProfileName(_profileCtrl.text);

    final homePlace = Place(
      id: 'place_home',
      type: PlaceType.living,
      name: 'Home',
      cityName: home.cityName,
      countryCode: home.countryCode,
      timeZoneId: home.timeZoneId,
      unitSystem: _homeUnit,
      use24h: _homeUse24h,
    );

    final destPlace = Place(
      id: 'place_destination',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: dest.cityName,
      countryCode: dest.countryCode,
      timeZoneId: dest.timeZoneId,
      unitSystem: _destUnit,
      use24h: _destUse24h,
    );

    // Do NOT Navigator.pop() here; app.dart swaps home screen when state updates.
    await widget.state.overwritePlaces(
      newPlaces: [homePlace, destPlace],
      defaultId: homePlace.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showBack = _step >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        leading: showBack
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
        bottom: _step == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _progressValue()),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStepBody(context)),
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _splashStep(context);
      case 1:
        return _profileStep(context);
      case 2:
        return _placeStep(context, home: true);
      case 3:
        return _placeStep(context, home: false);
      case 4:
        return _reviewStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(BuildContext context) {
    if (_step == 0) {
      return Align(
        alignment: Alignment.bottomRight,
        child: FilledButton(onPressed: _next, child: const Text('Start')),
      );
    }

    if (_step == 4) {
      return Row(
        children: [
          OutlinedButton(onPressed: _back, child: const Text('Back')),
          const Spacer(),
          FilledButton.icon(
            onPressed: _saveAndFinish,
            icon: const Icon(Icons.check),
            label: const Text('Finish'),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (_step >= 2)
          OutlinedButton(onPressed: _back, child: const Text('Back')),
        const Spacer(),
        FilledButton(
          onPressed: _canContinue ? _next : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _splashStep(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.public, size: 44, color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Unitana',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'A decoder ring for real life.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'For wanderers who want temperature, distance, time, and money to feel effortless, wherever they land.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Next we’ll name this setup, then pick a Home and a Destination.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          'No pressure. Everything here can be edited later.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _profileStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give this setup a name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'This name makes it easy to recognize later, especially once you add more places.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _profileCtrl,
          decoration: const InputDecoration(
            labelText: 'Profile name (optional)',
            hintText: 'My Places',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'You can edit this later. Multiple profiles are planned for premium (details TBD).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _placeStep(BuildContext context, {required bool home}) {
    final city = home ? _homeCity : _destCity;
    final unit = home ? _homeUnit : _destUnit;
    final use24h = home ? _homeUse24h : _destUse24h;

    final title = home ? 'Home' : 'Destination';
    final subtitle = home
        ? 'Pick the place that feels like your baseline.'
        : 'Pick the place you’re traveling to (or moving to, and calling it a “trip” for now).';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _pickCity(home: home),
          icon: Icon(home ? Icons.location_city : Icons.flight_takeoff),
          label: Text(city?.display ?? 'Choose a city'),
        ),
        const SizedBox(height: 18),
        Text('Units', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(value: 'imperial', label: Text('Imperial')),
            ButtonSegment<String>(value: 'metric', label: Text('Metric')),
          ],
          selected: {unit},
          onSelectionChanged: (v) {
            final next = v.first;
            setState(() {
              if (home) {
                _homeUnitTouched = true;
                _homeUnit = next;
              } else {
                _destUnitTouched = true;
                _destUnit = next;
              }
            });
          },
        ),
        const SizedBox(height: 18),
        Text('Clock', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('12-hour')),
            ButtonSegment<bool>(value: true, label: Text('24-hour')),
          ],
          selected: {use24h},
          onSelectionChanged: (v) {
            final next = v.first;
            setState(() {
              if (home) {
                _homeClockTouched = true;
                _homeUse24h = next;
              } else {
                _destClockTouched = true;
                _destUse24h = next;
              }
            });
          },
        ),
        const SizedBox(height: 18),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _kvRow(
                  'Time',
                  '${_timeSamplePrimary(use24h)} (${_timeSampleSecondary(use24h)})',
                ),
                _kvRow('Temp', _tempPreview(unit)),
                _kvRow('Wind', _windPreview(unit)),
                _kvRow('Currency', city?.currencyCode ?? '—'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(BuildContext context) {
    final home = _homeCity;
    final dest = _destCity;

    final profile = _profileCtrl.text.trim().isEmpty
        ? 'My Places'
        : _profileCtrl.text.trim();

    final homeTz = home?.timeZoneId ?? '';
    final destTz = dest?.timeZoneId ?? '';
    final homeVsDest = (homeTz.isNotEmpty && destTz.isNotEmpty)
        ? _tzDiffLabel(fromTz: homeTz, toTz: destTz)
        : '';
    final destVsHome = (homeTz.isNotEmpty && destTz.isNotEmpty)
        ? _tzDiffLabel(fromTz: destTz, toTz: homeTz)
        : '';

    final homeCurrency = home?.currencyCode ?? '';
    final destCurrency = dest?.currencyCode ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Tap a card to edit it.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _step = 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      profile,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.edit_outlined),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _step = 2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Home', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(home?.display ?? '—'),
                  const SizedBox(height: 6),
                  Text(
                    '${_unitLabel(_homeUnit)} · ${_clockLabel(_homeUse24h)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (homeVsDest.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'To Destination: $homeVsDest',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    homeCurrency.isEmpty ? '' : 'Currency: $homeCurrency',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _step = 3),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(dest?.display ?? '—'),
                  const SizedBox(height: 6),
                  Text(
                    '${_unitLabel(_destUnit)} · ${_clockLabel(_destUse24h)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (destVsHome.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'To Home: $destVsHome',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    destCurrency.isEmpty ? '' : 'Currency: $destCurrency',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (homeCurrency.isNotEmpty && destCurrency.isNotEmpty)
          Text(
            'Example: ${_currencyExample(fromCode: homeCurrency, toCode: destCurrency)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(k)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
