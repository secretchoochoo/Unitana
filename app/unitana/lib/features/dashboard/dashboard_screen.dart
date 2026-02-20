import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app_state.dart';
import '../../common/tutorial/tutorial_overlay.dart';
import '../../data/city_repository.dart';
import '../../models/place.dart';
import '../../common/feedback/unitana_toast.dart';
import '../first_run/first_run_screen.dart';
import 'models/dashboard_live_data.dart';
import 'models/dashboard_layout_controller.dart';
import 'models/dashboard_session_controller.dart';
import 'models/dashboard_exceptions.dart';
import 'models/dashboard_copy.dart';
import 'models/freshness_copy.dart';
import 'models/lofi_audio_controller.dart';
import 'models/tool_definitions.dart';
import 'widgets/dashboard_board.dart';
import 'widgets/data_refresh_status_label.dart';
import 'widgets/places_hero_collapsing_header.dart';
import 'widgets/profiles_board_screen.dart';
import 'widgets/settings_licenses_page.dart';
import 'widgets/tool_modal_bottom_sheet.dart';
import 'widgets/destructive_confirmation_sheet.dart';
import 'widgets/weather_summary_bottom_sheet.dart';

/// Developer-only time-of-day override for weather scene previews.
///
/// Kept file-private because this is not part of the public widget API.
enum _DevWeatherTimeOfDay { auto, sun, night }

enum _DevWeatherEmergencyMode {
  auto,
  none,
  advisory,
  watch,
  warning,
  emergency,
}

class DashboardScreen extends StatefulWidget {
  final UnitanaAppState state;

  @visibleForTesting
  static bool debugForcePinnedHeroVisible = false;

  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const double _kEditAppBarActionFontSize = 14;
  static const double _kAppBarTitleMaxFontSize = 28;
  static const double _kAppBarTitleMinFontSize = 18;
  static const double _kRefreshClusterVisualNudgeX = 10;
  static const Duration _kWeatherAutoRefreshStaleAfter = Duration(minutes: 10);
  static const Duration _kWeatherAutoRefreshMinInterval = Duration(seconds: 30);
  static const String _kBuildVersion = String.fromEnvironment(
    'UNITANA_APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const String _kBuildNumber = String.fromEnvironment(
    'UNITANA_BUILD_NUMBER',
    defaultValue: '100',
  );
  static const String _kBuildChannel = String.fromEnvironment(
    'UNITANA_BUILD_CHANNEL',
    defaultValue: 'Release',
  );
  static const bool _kDeveloperToolsEnabled = bool.fromEnvironment(
    'UNITANA_DEVTOOLS_ENABLED',
    defaultValue: false,
  );
  static const bool _kIsFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  late DashboardSessionController _session;
  late final DashboardLiveDataController _liveData;
  late DashboardLayoutController _layout;

  late final ScrollController _scrollController;
  late final LofiAudioController _lofiAudioController;
  bool _appIsInForeground = true;

  DateTime? _lastAutoWeatherRefreshAttemptAt;

  bool _isEditingWidgets = false;
  String? _focusTileId;
  String? _focusToolTileId;
  bool _showDashboardTutorial = false;
  bool _showDashboardEditTutorial = false;

  final GlobalKey _tutorialToolsButtonKey = GlobalKey();
  final GlobalKey _tutorialMenuButtonKey = GlobalKey();
  final GlobalKey _tutorialRefreshKey = GlobalKey();
  final GlobalKey _tutorialWidgetsKey = GlobalKey();
  final GlobalKey _tutorialEditDoneKey = GlobalKey();

  UnitanaAppState get state => widget.state;

