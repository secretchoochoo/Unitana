import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app_state.dart';
import '../../data/city_repository.dart';
import '../../models/place.dart';
import '../../common/feedback/unitana_toast.dart';
import '../../utils/timezone_utils.dart';
import '../first_run/first_run_screen.dart';
import 'models/dashboard_live_data.dart';
import 'models/dashboard_layout_controller.dart';
import 'models/dashboard_session_controller.dart';
import 'models/dashboard_exceptions.dart';
import 'models/tool_definitions.dart';
import 'widgets/dashboard_board.dart';
import 'widgets/data_refresh_status_label.dart';
import 'widgets/tool_modal_bottom_sheet.dart';

/// Developer-only time-of-day override for weather scene previews.
///
/// Kept file-private because this is not part of the public widget API.
enum _DevWeatherTimeOfDay { auto, sun, night }

class DashboardScreen extends StatefulWidget {
  final UnitanaAppState state;

  @visibleForTesting
  static bool debugForcePinnedHeroVisible = false;

  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardSessionController _session;
  late final DashboardLiveDataController _liveData;
  late final DashboardLayoutController _layout;

  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  DateTime? _lastAutoWeatherRefreshAttemptAt;

  bool _isEditingWidgets = false;
  String? _focusTileId;

  UnitanaAppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _session = DashboardSessionController();
    _liveData = DashboardLiveDataController();
    _liveData.loadDevSettings();
    _layout = DashboardLayoutController();
    _layout.load();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final next = _scrollController.offset;
      if (next == _scrollOffset) return;
      setState(() {
        _scrollOffset = next;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _session.dispose();
    _liveData.dispose();
    _layout.dispose();
    super.dispose();
  }

  Future<void> _resetAndRestart() async {
    await state.resetAll();
    CityRepository.instance.resetCache();
    await _layout.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => FirstRunScreen(state: state)),
      (route) => false,
    );
  }

  String _weatherLabel(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.overcast:
        return 'Overcast';
      case WeatherCondition.drizzle:
        return 'Drizzle';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorm';
      case WeatherCondition.snow:
        return 'Snow';
      case WeatherCondition.sleet:
        return 'Sleet';
      case WeatherCondition.hail:
        return 'Hail';
      case WeatherCondition.fog:
        return 'Fog';
      case WeatherCondition.mist:
        return 'Mist';
      case WeatherCondition.haze:
        return 'Haze';
      case WeatherCondition.smoke:
        return 'Smoke';
      case WeatherCondition.dust:
        return 'Dust';
      case WeatherCondition.sand:
        return 'Sand';
      case WeatherCondition.ash:
        return 'Ash';
      case WeatherCondition.squall:
        return 'Squall';
      case WeatherCondition.tornado:
        return 'Tornado';
      case WeatherCondition.windy:
        return 'Windy';
    }
  }

  void _openWeatherOverrideSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final currentOverride = _liveData.debugWeatherOverride;
        final WeatherCondition? initialCondition =
            currentOverride is WeatherDebugOverrideCoarse
            ? currentOverride.condition
            : null;
        final bool? initialIsNightOverride =
            currentOverride is WeatherDebugOverrideCoarse
            ? currentOverride.isNightOverride
            : null;

        _DevWeatherTimeOfDay initialTimeOfDay() {
          if (initialIsNightOverride == true) return _DevWeatherTimeOfDay.night;
          if (initialIsNightOverride == false) return _DevWeatherTimeOfDay.sun;
          return _DevWeatherTimeOfDay.auto;
        }

        final options = WeatherCondition.values.toList()
          ..sort((a, b) => _weatherLabel(a).compareTo(_weatherLabel(b)));

        WeatherCondition? selectedCondition = initialCondition;
        _DevWeatherTimeOfDay selectedTimeOfDay = initialTimeOfDay();
        WeatherBackend selectedBackend = _liveData.weatherBackend;

        return StatefulBuilder(
          builder: (context, setState) {
            bool? toNightOverride(_DevWeatherTimeOfDay v) {
              switch (v) {
                case _DevWeatherTimeOfDay.auto:
                  return null;
                case _DevWeatherTimeOfDay.sun:
                  return false;
                case _DevWeatherTimeOfDay.night:
                  return true;
              }
            }

            void applyOverride() {
              final c = selectedCondition;
              if (c == null) {
                _liveData.setDebugWeatherOverride(null);
                return;
              }
              _liveData.setDebugWeatherOverride(
                WeatherDebugOverrideCoarse(
                  c,
                  isNightOverride: toNightOverride(selectedTimeOfDay),
                ),
              );
            }

            String backendLabel(WeatherBackend b) {
              switch (b) {
                case WeatherBackend.mock:
                  return 'Demo (no network)';
                case WeatherBackend.openMeteo:
                  return 'Live: Open-Meteo';
                case WeatherBackend.weatherApi:
                  return 'Live: WeatherAPI';
              }
            }

            Future<void> applyBackend(WeatherBackend b) async {
              await _liveData.setWeatherBackend(b);
              if (!mounted) return;
              await _liveData.refreshAll(places: state.places);
            }

            Widget choiceTile({
              required Key key,
              required String title,
              required WeatherCondition? value,
            }) {
              final selected = value == selectedCondition;
              return ListTile(
                key: key,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_outlined
                      : Icons.radio_button_unchecked_outlined,
                ),
                title: Text(title),
                onTap: () {
                  if (value == null) {
                    setState(() {
                      selectedCondition = null;
                      selectedTimeOfDay = _DevWeatherTimeOfDay.auto;
                    });
                    _liveData.setDebugWeatherOverride(null);
                    Navigator.of(sheetContext).pop();
                    return;
                  }

                  setState(() {
                    selectedCondition = value;
                  });
                  applyOverride();
                  Navigator.of(sheetContext).pop();
                },
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    ListTile(
                      key: const ValueKey('devtools_weather_title'),
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: const Text('Weather'),
                      subtitle: Text(
                        'Source: ${backendLabel(selectedBackend)}\nForce hero weather scenes during development',
                      ),
                    ),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Weather Source',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    RadioGroup<WeatherBackend>(
                      // Flutter 3.32+ deprecates per-tile groupValue/onChanged.
                      // Some channels also flag RadioGroup's legacy props; keep
                      // the behavior but silence the analyzer until the final
                      // API shape stabilizes.
                      // ignore: deprecated_member_use
                      groupValue: selectedBackend,
                      // ignore: deprecated_member_use
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          selectedBackend = v;
                        });
                        applyBackend(v);
                      },
                      child: Column(
                        children: [
                          RadioListTile<WeatherBackend>(
                            key: const ValueKey('devtools_weather_source_mock'),
                            title: Text(backendLabel(WeatherBackend.mock)),
                            value: WeatherBackend.mock,
                          ),
                          RadioListTile<WeatherBackend>(
                            key: const ValueKey(
                              'devtools_weather_source_openmeteo',
                            ),
                            title: Text(backendLabel(WeatherBackend.openMeteo)),
                            subtitle: const Text('No API key required'),
                            value: WeatherBackend.openMeteo,
                            enabled: _liveData.weatherNetworkAllowed,
                          ),
                          RadioListTile<WeatherBackend>(
                            key: const ValueKey(
                              'devtools_weather_source_weatherapi',
                            ),
                            title: Text(
                              backendLabel(WeatherBackend.weatherApi),
                            ),
                            subtitle: Text(
                              _liveData.canUseWeatherApi
                                  ? 'Requires WEATHERAPI_KEY'
                                  : 'Not configured (missing WEATHERAPI_KEY)',
                            ),
                            value: WeatherBackend.weatherApi,
                            enabled:
                                _liveData.weatherNetworkAllowed &&
                                _liveData.canUseWeatherApi,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Builder(
                        builder: (context) {
                          String ago(Duration d) {
                            if (d.inMinutes < 1) return 'just now';
                            if (d.inMinutes < 60) return '${d.inMinutes}m ago';
                            if (d.inHours < 24) return '${d.inHours}h ago';
                            return '${d.inDays}d ago';
                          }

                          final src = backendLabel(selectedBackend)
                              .replaceAll('Live: ', '')
                              .replaceAll('Demo (no network)', 'Demo');

                          final last = _liveData.lastRefreshedAt;
                          final line = _liveData.isRefreshing
                              ? '$src: Updating…'
                              : last == null
                              ? '$src: Last update: never'
                              : '$src: Last update: ${ago(DateTime.now().difference(last))}';

                          return Text(
                            line,
                            key: const ValueKey('devtools_weather_freshness'),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: SegmentedButton<_DevWeatherTimeOfDay>(
                        key: const ValueKey('devtools_weather_time_of_day'),
                        segments: const [
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.auto,
                            label: Text('Auto'),
                          ),
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.sun,
                            label: Text('Sun'),
                          ),
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.night,
                            label: Text('Night'),
                          ),
                        ],
                        selected: {selectedTimeOfDay},
                        onSelectionChanged: (selection) {
                          final next = selection.isEmpty
                              ? _DevWeatherTimeOfDay.auto
                              : selection.first;
                          setState(() {
                            selectedTimeOfDay = next;
                          });
                          applyOverride();
                        },
                      ),
                    ),
                    choiceTile(
                      key: const ValueKey('devtools_weather_default'),
                      title: 'Default (no visual override)',
                      value: null,
                    ),
                    for (final option in options)
                      choiceTile(
                        key: ValueKey('devtools_weather_${option.name}'),
                        title: _weatherLabel(option),
                        value: option,
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _clockOverrideSubtitle(Duration? offset) {
    if (offset == null) return 'Device clock (no offset)';
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final absMinutes = totalMinutes.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;
    if (minutes == 0) return 'Offset: $sign${hours}h';
    final padded = minutes.toString().padLeft(2, '0');
    return 'Offset: $sign${hours}h ${padded}m';
  }

  void _openClockOverrideSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        // Default offset value if enabling for the first time.
        final initial = _liveData.debugClockOffset ?? Duration.zero;

        // Store offset as minutes so the slider stays stable.
        double minutesValue = initial.inMinutes.toDouble();
        bool enabled = _liveData.debugClockOffset != null;

        void apply() {
          if (!enabled) {
            _liveData.setDebugClockOffset(null);
            return;
          }
          final next = Duration(minutes: minutesValue.round());
          _liveData.setDebugClockOffset(next);
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final subtitle = _clockOverrideSubtitle(
              enabled ? Duration(minutes: minutesValue.round()) : null,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule),
                        const SizedBox(width: 10),
                        Text(
                          'Clock Override',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      key: const ValueKey('devtools_clock_enabled'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable clock offset'),
                      subtitle: const Text(
                        'Applies a temporary UTC offset for simulator testing and screenshots.',
                      ),
                      value: enabled,
                      onChanged: (value) {
                        setState(() {
                          enabled = value;
                        });
                        apply();
                      },
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: enabled ? 1.0 : 0.45,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offset (hours)',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Slider(
                              key: const ValueKey(
                                'devtools_clock_offset_slider',
                              ),
                              value: minutesValue,
                              min: -12 * 60.0,
                              max: 12 * 60.0,
                              divisions: 48,
                              label:
                                  '${(minutesValue / 60).toStringAsFixed(1)}h',
                              onChanged: (next) {
                                setState(() {
                                  minutesValue = next;
                                });
                              },
                              onChangeEnd: (_) => apply(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDeveloperToolsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final weatherOverride = _liveData.debugWeatherOverride;
        final sourceLabel = switch (_liveData.weatherBackend) {
          WeatherBackend.mock => 'Demo (no network)',
          WeatherBackend.openMeteo => 'Live: Open-Meteo',
          WeatherBackend.weatherApi => 'Live: WeatherAPI',
        };
        final String weatherSubtitle;
        if (weatherOverride == null) {
          weatherSubtitle = 'Source: $sourceLabel · No override';
        } else if (weatherOverride is WeatherDebugOverrideCoarse) {
          final suffix = weatherOverride.isNightOverride == null
              ? ''
              : (weatherOverride.isNightOverride! ? ' (night)' : ' (sun)');
          weatherSubtitle =
              'Source: $sourceLabel · Forced: ${_weatherLabel(weatherOverride.condition)}$suffix';
        } else {
          final api = weatherOverride as WeatherDebugOverrideWeatherApi;
          final nightSuffix = api.isNight ? ' (night)' : '';
          weatherSubtitle =
              'Source: $sourceLabel · Forced: ${api.text} (#${api.code})$nightSuffix';
        }

        final clockSubtitle = _clockOverrideSubtitle(
          _liveData.debugClockOffset,
        );

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              ListTile(
                leading: const Icon(Icons.developer_mode),
                title: const Text('Developer Tools'),
                subtitle: const Text('Temporary tools for development and QA'),
              ),
              ListTile(
                key: const ValueKey('devtools_reset_restart'),
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset and Restart'),
                subtitle: const Text('Restore defaults and clear cached data'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _resetAndRestart();
                },
              ),
              ListTile(
                key: const ValueKey('devtools_weather_menu'),
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Weather'),
                subtitle: Text(weatherSubtitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openWeatherOverrideSheet();
                },
              ),
              ListTile(
                key: const ValueKey('devtools_clock_menu'),
                leading: const Icon(Icons.schedule),
                title: const Text('Clock Override'),
                subtitle: Text(clockSubtitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openClockOverrideSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resetDashboardDefaults() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Dashboard Defaults',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'This removes any widgets you\'ve added and restores the default dashboard layout.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    await _layout.resetDashboardDefaults();
    if (!mounted) return;

    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });

    UnitanaToast.showSuccess(
      context,
      'Dashboard reset to defaults.',
      key: const ValueKey('toast_dashboard_reset_defaults'),
    );
  }

  (Place?, Place?) _resolveHomeDestination() {
    Place? home;
    Place? destination;

    for (final p in state.places) {
      if (home == null && p.type == PlaceType.living) home = p;
      if (destination == null && p.type != PlaceType.living) destination = p;
    }

    return (home, destination);
  }

  bool _preferMetricForReality() {
    // Align tool defaults with the currently selected "reality" in Places Hero.
    final (home, destination) = _resolveHomeDestination();

    final primary = _session.reality == DashboardReality.home
        ? home
        : destination;
    final unitSystem = (primary?.unitSystem ?? 'metric').toLowerCase();
    return unitSystem == 'metric';
  }

  bool _prefer24hForReality() {
    // Time format is configured per-place (wizard) and is driven by the active
    // Places Hero reality.
    final (home, destination) = _resolveHomeDestination();

    final primary = _session.reality == DashboardReality.home
        ? home
        : destination;
    return primary?.use24h ?? false;
  }

  Future<void> _openToolPickerAndRun(BuildContext context) async {
    final picked = await showModalBottomSheet<ToolDefinition>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => ToolPickerSheet(session: _session),
    );

    if (picked == null) return;
    if (!context.mounted) return;

    final (home, destination) = _resolveHomeDestination();

    await ToolModalBottomSheet.show(
      context,
      tool: picked,
      session: _session,
      preferMetric: _preferMetricForReality(),
      prefer24h: _prefer24hForReality(),
      eurToUsd: _liveData.eurToUsd,
      home: home,
      destination: destination,
      canAddWidget: true,
      onAddWidget: () async {
        if (_dashboardHasToolId(picked.id)) {
          throw DuplicateDashboardWidgetException(
            toolId: picked.id,
            title: picked.title,
          );
        }
        await _layout.addTool(picked);
      },
    );
  }

  bool _dashboardHasToolId(String toolId) {
    // Includes the default, always-present tiles and user-added tiles.
    if (ToolDefinitions.defaultTiles.any((t) => t.id == toolId)) return true;
    return _layout.items.any((i) => i.toolId == toolId);
  }

  void _comingSoon(BuildContext context, String label) {
    UnitanaToast.showInfo(context, '$label: coming soon');
  }

  void _openToolPickerFromMenu() {
    if (!mounted) return;
    _openToolPickerAndRun(context);
  }

  void _enterEditWidgets({String? focusTileId}) {
    if (_isEditingWidgets) return;
    _layout.beginEdit();
    setState(() {
      _isEditingWidgets = true;
      _focusTileId = focusTileId;
    });
  }

  Future<void> _exitEditWidgetsCancel() async {
    if (!_isEditingWidgets) return;
    _layout.cancelEdit();
    if (!mounted) return;
    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
  }

  Future<void> _exitEditWidgetsDone() async {
    if (!_isEditingWidgets) return;
    await _layout.commitEdit();
    if (!mounted) return;
    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
    if (!mounted) return;
    UnitanaToast.showSuccess(context, 'Dashboard updated');
  }

  void _maybeAutoRefreshWeather(List<Place> places) {
    final isLive =
        _liveData.weatherNetworkEnabled &&
        _liveData.weatherBackend != WeatherBackend.mock;
    if (!isLive) return;
    if (_liveData.isRefreshing) return;

    final last = _liveData.lastRefreshedAt;
    final now = DateTime.now();
    const staleAfter = Duration(minutes: 10);
    final isStale = last == null || now.difference(last) > staleAfter;
    if (!isStale) return;

    final prev = _lastAutoWeatherRefreshAttemptAt;
    if (prev != null && now.difference(prev) < const Duration(seconds: 30)) {
      return;
    }
    _lastAutoWeatherRefreshAttemptAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _liveData.refreshAll(places: places);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileName = state.profileName.trim().isEmpty
        ? 'My Places'
        : state.profileName.trim();

    return AnimatedBuilder(
      animation: Listenable.merge([_session, _liveData, _layout]),
      builder: (context, _) {
        _maybeAutoRefreshWeather(state.places);
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            // AppBar has a fixed height (typically 56). Avoid stacking text
            // under the icon here because it causes overflows on small phones.
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _HeaderIconButton(
                key: const Key('dashboard_tools_button'),
                tooltip: 'Tools',
                icon: Icons.handyman_rounded,
                onTap: _openToolPickerFromMenu,
              ),
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                profileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.robotoSlab(
                      textStyle: Theme.of(context).textTheme.titleLarge,
                    ).copyWith(
                      fontSize: 28,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            actions: [
              if (_isEditingWidgets) ...[
                IconButton(
                  key: const Key('dashboard_edit_cancel'),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: _exitEditWidgetsCancel,
                ),
                IconButton(
                  key: const Key('dashboard_edit_done'),
                  icon: const Icon(Icons.check),
                  tooltip: 'Done',
                  onPressed: _exitEditWidgetsDone,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _HeaderIconButton(
                    key: const Key('dashboard_menu_button'),
                    tooltip: 'Menu',
                    icon: Icons.menu_rounded,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheetContext) {
                          // Bottom sheets are particularly prone to small-phone
                          // overflows when built as a natural-height Column.
                          // Use a scrollable list so the sheet can adapt to
                          // tight viewports without RenderFlex overflow.
                          return SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(bottom: 8),
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit widgets'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    Future.microtask(() {
                                      if (!mounted) return;
                                      _enterEditWidgets();
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.switch_account),
                                  title: const Text('Switch profile'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _comingSoon(context, 'Switch profile');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.person_add_alt_1),
                                  title: const Text('Add profile'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _comingSoon(context, 'Add profile');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.settings),
                                  title: const Text('Settings'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _comingSoon(context, 'Settings');
                                  },
                                ),
                                ListTile(
                                  key: const ValueKey(
                                    'dashboard_menu_reset_defaults',
                                  ),
                                  leading: const Icon(Icons.restore),
                                  title: const Text('Reset Dashboard Defaults'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    Future.microtask(_resetDashboardDefaults);
                                  },
                                ),
                                ListTile(
                                  key: const ValueKey(
                                    'dashboard_menu_developer_tools',
                                  ),
                                  leading: const Icon(Icons.developer_mode),
                                  title: const Text('Developer Tools'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    Future.microtask(_openDeveloperToolsSheet);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final padding = width >= 600
                  ? const EdgeInsets.all(24)
                  : const EdgeInsets.all(16);

              final availableWidth = width - padding.horizontal;

              // Sticky hero (Option A, compact overlay): we preserve the hero
              // tile and grid indexing for persistence, but we surface a
              // compact, always-actionable reality toggle once the hero has
              // scrolled mostly out of view.
              const gridGap = 12.0;
              const tileHeightRatio = 0.78;
              final cols = availableWidth >= 520 ? 3 : 2;
              final tileW = (availableWidth - (cols - 1) * gridGap) / cols;
              final tileH = tileW * tileHeightRatio;
              final heroHeight = (2 * tileH) + gridGap;

              const pinnedHeight = 104.0;
              final showPinned =
                  (DashboardScreen.debugForcePinnedHeroVisible) ||
                  (!_isEditingWidgets &&
                      _scrollOffset > (heroHeight - pinnedHeight * 0.75));

              // C3a: sliver migration foundation.
              //
              // Keep behavior identical to SingleChildScrollView for now
              // (hero and tiles scroll together). This unlocks a pinned header
              // in a later slice without increasing current layout risk.
              return Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: padding,
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Single, unified refresh indicator.
                              // Contract: visible under the city header, never
                              // inside the hero marquee.
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: DataRefreshStatusLabel(
                                    liveData: _liveData,
                                    compact: false,
                                    showBackground: true,
                                  ),
                                ),
                              ),
                              DashboardBoard(
                                state: state,
                                session: _session,
                                liveData: _liveData,
                                layout: _layout,
                                availableWidth: availableWidth,
                                isEditing: _isEditingWidgets,
                                focusActionTileId: _focusTileId,
                                onEnteredEditMode: (tileId) {
                                  if (_isEditingWidgets) return;
                                  _enterEditWidgets(focusTileId: tileId);
                                },
                                onConsumedFocusTileId: () {
                                  if (_focusTileId == null) return;
                                  setState(() {
                                    _focusTileId = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _PinnedHeroOverlay(
                      key: const ValueKey('dashboard_pinned_hero'),
                      visible: showPinned,
                      height: pinnedHeight,
                      horizontalPadding: padding.horizontal / 2,
                      places: state.places,
                      session: _session,
                      liveData: _liveData,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PinnedHeroOverlay extends StatelessWidget {
  final bool visible;
  final double height;
  final double horizontalPadding;
  final List<Place> places;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;

  const _PinnedHeroOverlay({
    super.key,
    required this.visible,
    required this.height,
    required this.horizontalPadding,
    required this.places,
    required this.session,
    required this.liveData,
  });

  Place? _pickHome(List<Place> places) {
    for (final p in places) {
      if (p.type == PlaceType.living) return p;
    }
    return places.isEmpty ? null : places.last;
  }

  Place? _pickDestination(List<Place> places) {
    for (final p in places) {
      if (p.type == PlaceType.visiting) return p;
    }
    return places.isEmpty ? null : places.first;
  }

  String _flagEmoji(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) return '';
    final a = code.codeUnitAt(0);
    final b = code.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) return '';
    return String.fromCharCode(0x1F1E6 + (a - 65)) +
        String.fromCharCode(0x1F1E6 + (b - 65));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final home = _pickHome(places);
    final dest = _pickDestination(places);

    if (home == null || dest == null) {
      return const SizedBox.shrink();
    }

    final isHome = session.reality == DashboardReality.home;
    final active = isHome ? home : dest;
    // Primary/secondary are only for the pinned overlay cockpit row.
    // Primary is the active "reality" place.
    final primary = active;
    final secondary = isHome ? dest : home;

    final homeLabel = '${_flagEmoji(home.countryCode)} ${home.cityName}'.trim();
    final destLabel = '${_flagEmoji(dest.countryCode)} ${dest.cityName}'.trim();

    final bar = Material(
      elevation: 1,
      color: cs.surface.withAlpha(242),
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactRealityToggle(
              key: const ValueKey('dashboard_pinned_reality_toggle'),
              isHome: isHome,
              homeLabel: homeLabel,
              destLabel: destLabel,
              onPickHome: () => session.setReality(DashboardReality.home),
              onPickDestination: () =>
                  session.setReality(DashboardReality.destination),
            ),
            const SizedBox(height: 8),
            _PinnedCockpitRow(
              session: session,
              primary: primary,
              secondary: secondary,
              liveData: liveData,
            ),
          ],
        ),
      ),
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      offset: visible ? Offset.zero : const Offset(0, -0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: IgnorePointer(ignoring: !visible, child: bar),
      ),
    );
  }
}

class _PinnedCockpitRow extends StatelessWidget {
  final DashboardSessionController session;
  final Place primary;
  final Place secondary;
  final DashboardLiveDataController liveData;

  const _PinnedCockpitRow({
    required this.session,
    required this.primary,
    required this.secondary,
    required this.liveData,
  });

  List<String> _currencyLines({
    required String fromCode,
    required String toCode,
    required double eurToUsd,
  }) {
    // Mirrors PlacesHeroV2 formatting, but kept local to avoid a cross-widget
    // dependency for pinned overlay rendering.
    if (fromCode.toUpperCase() == 'EUR' && toCode.toUpperCase() == 'USD') {
      final approx = (10 * eurToUsd).round();
      return ['€10≈\$$approx', '1€≈\$${eurToUsd.toStringAsFixed(2)}'];
    }
    if (fromCode.toUpperCase() == 'USD' && toCode.toUpperCase() == 'EUR') {
      final inv = eurToUsd == 0 ? 0 : 1 / eurToUsd;
      final approx = (10 * inv).round();
      return ['\$10≈€$approx', '1\$≈€${inv.toStringAsFixed(2)}'];
    }
    // Fallback for future pairs.
    final approx = (10 * eurToUsd).round();
    return [
      '${fromCode.toUpperCase()}10≈${toCode.toUpperCase()}$approx',
      '1${fromCode.toUpperCase()}≈${toCode.toUpperCase()}${eurToUsd.toStringAsFixed(2)}',
    ];
  }

  String _currencyForPlace(Place place) {
    // Lightweight and intentionally limited for the MVP.
    // We can expand this into a richer mapping or ISO currency lookup later.
    switch (place.countryCode.toUpperCase()) {
      case 'US':
        return 'USD';
      default:
        return 'EUR';
    }
  }

  List<String> _windLines({required double windKmh, required double gustKmh}) {
    final windMph = windKmh * 0.621371;
    final gustMph = gustKmh * 0.621371;

    final useImperial = primary.unitSystem.toLowerCase() == 'imperial';
    if (useImperial) {
      return [
        '${windMph.round()} mph (${windKmh.round()} km/h)',
        '${gustMph.round()} mph (${gustKmh.round()} km/h) gust',
      ];
    }
    return [
      '${windKmh.round()} km/h (${windMph.round()} mph)',
      '${gustKmh.round()} km/h (${gustMph.round()} mph) gust',
    ];
  }

  String _timeLine() {
    final zt = TimezoneUtils.nowInZone(
      primary.timeZoneId,
      nowUtc: liveData.nowUtc,
    );
    final primaryTime = TimezoneUtils.formatClock(zt, use24h: primary.use24h);
    final secondaryTime = TimezoneUtils.formatClock(
      zt,
      use24h: !primary.use24h,
    );
    return '$primaryTime ($secondaryTime)';
  }

  String _tempLine() {
    final weather = liveData.weatherFor(primary);
    final tempC = weather?.temperatureC.round();
    if (tempC == null) return 'Temp —';
    final tempF = (tempC * 9 / 5 + 32).round();

    final useImperial = primary.unitSystem.toLowerCase() == 'imperial';
    if (useImperial) {
      return '$tempF°F ($tempC°C)';
    }
    return '$tempC°C ($tempF°F)';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final baseText = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: cs.onSurface.withAlpha(225),
      fontWeight: FontWeight.w700,
    );
    final secondaryText = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurface.withAlpha(205),
      fontWeight: FontWeight.w700,
    );

    // Pinned hero pills must never truncate with ellipsis. When space is tight
    // we scale down text to keep full content readable.
    Widget scaleLine(String text, TextStyle? style, {Key? key}) {
      return SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            key: key,
            maxLines: 1,
            softWrap: false,
            style: style,
          ),
        ),
      );
    }

    Widget pill({
      required Key key,
      required IconData icon,
      required Widget child,
      VoidCallback? onTap,
      Widget? trailing,
    }) {
      final content = Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withAlpha(210)),
          const SizedBox(width: 8),
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      );

      final pillBody = Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(89),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withAlpha(179), width: 1),
        ),
        child: content,
      );

      if (onTap == null) return pillBody;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: pillBody,
      );
    }

    final timeLine = _timeLine();
    final tempLine = _tempLine();

    final from = _currencyForPlace(primary);
    final to = _currencyForPlace(secondary);
    final currencyLines = _currencyLines(
      fromCode: from,
      toCode: to,
      eurToUsd: liveData.eurToUsd,
    );

    final weather = liveData.weatherFor(primary);
    final windLines = _windLines(
      windKmh: weather?.windKmh ?? 0,
      gustKmh: weather?.gustKmh ?? 0,
    );

    final sun = liveData.sunFor(primary);
    String sunRise = '—';
    String sunSet = '—';
    if (sun != null) {
      final riseZt = TimezoneUtils.nowInZone(
        primary.timeZoneId,
        nowUtc: sun.sunriseUtc,
      );
      final setZt = TimezoneUtils.nowInZone(
        primary.timeZoneId,
        nowUtc: sun.sunsetUtc,
      );
      sunRise = TimezoneUtils.formatClock(riseZt, use24h: primary.use24h);
      sunSet = TimezoneUtils.formatClock(setZt, use24h: primary.use24h);
    }

    final isSun = session.pinnedHeroDetailsMode == PinnedHeroDetailsMode.sun;

    Widget detailsBody;
    if (isSun) {
      detailsBody = Column(
        key: const ValueKey('dashboard_pinned_details_sun'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          scaleLine(sunRise, baseText),
          const SizedBox(height: 1),
          scaleLine(sunSet, secondaryText),
        ],
      );
    } else {
      detailsBody = Column(
        key: const ValueKey('dashboard_pinned_details_wind'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          scaleLine(windLines[0], baseText),
          const SizedBox(height: 1),
          scaleLine(windLines[1], secondaryText),
        ],
      );
    }

    final swap = _PulseSwapIcon(color: cs.primary.withAlpha(230));

    Widget timeTempPill() {
      return pill(
        key: const ValueKey('dashboard_pinned_time_temp_pill'),
        icon: Icons.schedule_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            scaleLine(timeLine, baseText),
            const SizedBox(height: 1),
            scaleLine(tempLine, secondaryText),
          ],
        ),
      );
    }

    Widget currencyPill() {
      return pill(
        key: const ValueKey('dashboard_pinned_currency_pill'),
        icon: Icons.currency_exchange_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            scaleLine(currencyLines[0], baseText),
            const SizedBox(height: 1),
            scaleLine(currencyLines[1], secondaryText),
          ],
        ),
      );
    }

    Widget detailsPill() {
      return pill(
        key: const ValueKey('dashboard_pinned_details_pill'),
        icon: isSun ? Icons.wb_sunny_rounded : Icons.air_rounded,
        onTap: session.togglePinnedHeroDetailsMode,
        trailing: swap,
        child: SizedBox(
          height: 34,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: detailsBody,
          ),
        ),
      );
    }

    // Contract: pinned mini-hero cockpit must stay single-row only (no stacking).
    return Row(
      key: const ValueKey('dashboard_pinned_cockpit_row'),
      children: [
        Expanded(flex: 4, child: timeTempPill()),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: currencyPill()),
        const SizedBox(width: 10),
        Expanded(flex: 5, child: detailsPill()),
      ],
    );
  }
}

