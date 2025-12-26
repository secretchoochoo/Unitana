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
  final CityRepository _cityRepo = CityRepository.instance;

  /// We start with a curated list so onboarding never blocks on asset IO.
  /// If the full dataset loads successfully, we swap it in.
  List<City> _cities = List<City>.from(kCuratedCities);

  // 0: Welcome
  // 1: Profile name
  // 2: Home
  // 3: Destination
  // 4: Review
  static const int _pageCount = 5;

  // Shared animation duration for subtle UI transitions in the wizard.
  static const Duration _kAnim = Duration(milliseconds: 220);

  final PageController _pageCtrl = PageController();
  int _page = 0;
  int _maxVisited = 0;
  bool _isRevertingSwipe = false;

  final TextEditingController _profileCtrl = TextEditingController();

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

  @override
  void initState() {
    super.initState();

    // Bootstrap immediately (no spinner), then try to load the full dataset.
    _bootstrapFromState();
    _loadCitiesBestEffort();
  }

  @override
  void dispose() {
    _profileCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCitiesBestEffort() async {
    try {
      final loaded = await _cityRepo.load();
      if (!mounted) return;

      setState(() {
        _cities = loaded;
        _refreshSelectedCitiesFromNewList();
      });
    } catch (_) {
      // CityRepository already falls back to curated cities on failure.
      // This is an extra safety net.
    }
  }

  void _refreshSelectedCitiesFromNewList() {
    // If we already picked a city from the curated list, keep the selection but
    // try to swap it to the equivalent object in the new list (for metadata).
    if (_homeCity != null) {
      final match = _cities.firstWhere(
        (c) => c.id == _homeCity!.id,
        orElse: () => _homeCity!,
      );
      _homeCity = match;
    }
    if (_destCity != null) {
      final match = _cities.firstWhere(
        (c) => c.id == _destCity!.id,
        orElse: () => _destCity!,
      );
      _destCity = match;
    }
  }

  void _bootstrapFromState() {
    // AppState is already loaded in app.dart before showing FirstRunScreen.
    final places = widget.state.places;
    final profile = widget.state.profileName;

    setState(() {
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
    });
  }

  City _fallbackHomeCity() {
    return _cities.firstWhere(
      (c) => c.id == 'denver_us',
      orElse: () => _cities.first,
    );
  }

  City _fallbackDestCity() {
    return _cities.firstWhere(
      (c) => c.id == 'lisbon_pt',
      orElse: () => _cities.first,
    );
  }

  City? _cityForPlace(Place place) {
    // Place stores cityName/countryCode/timeZoneId (no cityId).
    // Try strict match first.
    for (final c in _cities) {
      if (c.cityName == place.cityName &&
          c.countryCode == place.countryCode &&
          c.timeZoneId == place.timeZoneId) {
        return c;
      }
    }

    // Fallback: city + country (timezone might differ in future).
    for (final c in _cities) {
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

  bool get _canContinue {
    if (_page == 0) return true;
    if (_page == 1) return true;
    if (_page == 2) return _homeCity != null;
    if (_page == 3) return _destCity != null;
    return true;
  }

  bool _canGoToStep(int target) {
    if (target < 0 || target >= _pageCount) return false;
    if (target == _page) return true;

    // Allow going backward and revisiting any already-visited step.
    if (target <= _maxVisited) return true;

    // Allow moving forward one step at a time only when the current step is valid.
    if (target == _page + 1 && _canContinue) return true;

    return false;
  }

  void _goToStep(int target) {
    if (!_canGoToStep(target)) return;
    _goTo(target);
  }

  Future<void> _goTo(int index) async {
    final next = index.clamp(0, _pageCount - 1);
    if (!_canGoToStep(next)) return;

    setState(() {
      _page = next;
      if (next > _maxVisited) _maxVisited = next;
    });

    await _pageCtrl.animateToPage(
      next,
      duration: _kAnim,
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (!_canContinue) return;
    if (_page < _pageCount - 1) {
      _goTo(_page + 1);
    }
  }

  void _back() {
    if (_page > 0) {
      _goTo(_page - 1);
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

    // Show symbol + ISO to avoid ambiguity ($ USD vs $ CAD).
    final fromText = fromSym.isEmpty
        ? '$fromCode ${fromAmount.toStringAsFixed(0)}'
        : '$fromSym $fromCode ${fromAmount.toStringAsFixed(0)}';

    final toText = toSym.isEmpty
        ? '$toCode $toAmount'
        : '$toSym $toCode $toAmount';

    return '$fromText ≈ $toText';
  }

  Future<void> _pickCity({required bool home}) async {
    final selected = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          CityPicker(cities: _cities, selected: home ? _homeCity : _destCity),
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
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (idx) {
                    if (_isRevertingSwipe) {
                      _isRevertingSwipe = false;
                      return;
                    }

                    if (!_canGoToStep(idx)) {
                      _isRevertingSwipe = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _pageCtrl.animateToPage(
                          _page,
                          duration: _kAnim,
                          curve: Curves.easeOutCubic,
                        );
                      });
                      return;
                    }

                    setState(() {
                      _page = idx;
                      if (idx > _maxVisited) _maxVisited = idx;
                    });
                  },
                  children: [
                    KeyedSubtree(
                      key: const Key('first_run_step_welcome'),
                      child: _welcomeStep(context),
                    ),
                    KeyedSubtree(
                      key: const Key('first_run_step_profile'),
                      child: _profileStep(context),
                    ),
                    KeyedSubtree(
                      key: const Key('first_run_step_home'),
                      child: _placeStep(context, home: true),
                    ),
                    KeyedSubtree(
                      key: const Key('first_run_step_destination'),
                      child: _placeStep(context, home: false),
                    ),
                    KeyedSubtree(
                      key: const Key('first_run_step_review'),
                      child: _reviewStep(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildPagerControls(context),
              if (_page == 4) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('first_run_finish_button'),
                    onPressed: _saveAndFinish,
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagerControls(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final canPrev = _canGoToStep(_page - 1);
    final canNext = _canGoToStep(_page + 1);

    return SafeArea(
      top: false,
      child: Row(
        children: [
          _navIconButton(
            key: const Key('first_run_nav_prev'),
            icon: Icons.chevron_left,
            enabled: canPrev,
            onPressed: _back,
            cs: cs,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildDots(context),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _navIconButton(
            key: const Key('first_run_nav_next'),
            icon: Icons.chevron_right,
            enabled: canNext,
            onPressed: _next,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _navIconButton({
    required Key key,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
    required ColorScheme cs,
  }) {
    return IconButton(
      key: key,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      iconSize: 34,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints.tightFor(width: 56, height: 56),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? cs.primaryContainer
            : cs.surfaceContainerHighest,
        foregroundColor: enabled ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        shape: const StadiumBorder(),
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i == _page;
        final visited = i <= _maxVisited;
        final canTap = visited || (i == _page + 1 && _canContinue);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: InkWell(
            onTap: canTap ? () => _goToStep(i) : null,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: active ? 30 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: active
                      ? cs.primary
                      : (canTap
                            ? cs.onSurfaceVariant.withAlpha(120)
                            : cs.onSurfaceVariant.withAlpha(60)),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _welcomeStep(BuildContext context) {
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _profileStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        TextField(
          key: const Key('first_run_profile_name_field'),
          controller: _profileCtrl,
          decoration: const InputDecoration(
            labelText: 'Profile name (optional)',
            hintText: 'My Places',
            helperText: 'You can change this later.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _placeStep(BuildContext context, {required bool home}) {
    final city = home ? _homeCity : _destCity;
    final unit = home ? _homeUnit : _destUnit;
    final use24h = home ? _homeUse24h : _destUse24h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: home
              ? const Key('first_run_home_city_button')
              : const Key('first_run_dest_city_button'),
          onPressed: () => _pickCity(home: home),
          icon: Icon(home ? Icons.location_city : Icons.flight_takeoff),
          label: Text(
            city?.display ??
                (home ? 'Choose Home city' : 'Choose Destination city'),
          ),
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
                // Show symbol + ISO if available.
                _kvRow('Currency', city?.currencyLabel ?? 'N/A'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _goTo(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
          const SizedBox(height: 12),
          _placeReviewCard(
            context,
            title: 'Home',
            city: home,
            unitSystem: _homeUnit,
            use24h: _homeUse24h,
            tzExtra: homeVsDest,
            otherCurrency: dest?.currencyCode,
            onTap: () => _goTo(2),
          ),
          const SizedBox(height: 12),
          _placeReviewCard(
            context,
            title: 'Destination',
            city: dest,
            unitSystem: _destUnit,
            use24h: _destUse24h,
            tzExtra: destVsHome,
            otherCurrency: home?.currencyCode,
            onTap: () => _goTo(3),
          ),
        ],
      ),
    );
  }

  Widget _placeReviewCard(
    BuildContext context, {
    required String title,
    required City? city,
    required String unitSystem,
    required bool use24h,
    required String tzExtra,
    required String? otherCurrency,
    required VoidCallback onTap,
  }) {
    final tz = city?.timeZoneId ?? 'N/A';
    final tzLine = tzExtra.isEmpty ? tz : '$tz ($tzExtra)';

    final currencyCode = city?.currencyCode;
    String currencyLine = city?.currencyLabel ?? 'N/A';
    if (currencyCode != null &&
        otherCurrency != null &&
        otherCurrency.isNotEmpty) {
      currencyLine = _currencyExample(
        fromCode: currencyCode,
        toCode: otherCurrency,
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.edit_outlined),
                ],
              ),
              const SizedBox(height: 10),
              _kvRow('City', city?.display ?? 'N/A', boldKey: true),
              _kvRow('Time zone', tzLine, boldKey: true),
              _kvRow('Units', _unitLabel(unitSystem), boldKey: true),
              _kvRow('Clock', _clockLabel(use24h), boldKey: true),
              const SizedBox(height: 8),
              _kvRow(
                'Time',
                '${_timeSamplePrimary(use24h)} (${_timeSampleSecondary(use24h)})',
                boldKey: true,
              ),
              _kvRow('Temp', _tempPreview(unitSystem), boldKey: true),
              _kvRow('Wind', _windPreview(unitSystem), boldKey: true),
              _kvRow('Currency', currencyLine, boldKey: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kvRow(String key, String value, {bool boldKey = false}) {
    final keyStyle = boldKey
        ? const TextStyle(fontWeight: FontWeight.w600)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text('$key:', style: keyStyle)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