  TextStyle _baseAppBarTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleLarge ?? const TextStyle())
        .merge(GoogleFonts.robotoSlab())
        .copyWith(height: 1.0, fontWeight: FontWeight.w800);
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  double _estimatedEditActionsWidth(BuildContext context) {
    final actionStyle =
        (Theme.of(context).textTheme.labelLarge ??
                const TextStyle(fontSize: _kEditAppBarActionFontSize))
            .copyWith(fontSize: _kEditAppBarActionFontSize);
    final cancelWidth = _measureTextWidth(
      DashboardCopy.dashboardEditCancel(context),
      actionStyle,
    );
    final doneWidth = _measureTextWidth(
      DashboardCopy.dashboardEditDone(context),
      actionStyle,
    );

    // button internal horizontal padding (6 + 6) for both buttons
    const buttonPadding = 24.0;
    // trailing outer padding on "Done" segment
    const trailingPad = 4.0;
    // small cushion so title doesn't visually crowd controls
    const safety = 8.0;

    return cancelWidth + doneWidth + (buttonPadding * 2) + trailingPad + safety;
  }

  double _resolveAppBarTitleFontSize(BuildContext context, String profileName) {
    final width = MediaQuery.of(context).size.width;

    // Leading reserves the tools button slot (72) + left inset cushion.
    const leftReserve = 88.0;
    // Right reserve depends on whether edit controls are shown.
    final rightReserve = _isEditingWidgets
        ? _estimatedEditActionsWidth(context)
        : 88.0;

    final maxTitleWidth = width - leftReserve - rightReserve;
    if (maxTitleWidth <= 80) return _kAppBarTitleMinFontSize;

    final base = _baseAppBarTitleStyle(context);
    var size = _kAppBarTitleMaxFontSize;
    while (size > _kAppBarTitleMinFontSize) {
      final style = base.copyWith(fontSize: size);
      if (_measureTextWidth(profileName, style) <= maxTitleWidth) {
        break;
      }
      size -= 1;
    }
    if (size < _kAppBarTitleMinFontSize) return _kAppBarTitleMinFontSize;
    return size;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appIsInForeground = _isLifecycleForeground(
      WidgetsBinding.instance.lifecycleState,
    );
    _liveData = DashboardLiveDataController();
    if (_kDeveloperToolsEnabled) {
      _liveData.loadDevSettings();
    }
    _bindProfileScopedControllers();

    _scrollController = ScrollController();
    _lofiAudioController = LofiAudioController();
    state.addListener(_onAppStateChanged);
    _syncLofiAudioFromState();

    // Kick off an initial refresh so the hero is never stuck showing placeholders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLofiAudioFromState();
      _refreshAllNow();
      final pendingSuccess = state.consumePendingSuccessToast();
      if (!mounted) return;
      if (pendingSuccess != null) {
        UnitanaToast.showSuccess(context, pendingSuccess);
      }
      _maybeStartDashboardTutorial();
    });
  }

  void _maybeStartDashboardTutorial() {
    if (_kIsFlutterTest) return;
    if (state.tutorialDismissed && !state.tutorialReplayRequested) return;
    if (_isEditingWidgets) return;
    if (_showDashboardTutorial) return;
    if (state.hasCompletedTutorialSurface('dashboard')) return;
    setState(() => _showDashboardTutorial = true);
  }

  Future<void> _completeDashboardTutorial() async {
    if (!mounted) return;
    setState(() => _showDashboardTutorial = false);
    await state.markTutorialSurfaceCompleted('dashboard');
  }

  Future<void> _completeDashboardEditTutorial() async {
    if (!mounted) return;
    setState(() => _showDashboardEditTutorial = false);
    await state.markTutorialSurfaceCompleted('dashboard_edit');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.removeListener(_onAppStateChanged);
    _scrollController.dispose();
    _session.dispose();
    _liveData.dispose();
    _layout.dispose();
    _lofiAudioController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    final dashboardCompleted = state.hasCompletedTutorialSurface('dashboard');
    final editCompleted = state.hasCompletedTutorialSurface('dashboard_edit');
    if ((_showDashboardTutorial && dashboardCompleted) ||
        (_showDashboardEditTutorial && editCompleted)) {
      setState(() {
        if (dashboardCompleted) _showDashboardTutorial = false;
        if (editCompleted) _showDashboardEditTutorial = false;
      });
    }
    _syncLofiAudioFromState();
  }

  void _syncLofiAudioFromState() {
    _lofiAudioController.apply(
      enabled: state.lofiAudioEnabled && _appIsInForeground,
      volume: state.lofiAudioVolume,
    );
  }

  bool _isLifecycleForeground(AppLifecycleState? lifecycleState) {
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final nextIsForeground = _isLifecycleForeground(lifecycleState);
    if (_appIsInForeground == nextIsForeground) return;
    _appIsInForeground = nextIsForeground;
    _syncLofiAudioFromState();
  }

  void _bindProfileScopedControllers() {
    final namespace = state.activePrefsNamespace;
    _session = DashboardSessionController(prefsNamespace: namespace);
    _session.loadPersisted();
    _layout = DashboardLayoutController(prefsNamespace: namespace);
    _layout.load();
  }

  Future<void> _switchActiveProfileAndReload(String profileId) async {
    await state.switchToProfile(profileId);
    if (!mounted) return;

    _session.dispose();
    _layout.dispose();
    _bindProfileScopedControllers();

    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
    await _refreshAllNow();
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

  String _weatherLabel(BuildContext context, WeatherCondition condition) {
    final conditionKey = switch (condition) {
      WeatherCondition.clear => 'clear',
      WeatherCondition.partlyCloudy => 'partlyCloudy',
      WeatherCondition.cloudy => 'cloudy',
      WeatherCondition.overcast => 'overcast',
      WeatherCondition.drizzle => 'drizzle',
      WeatherCondition.rain => 'rain',
      WeatherCondition.thunderstorm => 'thunderstorm',
      WeatherCondition.snow => 'snow',
      WeatherCondition.sleet => 'sleet',
      WeatherCondition.hail => 'hail',
      WeatherCondition.fog => 'fog',
      WeatherCondition.mist => 'mist',
      WeatherCondition.haze => 'haze',
      WeatherCondition.smoke => 'smoke',
      WeatherCondition.dust => 'dust',
      WeatherCondition.sand => 'sand',
      WeatherCondition.ash => 'ash',
      WeatherCondition.squall => 'squall',
      WeatherCondition.tornado => 'tornado',
      WeatherCondition.windy => 'windy',
    };
    return DashboardCopy.devtoolsWeatherConditionLabel(
      context,
      conditionKey: conditionKey,
    );
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
        final initialEmergencyOverride =
            _liveData.debugEmergencySeverityOverride;

        _DevWeatherTimeOfDay initialTimeOfDay() {
          if (initialIsNightOverride == true) return _DevWeatherTimeOfDay.night;
          if (initialIsNightOverride == false) return _DevWeatherTimeOfDay.sun;
          return _DevWeatherTimeOfDay.auto;
        }

        final options = WeatherCondition.values.toList()
          ..sort(
            (a, b) =>
                _weatherLabel(context, a).compareTo(_weatherLabel(context, b)),
          );

        WeatherCondition? selectedCondition = initialCondition;
        _DevWeatherTimeOfDay selectedTimeOfDay = initialTimeOfDay();
        _DevWeatherEmergencyMode selectedEmergency =
            switch (initialEmergencyOverride) {
              null => _DevWeatherEmergencyMode.auto,
              WeatherEmergencySeverity.none => _DevWeatherEmergencyMode.none,
              WeatherEmergencySeverity.advisory =>
                _DevWeatherEmergencyMode.advisory,
              WeatherEmergencySeverity.watch => _DevWeatherEmergencyMode.watch,
              WeatherEmergencySeverity.warning =>
                _DevWeatherEmergencyMode.warning,
              WeatherEmergencySeverity.emergency =>
                _DevWeatherEmergencyMode.emergency,
            };
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

            void applyEmergencyOverride(_DevWeatherEmergencyMode mode) {
              final value = switch (mode) {
                _DevWeatherEmergencyMode.auto => null,
                _DevWeatherEmergencyMode.none => WeatherEmergencySeverity.none,
                _DevWeatherEmergencyMode.advisory =>
                  WeatherEmergencySeverity.advisory,
                _DevWeatherEmergencyMode.watch =>
                  WeatherEmergencySeverity.watch,
                _DevWeatherEmergencyMode.warning =>
                  WeatherEmergencySeverity.warning,
                _DevWeatherEmergencyMode.emergency =>
                  WeatherEmergencySeverity.emergency,
              };
              _liveData.setDebugEmergencySeverityOverride(value);
            }

            String backendLabel(WeatherBackend b) {
              final key = switch (b) {
                WeatherBackend.mock => 'mock',
                WeatherBackend.openMeteo => 'openMeteo',
                WeatherBackend.weatherApi => 'weatherApi',
              };
              return DashboardCopy.devtoolsWeatherBackendLabel(
                context,
                backendKey: key,
              );
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
                      child: Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DashboardCopy.devtoolsWeatherTitle(context),
                              key: const ValueKey('devtools_weather_title'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: DashboardCopy.commonBackTooltip(context),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              Future.microtask(_openDeveloperToolsSheet);
                            },
                          ),
                          _sheetCloseButton(sheetContext),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        DashboardCopy.devtoolsWeatherSourceSummary(
                          context,
                          backendLabel(selectedBackend),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        DashboardCopy.devtoolsWeatherSourceHeading(context),
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
                            subtitle: Text(
                              DashboardCopy.devtoolsWeatherNoApiKey(context),
                            ),
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
                                  ? DashboardCopy.devtoolsWeatherRequiresApiKey(
                                      context,
                                    )
                                  : DashboardCopy.devtoolsWeatherMissingApiKey(
                                      context,
                                    ),
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
                          final src =
                              DashboardCopy.devtoolsWeatherBackendShortLabel(
                                context,
                                backendKey: switch (selectedBackend) {
                                  WeatherBackend.mock => 'mock',
                                  WeatherBackend.openMeteo => 'openMeteo',
                                  WeatherBackend.weatherApi => 'weatherApi',
                                },
                              );

                          final last = _liveData.lastRefreshedAt;
                          final line = _liveData.isRefreshing
                              ? '$src: ${DashboardCopy.updating(context)}'
                              : last == null
                              ? DashboardCopy.devtoolsWeatherFreshnessNever(
                                  context,
                                  sourceShortLabel: src,
                                )
                              : DashboardCopy.devtoolsWeatherFreshnessUpdated(
                                  context,
                                  sourceShortLabel: src,
                                  age: FreshnessCopy.relativeAgeShort(
                                    now: DateTime.now(),
                                    then: last,
                                  ),
                                );

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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        DashboardCopy.devtoolsWeatherEmergencyOverrideTitle(
                          context,
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: SegmentedButton<_DevWeatherEmergencyMode>(
                        key: const ValueKey('devtools_weather_emergency_mode'),
                        segments: <ButtonSegment<_DevWeatherEmergencyMode>>[
                          ButtonSegment(
                            value: _DevWeatherEmergencyMode.auto,
                            label: Text(
                              DashboardCopy.devtoolsWeatherEmergencyMode(
                                context,
                                modeKey: 'auto',
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: _DevWeatherEmergencyMode.watch,
                            label: Text(
                              DashboardCopy.devtoolsWeatherEmergencyMode(
                                context,
                                modeKey: 'watch',
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: _DevWeatherEmergencyMode.warning,
                            label: Text(
                              DashboardCopy.devtoolsWeatherEmergencyMode(
                                context,
                                modeKey: 'warning',
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: _DevWeatherEmergencyMode.emergency,
                            label: Text(
                              DashboardCopy.devtoolsWeatherEmergencyMode(
                                context,
                                modeKey: 'emergency',
                              ),
                            ),
                          ),
                        ],
                        selected: <_DevWeatherEmergencyMode>{selectedEmergency},
                        onSelectionChanged: (selection) {
                          final next = selection.isEmpty
                              ? _DevWeatherEmergencyMode.auto
                              : selection.first;
                          setState(() {
                            selectedEmergency = next;
                          });
                          applyEmergencyOverride(next);
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
                        segments: [
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.auto,
                            label: Text(
                              DashboardCopy.devtoolsWeatherTimeAuto(context),
                            ),
                          ),
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.sun,
                            label: Text(
                              DashboardCopy.devtoolsWeatherTimeSun(context),
                            ),
                          ),
                          ButtonSegment(
                            value: _DevWeatherTimeOfDay.night,
                            label: Text(
                              DashboardCopy.devtoolsWeatherTimeNight(context),
                            ),
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
                      title: DashboardCopy.devtoolsWeatherDefaultChoice(
                        context,
                      ),
                      value: null,
                    ),
                    for (final option in options)
                      choiceTile(
                        key: ValueKey('devtools_weather_${option.name}'),
                        title: _weatherLabel(context, option),
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

  String _clockOverrideSubtitle(BuildContext context, Duration? offset) {
    if (offset == null) {
      return DashboardCopy.devtoolsClockDeviceSubtitle(context);
    }
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final absMinutes = totalMinutes.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;
    if (minutes == 0) {
      return DashboardCopy.devtoolsClockOffsetSubtitle(
        context,
        offsetText: '$sign${hours}h',
      );
    }
    final padded = minutes.toString().padLeft(2, '0');
    return DashboardCopy.devtoolsClockOffsetSubtitle(
      context,
      offsetText: '$sign${hours}h ${padded}m',
    );
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
              context,
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
                        Expanded(
                          child: Text(
                            DashboardCopy.devtoolsClockTitle(context),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: DashboardCopy.commonBackTooltip(context),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            Future.microtask(_openDeveloperToolsSheet);
                          },
                        ),
                        _sheetCloseButton(sheetContext),
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
                      title: Text(
                        DashboardCopy.devtoolsClockEnableTitle(context),
                      ),
                      subtitle: Text(
                        DashboardCopy.devtoolsClockEnableHelp(context),
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
                              DashboardCopy.devtoolsClockOffsetHoursLabel(
                                context,
                              ),
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
                        child: Text(DashboardCopy.dashboardEditDone(context)),
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
        final sourceLabel = DashboardCopy.devtoolsWeatherBackendLabel(
          sheetContext,
          backendKey: switch (_liveData.weatherBackend) {
            WeatherBackend.mock => 'mock',
            WeatherBackend.openMeteo => 'openMeteo',
            WeatherBackend.weatherApi => 'weatherApi',
          },
        );
        final String weatherSubtitle;
        if (weatherOverride == null) {
          weatherSubtitle = DashboardCopy.devtoolsSourceNoOverride(
            sheetContext,
            sourceLabel: sourceLabel,
          );
        } else if (weatherOverride is WeatherDebugOverrideCoarse) {
          final suffix = weatherOverride.isNightOverride == null
              ? ''
              : DashboardCopy.devtoolsNightSuffix(
                  sheetContext,
                  night: weatherOverride.isNightOverride!,
                );
          weatherSubtitle = DashboardCopy.devtoolsSourceForced(
            sheetContext,
            sourceLabel: sourceLabel,
            forcedLabel: _weatherLabel(sheetContext, weatherOverride.condition),
            suffix: suffix,
          );
        } else {
          final api = weatherOverride as WeatherDebugOverrideWeatherApi;
          final nightSuffix = api.isNight
              ? DashboardCopy.devtoolsNightSuffix(sheetContext, night: true)
              : '';
          weatherSubtitle = DashboardCopy.devtoolsSourceForced(
            sheetContext,
            sourceLabel: sourceLabel,
            forcedLabel: '${api.text} (#${api.code})',
            suffix: nightSuffix,
          );
        }
        final emergencyOverride = _liveData.debugEmergencySeverityOverride;
        final weatherSubtitleWithEmergency = emergencyOverride == null
            ? weatherSubtitle
            : '$weatherSubtitle\n${DashboardCopy.devtoolsWeatherEmergencyOverrideTitle(sheetContext)}: ${DashboardCopy.weatherEmergencyShortLabel(sheetContext, severity: emergencyOverride)}';

        final clockSubtitle = _clockOverrideSubtitle(
          sheetContext,
          _liveData.debugClockOffset,
        );

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
                child: Row(
                  children: [
                    const Icon(Icons.developer_mode),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DashboardCopy.devtoolsTitle(sheetContext),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    _sheetCloseButton(sheetContext),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  DashboardCopy.devtoolsSubtitle(sheetContext),
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              ),
              ListTile(
                key: const ValueKey('devtools_reset_restart'),
                leading: const Icon(Icons.restart_alt),
                title: Text(DashboardCopy.devtoolsResetRestartTitle(context)),
                subtitle: Text(
                  DashboardCopy.devtoolsResetRestartSubtitle(context),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _resetAndRestart();
                },
              ),
              ListTile(
                key: const ValueKey('devtools_weather_menu'),
                leading: const Icon(Icons.wb_sunny_outlined),
                title: Text(DashboardCopy.devtoolsWeatherTitle(context)),
                subtitle: Text(weatherSubtitleWithEmergency),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openWeatherOverrideSheet();
                },
              ),
              ListTile(
                key: const ValueKey('devtools_clock_menu'),
                leading: const Icon(Icons.schedule),
                title: Text(DashboardCopy.devtoolsClockTitle(context)),
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
    final confirmed = await showDestructiveConfirmationSheet(
      context,
      title: DashboardCopy.dashboardMenuResetDefaults(context),
      message: DashboardCopy.dashboardResetDefaultsMessage(context),
      confirmLabel: DashboardCopy.dashboardResetDefaultsConfirm(context),
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
      DashboardCopy.dashboardResetDefaultsSuccess(context),
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ToolPickerSheet(session: _session),
      ),
    );

    if (picked == null) return;
    if (!context.mounted) return;

    final (home, destination) = _resolveHomeDestination();

    if (picked.id == 'weather_summary') {
      await WeatherSummaryBottomSheet.show(
        context,
        liveData: _liveData,
        home: home,
        destination: destination,
      );
      return;
    }

    await ToolModalBottomSheet.show(
      context,
      tool: picked,
      session: _session,
      preferMetric: _preferMetricForReality(),
      prefer24h: _prefer24hForReality(),
      eurToUsd: _liveData.eurToUsd,
      currencyRateForPair: (fromCode, toCode) =>
          _liveData.currencyRate(fromCode: fromCode, toCode: toCode),
      currencyIsStale: _liveData.isCurrencyStale,
      currencyShouldRetryNow: _liveData.shouldRetryCurrencyNow,
      currencyLastErrorAt: _liveData.lastCurrencyErrorAt,
      currencyLastRefreshedAt: _liveData.lastCurrencyRefreshedAt,
      currencyNetworkEnabled: _liveData.currencyNetworkEnabled,
      onRetryCurrencyNow: () async {
        final places = <Place>[
          if (home != null) home,
          if (destination != null) destination,
        ];
        if (places.isEmpty) return;
        await _liveData.refreshAll(places: places);
      },
      home: home,
      destination: destination,
      canAddWidget: true,
      onAddWidget: () async {
        if (_dashboardHasToolId(picked.id)) {
          _focusExistingToolTile(picked.id);
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

  void _focusExistingToolTile(String toolId) {
    if (!mounted) return;
    setState(() {
      _focusToolTileId = toolId;
    });
  }

  Future<void> _openLanguageSettingsSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current = state.preferredLanguageCode;
        final options = <({String id, String label})>[
          (id: 'system', label: DashboardCopy.settingsLanguageSystem(context)),
          (id: 'en', label: DashboardCopy.settingsLanguageEnglish(context)),
          (id: 'es', label: DashboardCopy.settingsLanguageSpanish(context)),
          (id: 'fr', label: DashboardCopy.settingsLanguageFrench(context)),
          (
            id: 'pt-PT',
            label: DashboardCopy.settingsLanguagePortuguesePortugal(context),
          ),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: DashboardCopy.commonBackTooltip(context),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openSettingsSheet);
                        },
                      ),
                      Expanded(
                        child: Text(
                          DashboardCopy.settingsLanguageTitle(context),
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _sheetCloseButton(sheetContext),
                    ],
                  ),
                ),
                RadioGroup<String>(
                  // ignore: deprecated_member_use
                  groupValue: current,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.of(sheetContext).pop(value);
                  },
                  child: Column(
                    children: [
                      for (final option in options)
                        RadioListTile<String>(
                          key: ValueKey('settings_language_${option.id}'),
                          value: option.id,
                          title: Text(option.label),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await state.setPreferredLanguageCode(selected);
    if (!mounted) return;
    UnitanaToast.showSuccess(
      context,
      DashboardCopy.settingsLanguageUpdated(context),
    );
  }

  Future<void> _openThemeSettingsSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current = state.preferredThemeMode;
        final options = <({String id, String label})>[
          (id: 'system', label: DashboardCopy.settingsThemeSystem(context)),
          (id: 'dark', label: DashboardCopy.settingsThemeDark(context)),
          (id: 'light', label: DashboardCopy.settingsThemeLight(context)),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: DashboardCopy.commonBackTooltip(context),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openSettingsSheet);
                        },
                      ),
                      Expanded(
                        child: Text(
                          DashboardCopy.settingsThemeTitle(context),
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _sheetCloseButton(sheetContext),
                    ],
                  ),
                ),
                RadioGroup<String>(
                  // ignore: deprecated_member_use
                  groupValue: current,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.of(sheetContext).pop(value);
                  },
                  child: Column(
                    children: [
                      for (final option in options)
                        RadioListTile<String>(
                          key: ValueKey('settings_theme_${option.id}'),
                          value: option.id,
                          title: Text(option.label),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await state.setPreferredThemeMode(selected);
    if (!mounted) return;
    UnitanaToast.showSuccess(
      context,
      DashboardCopy.settingsThemeUpdated(context),
    );
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final maxH = MediaQuery.of(sheetContext).size.height * 0.92;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Column(
                    key: const ValueKey('settings_sheet'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DashboardCopy.dashboardMenuTitle(context),
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _sheetCloseButton(sheetContext),
                          ],
                        ),
                      ),
                      const _MenuSectionLabel('Dashboard'),
                      ListTile(
                        key: const ValueKey('dashboard_menu_profiles'),
                        leading: const Icon(Icons.switch_account),
                        title: Text(
                          DashboardCopy.dashboardMenuProfiles(context),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openProfilesBoard);
                        },
                      ),
                      if (!_isEditingWidgets)
                        ListTile(
                          key: const Key('dashboard_edit_mode'),
                          leading: const Icon(Icons.edit),
                          title: Text(
                            DashboardCopy.dashboardMenuEditWidgets(context),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            Future.microtask(_enterEditWidgets);
                          },
                        ),
                      ListTile(
                        key: const ValueKey('dashboard_menu_reset_defaults'),
                        leading: const Icon(Icons.restore),
                        title: Text(
                          DashboardCopy.dashboardMenuResetDefaults(context),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_resetDashboardDefaults);
                        },
                      ),
                      if (_kDeveloperToolsEnabled)
                        ListTile(
                          key: const ValueKey('dashboard_menu_developer_tools'),
                          leading: const Icon(Icons.developer_mode),
                          title: Text(
                            DashboardCopy.dashboardMenuDeveloperTools(context),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            Future.microtask(_openDeveloperToolsSheet);
                          },
                        ),
                      const Divider(height: 18),
                      _MenuSectionLabel(
                        DashboardCopy.dashboardMenuSettings(context),
                        key: const ValueKey('dashboard_menu_settings'),
                        onTap: () {},
                      ),
                      ListTile(
                        key: const ValueKey('settings_option_theme'),
                        leading: const Icon(Icons.palette_outlined),
                        title: Text(DashboardCopy.settingsThemeTitle(context)),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openThemeSettingsSheet);
                        },
                      ),
                      ListTile(
                        key: const ValueKey('settings_option_language'),
                        leading: const Icon(Icons.language_rounded),
                        title: Text(
                          DashboardCopy.settingsLanguageTitle(context),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openLanguageSettingsSheet);
                        },
                      ),
                      SwitchListTile(
                        key: const ValueKey('settings_option_lofi_audio'),
                        secondary: const Icon(Icons.music_note_rounded),
                        value: state.lofiAudioEnabled,
                        title: Text(
                          DashboardCopy.settingsLofiAudioTitle(context),
                        ),
                        subtitle: Text(
                          '${state.lofiAudioEnabled ? DashboardCopy.settingsLofiAudioOn(context) : DashboardCopy.settingsLofiAudioOff(context)} · ${DashboardCopy.settingsLofiAudioVolume(context, percent: (state.lofiAudioVolume * 100).round())}',
                        ),
                        onChanged: (enabled) async {
                          final updatedMessage =
                              DashboardCopy.settingsLofiAudioUpdated(context);
                          await state.setLofiAudioEnabled(enabled);
                          setSheetState(() {});
                          if (!sheetContext.mounted) return;
                          UnitanaToast.showSuccess(
                            sheetContext,
                            updatedMessage,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                key: const ValueKey(
                                  'settings_lofi_volume_slider',
                                ),
                                value: state.lofiAudioVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: DashboardCopy.settingsLofiAudioVolume(
                                  context,
                                  percent: (state.lofiAudioVolume * 100)
                                      .round(),
                                ),
                                onChanged: state.lofiAudioEnabled
                                    ? (value) async {
                                        await state.setLofiAudioVolume(value);
                                        setSheetState(() {});
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        key: const ValueKey('settings_option_reset_tutorials'),
                        leading: const Icon(Icons.school_rounded),
                        title: const Text('Reset tutorials'),
                        subtitle: const Text(
                          'Show tips again across wizard, dashboard, and profiles.',
                        ),
                        onTap: () async {
                          await state.resetTutorialSurfaces();
                          if (!sheetContext.mounted) return;
                          UnitanaToast.showSuccess(
                            sheetContext,
                            'Tutorials reset.',
                          );
                          if (!mounted) return;
                          setState(() => _showDashboardTutorial = true);
                        },
                      ),
                      ListTile(
                        key: const ValueKey('settings_option_about'),
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(DashboardCopy.settingsOptionAbout(context)),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openAboutSheet);
                        },
                      ),
                      ListTile(
                        key: const ValueKey('settings_option_licenses'),
                        leading: const Icon(Icons.gavel_rounded),
                        title: Text(
                          DashboardCopy.settingsOptionLicenses(context),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openLicensesPage);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAboutSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final versionLine = 'Version $_kBuildVersion ($_kBuildNumber)';
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              key: const ValueKey('settings_about_sheet'),
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: DashboardCopy.commonBackTooltip(context),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Future.microtask(_openSettingsSheet);
                        },
                      ),
                      Expanded(
                        child: Text(
                          DashboardCopy.settingsAboutTitle(context),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _sheetCloseButton(sheetContext),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(64),
                      ),
                      child: Image.asset(
                        'assets/brand/unitana_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      DashboardCopy.settingsAboutLegalese(context),
                      key: const ValueKey('settings_about_legalese'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      DashboardCopy.settingsAboutTagline(context),
                      key: const ValueKey('settings_about_tagline'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Build channel: $_kBuildChannel',
                      key: const ValueKey('settings_about_body'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(48),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data providers',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Weather: Open-Meteo (primary runtime), WeatherAPI (development diagnostics)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Currency: Frankfurter (primary), open.er-api.com (fallback)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      versionLine,
                      key: const ValueKey('settings_about_version'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLicensesPage() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsLicensesPage(
          key: const ValueKey('settings_licenses_page'),
          applicationName: 'Unitana',
          applicationLegalese: DashboardCopy.settingsAboutLegalese(context),
        ),
        settings: const RouteSettings(name: 'settings_licenses_route'),
      ),
    );
  }

  Future<void> _openEditProfileWizard({
    bool reopenSwitcherOnCancel = false,
    String? discardProfileIdOnCancel,
    String? returnToProfileIdOnCancel,
    String? successToast,
  }) async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<FirstRunExitAction>(
      MaterialPageRoute(
        builder: (_) => FirstRunScreen(
          state: widget.state,
          editMode: true,
          allowCancel: true,
        ),
      ),
    );

    if (result == FirstRunExitAction.saved) {
      if (successToast != null && successToast.trim().isNotEmpty && mounted) {
        UnitanaToast.showSuccess(context, successToast);
      }
      return;
    }

    if (result != FirstRunExitAction.cancelled) return;
    if (!mounted) return;

    if (discardProfileIdOnCancel != null &&
        discardProfileIdOnCancel.trim().isNotEmpty) {
      await state.deleteProfile(discardProfileIdOnCancel);
      if (!mounted) return;
      final fallback = returnToProfileIdOnCancel;
      if (fallback != null && fallback.trim().isNotEmpty) {
        await _switchActiveProfileAndReload(fallback);
      }
      if (!mounted) return;
    }

    if (reopenSwitcherOnCancel) {
      await _openProfilesBoard();
    }
  }

  Future<void> _editProfileFromBoard(String profileId) async {
    if (!mounted) return;
    final successToast = DashboardCopy.dashboardProfileUpdated(context);
    final prevActive = state.activeProfileId;
    final target = profileId.trim();
    if (target.isEmpty) return;
    final switched = target != prevActive;

    if (switched) {
      await _switchActiveProfileAndReload(target);
      if (!mounted) return;
    }

    await _openEditProfileWizard(
      reopenSwitcherOnCancel: false,
      successToast: successToast,
    );
    if (!mounted) return;

    if (switched) {
      await _switchActiveProfileAndReload(prevActive);
    }
  }

  Future<void> _openProfilesBoard() async {
    if (!mounted) return;
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    final showProfilesTutorial =
        !isFlutterTest &&
        (!state.tutorialDismissed || state.tutorialReplayRequested) &&
        !state.hasCompletedTutorialSurface('profiles');

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfilesBoardScreen(
          state: state,
          onSwitchProfile: (profileId) async {
            await _switchActiveProfileAndReload(profileId);
          },
          onEditProfile: _editProfileFromBoard,
          onAddProfile: ({int? slotIndex}) async {
            await _createAndOpenNewProfileWizard(
              reopenOnCancel: false,
              slotIndex: slotIndex,
            );
          },
          onDeleteProfile: (profileId) async {
            final before = state.activeProfileId;
            await state.deleteProfile(profileId);
            if (!mounted) return;
            final after = state.activeProfileId;
            if (before != after) {
              await _switchActiveProfileAndReload(after);
              return;
            }
            await _refreshAllNow();
          },
          showTutorial: showProfilesTutorial,
          onCompleteTutorial: () =>
              state.markTutorialSurfaceCompleted('profiles'),
        ),
      ),
    );
  }

  void _openToolPickerFromMenu() {
    if (!mounted) return;
    _openToolPickerAndRun(context);
  }

  void _enterEditWidgets({String? focusTileId}) {
    if (_isEditingWidgets) return;
    _layout.beginEdit();
    final shouldShowEditTutorial = !state.hasCompletedTutorialSurface(
      'dashboard_edit',
    );
    setState(() {
      _isEditingWidgets = true;
      _focusTileId = focusTileId;
      _showDashboardEditTutorial = shouldShowEditTutorial;
    });
  }

  String _nextProfileId() {
    final existing = state.profiles.map((p) => p.id).toSet();
    var n = 1;
    while (existing.contains('profile_$n')) {
      n += 1;
    }
    return 'profile_$n';
  }

  String _nextProfileDisplayName() {
    var highest = 0;
    final pattern = RegExp(r'^Profile\s*#\s*(\d+)$', caseSensitive: false);
    for (final profile in state.profiles) {
      final match = pattern.firstMatch(profile.name.trim());
      if (match == null) continue;
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > highest) {
        highest = parsed;
      }
    }
    final next = highest + 1;
    return 'Profile #$next';
  }

  Future<void> _createAndOpenNewProfileWizard({
    bool reopenOnCancel = true,
    int? slotIndex,
  }) async {
    final previousProfileId = state.activeProfileId;
    final profile = UnitanaProfile(
      id: _nextProfileId(),
      name: _nextProfileDisplayName(),
      places: const <Place>[],
      defaultPlaceId: null,
    );

    await state.createProfile(profile, insertIndex: slotIndex);
    if (!mounted) return;
    await _openEditProfileWizard(
      reopenSwitcherOnCancel: reopenOnCancel,
      discardProfileIdOnCancel: profile.id,
      returnToProfileIdOnCancel: previousProfileId,
      successToast: DashboardCopy.dashboardProfileCreated(context),
    );
    if (!mounted) return;

    // Rebind profile-scoped controllers after wizard save/cancel flow settles.
    _session.dispose();
    _layout.dispose();
    _bindProfileScopedControllers();
    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
    await _refreshAllNow();
  }

  Widget _sheetCloseButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close_rounded),
      tooltip: DashboardCopy.dashboardClosePanelTooltip(context),
      onPressed: () => Navigator.of(context).maybePop(),
    );
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
    UnitanaToast.showSuccess(context, DashboardCopy.dashboardUpdated(context));
  }

  void _maybeAutoRefreshWeather(List<Place> places) {
    final weatherLive =
        _liveData.weatherNetworkEnabled &&
        _liveData.weatherBackend != WeatherBackend.mock;
    final currencyLive = _liveData.currencyNetworkEnabled;
    if (!weatherLive && !currencyLive) return;
    if (_liveData.isRefreshing) return;

    final last = _liveData.lastRefreshedAt;
    final now = DateTime.now();
    final weatherStale =
        weatherLive &&
        (last == null || now.difference(last) > _kWeatherAutoRefreshStaleAfter);
    final currencyStale = currencyLive && _liveData.isCurrencyStale;
    final isStale = weatherStale || currencyStale;
    if (!isStale) return;

    final prev = _lastAutoWeatherRefreshAttemptAt;
    if (prev != null &&
        now.difference(prev) < _kWeatherAutoRefreshMinInterval) {
      return;
    }
    _lastAutoWeatherRefreshAttemptAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _liveData.refreshAll(places: places);
    });
  }

  Future<void> _refreshAllNow() async {
    if (!mounted) return;
    final places = state.places;
    await _liveData.refreshAll(places: places);
  }

  /// Pick the current Home place from the app state.
  ///
  /// Contract: the wizard stores places in [home, destination] order.
  /// If that ever changes, update this helper (and its companion below)
  /// in one place so hero + mini hero stay consistent.
  Place? _pickHome(List<Place> places) {
    if (places.isEmpty) return null;
    return places.first;
  }

  /// Pick the current Destination place from the app state.
  ///
  /// Returns null when the user has not configured a second place yet,
  /// which intentionally hides the pinned mini hero readout.
  Place? _pickDestination(List<Place> places) {
    if (places.length < 2) return null;
    return places[1];
  }

  @override
  Widget build(BuildContext context) {
    final profileName = state.profileName.trim().isEmpty
        ? DashboardCopy.dashboardProfileNameFallback(context)
        : state.profileName.trim();
    final titleFontSize = _resolveAppBarTitleFontSize(context, profileName);

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
              child: KeyedSubtree(
                key: _tutorialToolsButtonKey,
                child: _HeaderIconButton(
                  key: const Key('dashboard_tools_button'),
                  tooltip: DashboardCopy.dashboardOpenToolsTooltip(context),
                  icon: Icons.handyman_rounded,
                  onTap: _openToolPickerFromMenu,
                ),
              ),
            ),
            title: Text(
              profileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
              style: _baseAppBarTitleStyle(
                context,
              ).copyWith(fontSize: titleFontSize),
            ),
            actions: [
              if (_isEditingWidgets) ...[
                TextButton(
                  key: const Key('dashboard_edit_cancel'),
                  onPressed: _exitEditWidgetsCancel,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    DashboardCopy.dashboardEditCancel(context),
                    style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: KeyedSubtree(
                    key: _tutorialEditDoneKey,
                    child: TextButton(
                      key: const Key('dashboard_edit_done'),
                      onPressed: _exitEditWidgetsDone,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(
                        DashboardCopy.dashboardEditDone(context),
                        style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                      ),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: KeyedSubtree(
                    key: _tutorialMenuButtonKey,
                    child: _HeaderIconButton(
                      key: const Key('dashboard_menu_button'),
                      tooltip: DashboardCopy.dashboardOpenMenuTooltip(context),
                      icon: Icons.menu_rounded,
                      onTap: _openSettingsSheet,
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final padding = width >= 600
                      ? const EdgeInsets.all(24)
                      : const EdgeInsets.all(16);

                  final availableWidth = width - padding.horizontal;

                  // Grid geometry (kept in sync with DashboardBoard)
                  const gridGap = 12.0;
                  const tileHeightRatio = 0.78;
                  final cols = availableWidth >= 520 ? 3 : 2;
                  final tileW = (availableWidth - (cols - 1) * gridGap) / cols;
                  final tileH = tileW * tileHeightRatio;
                  final heroHeight = (2 * tileH) + gridGap;
                  // Collapsing pinned header: PlacesHeroV2 -> mini hero.
                  //
                  // NOTE: With a sliver persistent header, this becomes scroll-continuous.
                  // There is no overlay insertion and no spacer threshold that can "pop".
                  const pinnedHeight = 176.0;

                  final home = _pickHome(state.places);
                  final destination = _pickDestination(state.places);

                  // Seed deterministic demo/live data so the header does not show a
                  // one-frame placeholder during fast scroll.
                  _liveData.ensureSeeded([
                    if (home != null) home,
                    if (destination != null) destination,
                  ]);

                  return RefreshIndicator(
                    key: const ValueKey('dashboard_pull_to_refresh'),
                    onRefresh: _refreshAllNow,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: padding.left,
                            right: padding.right,
                            top: 0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  // Keep center cluster off the edge controls while
                                  // preserving true center alignment with the title.
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 72,
                                  ),
                                  child: Transform.translate(
                                    offset: const Offset(
                                      _kRefreshClusterVisualNudgeX,
                                      0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: KeyedSubtree(
                                        key: _tutorialRefreshKey,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              DataRefreshStatusLabel(
                                                key: const ValueKey(
                                                  'dashboard_refresh_status_label',
                                                ),
                                                liveData: _liveData,
                                                compact: true,
                                                showBackground: false,
                                                hideWhenUnavailable: false,
                                              ),
                                              const SizedBox(width: 0),
                                              IconButton(
                                                tooltip:
                                                    DashboardCopy.dashboardRefreshDataTooltip(
                                                      context,
                                                    ),
                                                onPressed: _refreshAllNow,
                                                icon: const Icon(
                                                  Icons.refresh_rounded,
                                                  size: 16,
                                                ),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withAlpha(220),
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 24,
                                                      minHeight: 24,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding.left,
                          ),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: PlacesHeroCollapsingHeaderDelegate(
                              expandedHeight: heroHeight,
                              collapsedHeight: pinnedHeight,
                              horizontalPadding: padding.left,
                              home: home,
                              destination: destination,
                              session: _session,
                              liveData: _liveData,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: padding.left,
                            right: padding.right,
                            bottom: padding.bottom,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: KeyedSubtree(
                              key: _tutorialWidgetsKey,
                              child: DashboardBoard(
                                state: state,
                                session: _session,
                                liveData: _liveData,
                                layout: _layout,
                                availableWidth: availableWidth,
                                isEditing: _isEditingWidgets,
                                includePlacesHero: false,
                                focusActionTileId: _focusTileId,
                                focusToolTileId: _focusToolTileId,
                                onEnteredEditMode: (focusId) =>
                                    _enterEditWidgets(focusTileId: focusId),
                                onConsumedFocusTileId: () =>
                                    setState(() => _focusTileId = null),
                                onConsumedFocusToolTileId: () =>
                                    setState(() => _focusToolTileId = null),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_showDashboardTutorial && !_isEditingWidgets)
                TutorialOverlay(
                  steps: [
                    TutorialStep(
                      title: 'Tools',
                      body:
                          'This is your tool belt. Tap the hammer + wrench to open tools, then pin your go-to picks.',
                      targetKey: null,
                      cardAlignment: const Alignment(-1, -0.84),
                      targetAlignment: const Alignment(0, -1),
                      showSpotlight: false,
                      arrowAboveCard: true,
                      arrowScale: 1.28,
                      fallbackScreenTargetAlignment: const Alignment(
                        -0.96,
                        -0.98,
                      ),
                    ),
                    TutorialStep(
                      title: 'Menu',
                      body:
                          'This is your control room: switch profiles, tune your theme, and adjust settings.',
                      targetKey: null,
                      cardAlignment: const Alignment(1, -0.84),
                      targetAlignment: const Alignment(0, -1),
                      showSpotlight: false,
                      arrowAboveCard: true,
                      arrowScale: 1.28,
                      fallbackScreenTargetAlignment: const Alignment(
                        0.96,
                        -0.98,
                      ),
                    ),
                    TutorialStep(
                      title: 'Refresh',
                      body:
                          'Need fresh data fast? Pull down on the page to refresh weather and currency. Tap the icon for a quick refresh too.',
                      targetKey: _tutorialRefreshKey,
                      cardAlignment: const Alignment(0, -0.86),
                      arrowStyle: TutorialArrowStyle.pullDownBounce,
                      showSpotlight: false,
                      arrowScale: 1.72,
                    ),
                    TutorialStep(
                      title: 'Widgets',
                      body:
                          'These are tool widgets. Each one shows your last result so key info is always one tap away.',
                      targetKey: _tutorialWidgetsKey,
                      cardAlignment: const Alignment(0, -0.84),
                      targetAlignment: const Alignment(0, -1.45),
                      arrowScale: 1.36,
                    ),
                  ],
                  onSkip: _completeDashboardTutorial,
                  onComplete: _completeDashboardTutorial,
                ),
              if (_showDashboardEditTutorial && _isEditingWidgets)
                TutorialOverlay(
                  steps: [
                    TutorialStep(
                      title: 'Move Widgets',
                      body:
                          'Long-press a tool widget, then drag it. Drop on a widget to swap, or drop on an empty slot to place it there.',
                      targetKey: _tutorialWidgetsKey,
                      cardAlignment: const Alignment(0, -0.84),
                      targetAlignment: const Alignment(0, -1.45),
                      arrowScale: 1.36,
                    ),
                    TutorialStep(
                      title: 'Save Layout',
                      body:
                          'Tap Done to keep your layout. Tap Cancel to exit without saving.',
                      targetKey: null,
                      cardAlignment: const Alignment(1, -0.84),
                      targetAlignment: const Alignment(0, -1),
                      showSpotlight: false,
                      arrowAboveCard: true,
                      arrowScale: 1.25,
                      fallbackScreenTargetAlignment: const Alignment(
                        0.96,
                        -0.98,
                      ),
                    ),
                  ],
                  onSkip: _completeDashboardEditTutorial,
                  onComplete: _completeDashboardEditTutorial,
                ),
            ],
          ),
        );
      },
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

class _MenuSectionLabel extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _MenuSectionLabel(this.text, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(220),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