class _PulseSwapIcon extends StatefulWidget {
  final Color color;

  const _PulseSwapIcon({required this.color});

  @override
  State<_PulseSwapIcon> createState() => _PulseSwapIconState();
}

class _PulseSwapIconState extends State<_PulseSwapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  bool get _isTest {
    // Prefer the compile-time flag when present.
    if (bool.fromEnvironment('FLUTTER_TEST')) return true;
    // Fall back to a binding type-name check (works across runners).
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  }

  void _syncAnimation() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tickerEnabled = TickerMode.of(context);
    final shouldAnimate = !_isTest && !disableAnimations && tickerEnabled;

    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.55), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulseSwapIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(Icons.swap_horiz_rounded, size: 18, color: widget.color),
    );
  }
}

class _CompactRealityToggle extends StatelessWidget {
  final bool isHome;
  final String homeLabel;
  final String destLabel;
  final VoidCallback onPickHome;
  final VoidCallback onPickDestination;

  const _CompactRealityToggle({
    super.key,
    required this.isHome,
    required this.homeLabel,
    required this.destLabel,
    required this.onPickHome,
    required this.onPickDestination,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHighest.withAlpha(77);
    final border = cs.outlineVariant.withAlpha(179);

    Widget segment({
      required bool selected,
      required String text,
      required VoidCallback onTap,
      required Key key,
    }) {
      return Expanded(
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer.withAlpha(140) : bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface.withAlpha(230),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          segment(
            key: const ValueKey('dashboard_pinned_segment_destination'),
            selected: !isHome,
            text: destLabel,
            onTap: onPickDestination,
          ),
          const SizedBox(width: 6),
          segment(
            key: const ValueKey('dashboard_pinned_segment_home'),
            selected: isHome,
            text: homeLabel,
            onTap: onPickHome,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  // AppBar's toolbar height is typically 56. Using the same square size here
  // ensures the leading and actions slots resolve to identical tap targets and
  // avoids constraint-driven size drift between the left and right buttons.
  static const double _size = 56;
  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(89),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: cs.outlineVariant.withAlpha(179),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: cs.onSurface.withAlpha(210)),
        ),
      ),
    );
  }
}
