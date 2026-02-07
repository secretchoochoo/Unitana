import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/data/cities.dart';
import 'package:unitana/data/city_repository.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/widgets/compact_reality_toggle.dart';
import 'package:unitana/features/dashboard/widgets/pinned_mini_hero_readout.dart';
import 'package:unitana/features/dashboard/widgets/places_hero_v2.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/dracula_palette.dart';
import 'package:unitana/widgets/city_picker.dart';

enum FirstRunExitAction { saved, cancelled }

class FirstRunScreen extends StatefulWidget {
  final UnitanaAppState state;
  final bool editMode;
  final bool allowCancel;

  const FirstRunScreen({
    super.key,
    required this.state,
    this.editMode = false,
    this.allowCancel = false,
  });

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  final CityRepository _cityRepo = CityRepository.instance;

  /// Shorthand for the active theme's ColorScheme.
  ///
  /// This screen uses a lot of colorScheme values to keep the onboarding
  /// visuals aligned with the dashboard.
  ColorScheme get cs => Theme.of(context).colorScheme;

  /// We start with a curated list so onboarding never blocks on asset IO.
  /// If the full dataset loads successfully, we swap it in.
  List<City> _cities = List<City>.from(kCuratedCities);

  // 0: Welcome
  // 1: Places (Home + Destination + mini hero preview)
  // 2: Confirm (Name + main hero preview)
  static const int _pageCount = 3;

  static const Duration _kAnim = Duration(milliseconds: 220);
  static const double _kWizardTitleFontSize = 40.0;
  static const double _kFooterCtaHeight = 56.0;
  static const double _kFooterCtaWidth = 240.0;

  final PageController _pageCtrl = PageController();
  int _page = 0;
  int _maxVisited = 0;
  bool _isRevertingSwipe = false;

  City? _homeCity;
  City? _destCity;

  // Wizard-specific preferences. These are persisted into the created profile
  // and used for preview rendering so the onboarding reflects the real dashboard.
  String _homeUnitSystem = 'metric';
  bool _homeUse24h = false;
  String _destUnitSystem = 'metric';
  bool _destUse24h = false;

  String _profileName = '';
  late final TextEditingController _nameCtrl;

  // Preview-only controllers. These mirror dashboard wiring so the wizard can
  // show the real visual system without duplicating widget trees.
  late final DashboardSessionController _previewSession;
  late final DashboardLiveDataController _previewLiveData;

  bool _previewRefreshPending = false;

  bool get _hasBothCities => _homeCity != null && _destCity != null;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return true;
      case 1:
        return _hasBothCities;
      case 2:
        return _hasBothCities;
      default:
        return false;
    }
  }

  bool _canGoToStep(int idx) {
    if (idx < 0 || idx >= _pageCount) return false;

    // Always allow moving backwards.
    if (idx <= _page) return true;

    // Forward navigation is gated by completion.
    if (_page == 0) return true;
    if (_page == 1) return _hasBothCities;
    return false;
  }

  @override
  void initState() {
    super.initState();

    _previewSession = DashboardSessionController();
    _previewLiveData = DashboardLiveDataController();
    _nameCtrl = TextEditingController();

    if (widget.editMode) {
      _profileName = widget.state.profileName;
      _nameCtrl.text = _profileName;

      // Best-effort: seed home/destination from the persisted Places.
      // We resolve Cities from the curated list first, then refine after the
      // full dataset loads.
      final living = widget.state.places
          .where((p) => p.type == PlaceType.living)
          .cast<Place?>()
          .firstWhere((p) => p != null, orElse: () => null);
      final visiting = widget.state.places
          .where((p) => p.type == PlaceType.visiting)
          .cast<Place?>()
          .firstWhere((p) => p != null, orElse: () => null);

      if (living != null) {
        _homeUnitSystem = living.unitSystem;
        _homeUse24h = living.use24h;
        _homeCity = _findCity(living.cityName, living.countryCode);
      }
      if (visiting != null) {
        _destUnitSystem = visiting.unitSystem;
        _destUse24h = visiting.use24h;
        _destCity = _findCity(visiting.cityName, visiting.countryCode);
      }
    }

    // Best-effort load of the full city dataset in the background.
    _cityRepo.load().then((_) {
      if (!mounted) return;
      setState(() {
        _cities = _cityRepo.cities;

        // If we're editing, refine city resolution against the full dataset.
        if (widget.editMode) {
          final living = widget.state.places
              .where((p) => p.type == PlaceType.living)
              .cast<Place?>()
              .firstWhere((p) => p != null, orElse: () => null);
          final visiting = widget.state.places
              .where((p) => p.type == PlaceType.visiting)
              .cast<Place?>()
              .firstWhere((p) => p != null, orElse: () => null);

          if (living != null) {
            _homeCity = _findCity(living.cityName, living.countryCode);
          }
          if (visiting != null) {
            _destCity = _findCity(visiting.cityName, visiting.countryCode);
          }
        }
      });
    });
  }

  City? _findCity(String cityName, String countryCode) {
    final name = cityName.trim().toLowerCase();
    final cc = countryCode.trim().toUpperCase();

    // Prefer exact city+country match.
    final exact = _cities.where((c) {
      return c.cityName.trim().toLowerCase() == name &&
          c.countryCode.trim().toUpperCase() == cc;
    });
    if (exact.isNotEmpty) return exact.first;

    // Fallback: match by name.
    final byName = _cities.where(
      (c) => c.cityName.trim().toLowerCase() == name,
    );
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _previewSession.dispose();
    _previewLiveData.dispose();
    super.dispose();
  }

  void _goToStep(int idx) {
    if (!_canGoToStep(idx)) return;
    _pageCtrl.animateToPage(idx, duration: _kAnim, curve: Curves.easeOutCubic);
  }

  void _next() {
    if (!_canContinue) return;
    final next = _page + 1;
    if (next >= _pageCount) return;
    _goToStep(next);
  }

  void _back() {
    final prev = _page - 1;
    if (prev < 0) return;
    _goToStep(prev);
  }

  Place? _previewHome() {
    final c = _homeCity;
    if (c == null) return null;
    return Place(
      id: 'preview_home',
      type: PlaceType.living,
      name: 'Home',
      cityName: c.cityName,
      countryCode: c.countryCode,
      timeZoneId: c.timeZoneId,
      unitSystem: _homeUnitSystem,
      use24h: _homeUse24h,
    );
  }

  Place? _previewDest() {
    final c = _destCity;
    if (c == null) return null;
    return Place(
      id: 'preview_destination',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: c.cityName,
      countryCode: c.countryCode,
      timeZoneId: c.timeZoneId,
      unitSystem: _destUnitSystem,
      use24h: _destUse24h,
    );
  }

  Future<void> _refreshPreview() async {
    final home = _previewHome();
    final dest = _previewDest();
    if (home == null || dest == null) return;
    await _previewLiveData.refreshAll(places: [home, dest]);
  }

  void _schedulePreviewRefresh() {
    if (_previewRefreshPending) return;
    _previewRefreshPending = true;
    Future.delayed(const Duration(milliseconds: 120), () async {
      if (!mounted) return;
      _previewRefreshPending = false;
      if (!_hasBothCities) return;
      await _refreshPreview();
    });
  }

  Future<City?> showCityPicker({
    required BuildContext context,
    required List<City> cities,
    City? initial,
  }) async {
    return showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DraculaPalette.background,
      builder: (ctx) => CityPicker(cities: cities, selected: initial),
    );
  }

  Future<void> _pickCity({required bool home}) async {
    final selected = await showCityPicker(
      context: context,
      cities: _cities,
      initial: home ? _homeCity : _destCity,
    );
    if (selected == null) return;
    setState(() {
      if (home) {
        _homeCity = selected;
        _homeUnitSystem = selected.defaultUnitSystem;
        _homeUse24h = selected.defaultUse24h;
      } else {
        _destCity = selected;
        _destUnitSystem = selected.defaultUnitSystem;
        _destUse24h = selected.defaultUse24h;
      }
      // Keep the default name aligned to Destination unless the user typed.
      if (_profileName.trim().isEmpty && _destCity != null) {
        _profileName = _destCity!.cityName;
        _nameCtrl.text = _profileName;
      }
    });

    _schedulePreviewRefresh();
  }

  Future<void> _saveAndFinish() async {
    final home = _homeCity;
    final dest = _destCity;
    if (home == null || dest == null) return;

    final name = _effectiveProfileName();

    final living = Place(
      id: 'living-1',
      type: PlaceType.living,
      name: 'Home',
      cityName: home.cityName,
      countryCode: home.countryCode,
      timeZoneId: home.timeZoneId,
      unitSystem: _homeUnitSystem,
      use24h: _homeUse24h,
    );

    final visiting = Place(
      id: 'visit-1',
      type: PlaceType.visiting,
      name: 'Destination',
      cityName: dest.cityName,
      countryCode: dest.countryCode,
      timeZoneId: dest.timeZoneId,
      unitSystem: _destUnitSystem,
      use24h: _destUse24h,
    );
    await widget.state.overwritePlaces(
      newPlaces: [living, visiting],
      defaultId: visiting.id,
    );
    await widget.state.setProfileName(name);

    if (!mounted) return;

    if (widget.editMode) {
      Navigator.of(context).pop(FirstRunExitAction.saved);
      return;
    }

    widget.state.setPendingSuccessToast('Profile created');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardScreen(state: widget.state)),
      (route) => false,
    );
  }

  String _effectiveProfileName() {
    final trimmed = _profileName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final dest = _destCity;
    if (dest != null && dest.cityName.trim().isNotEmpty) {
      return dest.cityName.trim();
    }
    return 'Unitana';
  }

  void _cancelAndClose() {
    if (!widget.allowCancel) return;
    Navigator.of(context).pop(FirstRunExitAction.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!widget.allowCancel) return;
        _cancelAndClose();
      },
      child: Scaffold(
        appBar: null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.allowCancel)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key('first_run_cancel_button'),
                      tooltip: 'Cancel setup',
                      onPressed: _cancelAndClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
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

                      if (idx >= 1 && _hasBothCities) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _refreshPreview();
                        });
                      }
                    },
                    children: [
                      KeyedSubtree(
                        key: const Key('first_run_step_welcome'),
                        child: _welcomeStep(context),
                      ),
                      KeyedSubtree(
                        key: const Key('first_run_step_places'),
                        child: _placesStep(context),
                      ),
                      KeyedSubtree(
                        key: const Key('first_run_step_confirm'),
                        child: _confirmStep(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildPagerControls(context),
                const SizedBox(height: 10),
                SizedBox(
                  height: _kFooterCtaHeight,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _page == _pageCount - 1
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _kFooterCtaWidth,
                                minHeight: _kFooterCtaHeight,
                              ),
                              child: FilledButton.icon(
                                key: const Key('first_run_finish_button'),
                                onPressed: _saveAndFinish,
                                icon: const Icon(Icons.check),
                                label: Text(
                                  widget.editMode
                                      ? 'Save Changes'
                                      : 'Create Profile',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagerControls(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final canPrev = _canGoToStep(_page - 1);
    final canNext = _canGoToStep(_page + 1) && _canContinue;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pageCount, (i) {
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
    final tt = Theme.of(context).textTheme;

    final headlineStyle = GoogleFonts.robotoSlab(
      fontSize: _kWizardTitleFontSize,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
      height: 1.05,
    );
    final taglineStyle = (tt.bodyLarge ?? const TextStyle(fontSize: 16))
        .copyWith(color: cs.onSurfaceVariant.withAlpha(220), height: 1.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(60),
                          border: Border.all(
                            color: cs.outlineVariant.withAlpha(160),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(
                            'assets/brand/unitana_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome to Unitana',
                        style: headlineStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant.withAlpha(160),
                          ),
                        ),
                        child: Text(
                          'A dual-reality dashboard for the stuff\n'
                          'your brain keeps converting anyway.',
                          style: taglineStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placesStep(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final titleStyle = GoogleFonts.robotoSlab(
      fontSize: _kWizardTitleFontSize,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
      height: 1.05,
    );
    final subStyle = (tt.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: cs.onSurface.withAlpha(200),
      height: 1.35,
    );

    final home = _previewHome();
    final dest = _previewDest();

    Widget preview() {
      if (home == null || dest == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withAlpha(160)),
          ),
          child: Text(
            'Pick both places to preview the mini hero.',
            style: subStyle,
            textAlign: TextAlign.center,
          ),
        );
      }

      return AnimatedBuilder(
        animation: Listenable.merge([_previewSession, _previewLiveData]),
        builder: (context, _) {
          final isHome = _previewSession.reality == DashboardReality.home;
          final primary = isHome ? home : dest;
          final secondary = isHome ? dest : home;

          final homeLabel = '${_flagEmoji(home.countryCode)} ${home.cityName}'
              .trim();
          final destLabel = '${_flagEmoji(dest.countryCode)} ${dest.cityName}'
              .trim();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CompactRealityToggle(
                key: const ValueKey('first_run_preview_reality_toggle'),
                isHome: isHome,
                homeLabel: homeLabel,
                destLabel: destLabel,
                onPickHome: () =>
                    _previewSession.setReality(DashboardReality.home),
                onPickDestination: () =>
                    _previewSession.setReality(DashboardReality.destination),
              ),
              const SizedBox(height: 10),
              PinnedMiniHeroReadout(
                key: const ValueKey('first_run_preview_mini_hero_readout'),
                primary: primary,
                secondary: secondary,
                liveData: _previewLiveData,
              ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Pick Your Places',
                      style: titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your here and your there, side by side.',
                      style: subStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    _cityPickButton(
                      context,
                      key: const Key('first_run_home_city_button'),
                      onPressed: () => _pickCity(home: true),
                      icon: Icons.home,
                      label: _homeCity?.display ?? 'Choose Home city',
                    ),
                    if (_homeCity != null) ...[
                      const SizedBox(height: 10),
                      _unitClockControls(
                        unitSystem: _homeUnitSystem,
                        use24h: _homeUse24h,
                        onPickUnit: (v) {
                          setState(() => _homeUnitSystem = v);
                          _schedulePreviewRefresh();
                        },
                        onPickClock: (v) {
                          setState(() => _homeUse24h = v);
                          _schedulePreviewRefresh();
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    _cityPickButton(
                      context,
                      key: const Key('first_run_dest_city_button'),
                      onPressed: () => _pickCity(home: false),
                      icon: Icons.flight_takeoff,
                      label: _destCity?.display ?? 'Choose Destination city',
                    ),
                    if (_destCity != null) ...[
                      const SizedBox(height: 10),
                      _unitClockControls(
                        unitSystem: _destUnitSystem,
                        use24h: _destUse24h,
                        onPickUnit: (v) {
                          setState(() => _destUnitSystem = v);
                          _schedulePreviewRefresh();
                        },
                        onPickClock: (v) {
                          setState(() => _destUse24h = v);
                          _schedulePreviewRefresh();
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    preview(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _confirmStep(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final titleStyle = GoogleFonts.robotoSlab(
      fontSize: _kWizardTitleFontSize,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
      height: 1.05,
    );
    final subStyle = (tt.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: cs.onSurface.withAlpha(200),
      height: 1.35,
    );

    final home = _previewHome();
    final dest = _previewDest();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Name and Confirm',
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'This name shows in the header and in your profile list. Keep it short.',
                  style: subStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('first_run_profile_name_field'),
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  labelStyle: (tt.bodySmall ?? const TextStyle(fontSize: 12))
                      .copyWith(
                        color: cs.primary.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                  hintText: _destCity?.cityName ?? 'Lisbon',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (v) => setState(() => _profileName = v),
                controller: _nameCtrl,
              ),
              const SizedBox(height: 18),
              if (home == null || dest == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withAlpha(160)),
                  ),
                  child: Text(
                    'Go back and pick Home + Destination to preview the hero.',
                    style: subStyle,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _previewSession,
                    _previewLiveData,
                  ]),
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: cs.outlineVariant.withAlpha(160),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: PlacesHeroV2(
                                includeTestKeys: false,
                                home: home,
                                destination: dest,
                                session: _previewSession,
                                liveData: _previewLiveData,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitClockControls({
    required String unitSystem,
    required bool use24h,
    required ValueChanged<String> onPickUnit,
    required ValueChanged<bool> onPickClock,
  }) {
    Widget pill({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: _kAnim,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withAlpha(170)
                : cs.surfaceContainerHighest.withAlpha(55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withAlpha(200)
                  : cs.outlineVariant.withAlpha(160),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: cs.onPrimaryContainer),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: selected
                      ? cs.onPrimaryContainer
                      : cs.onSurface.withAlpha(230),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            pill(
              label: 'Metric',
              selected: unitSystem == 'metric',
              onTap: () => onPickUnit('metric'),
            ),
            pill(
              label: 'Imperial',
              selected: unitSystem == 'imperial',
              onTap: () => onPickUnit('imperial'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            pill(
              label: '12-Hour',
              selected: !use24h,
              onTap: () => onPickClock(false),
            ),
            pill(
              label: '24-Hour',
              selected: use24h,
              onTap: () => onPickClock(true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cityPickButton(
    BuildContext context, {
    required Key key,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withAlpha(230),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          backgroundColor: cs.surfaceContainerHighest.withAlpha(55),
          side: BorderSide(color: cs.outlineVariant.withAlpha(160)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  String _flagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
