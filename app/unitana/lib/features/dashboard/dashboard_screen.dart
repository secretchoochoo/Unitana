import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app_state.dart';
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
import 'models/tool_definitions.dart';
import 'widgets/dashboard_board.dart';
import 'widgets/data_refresh_status_label.dart';
import 'widgets/places_hero_collapsing_header.dart';
import 'widgets/profiles_board_screen.dart';
import 'widgets/tool_modal_bottom_sheet.dart';
import 'widgets/destructive_confirmation_sheet.dart';
import 'widgets/weather_summary_bottom_sheet.dart';
import '../../theme/dracula_palette.dart';

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
  static const double _kMenuSheetHeightFactor = 0.85;
  static const double _kEditAppBarActionFontSize = 14;
  static const double _kAppBarTitleMaxFontSize = 28;
  static const double _kAppBarTitleMinFontSize = 18;
  static const double _kRefreshClusterVisualNudgeX = 10;

  late DashboardSessionController _session;
  late final DashboardLiveDataController _liveData;
  late DashboardLayoutController _layout;

  late final ScrollController _scrollController;

  DateTime? _lastAutoWeatherRefreshAttemptAt;

  bool _isEditingWidgets = false;
  String? _focusTileId;
  String? _focusToolTileId;

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
    _liveData = DashboardLiveDataController();
    _liveData.loadDevSettings();
    _bindProfileScopedControllers();

    _scrollController = ScrollController();

    // Kick off an initial refresh so the hero is never stuck showing placeholders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllNow();
      final pendingSuccess = state.consumePendingSuccessToast();
      if (!mounted || pendingSuccess == null) return;
      UnitanaToast.showSuccess(context, pendingSuccess);
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
                subtitle: Text(weatherSubtitle),
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
      showDragHandle: true,
      builder: (sheetContext) {
        UnitanaProfile? suggestedProfile;
        final suggestedId = state.autoSuggestedProfileId;
        if (suggestedId != null) {
          for (final profile in state.profiles) {
            if (profile.id == suggestedId) {
              suggestedProfile = profile;
              break;
            }
          }
        }
        final fallbackSuggestion = suggestedProfile == null
            ? DashboardCopy.settingsProfileSuggestReasonUnavailable(context)
            : DashboardCopy.settingsProfileSuggestSuggested(
                context,
                profileName: suggestedProfile.name,
              );
        final explainability =
            state.autoProfileSuggestionReason?.trim().isNotEmpty == true
            ? state.autoProfileSuggestionReason!.trim()
            : fallbackSuggestion;
        return SafeArea(
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
                          DashboardCopy.settingsTitle(context),
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _sheetCloseButton(sheetContext),
                    ],
                  ),
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
                  title: Text(DashboardCopy.settingsLanguageTitle(context)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future.microtask(_openLanguageSettingsSheet);
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('settings_option_profile_suggest'),
                  secondary: const Icon(Icons.my_location_rounded),
                  value: state.autoProfileSuggestEnabled,
                  title: Text(
                    DashboardCopy.settingsProfileSuggestTitle(context),
                  ),
                  subtitle: Text(
                    '${state.autoProfileSuggestEnabled ? DashboardCopy.settingsProfileSuggestEnabled(context) : DashboardCopy.settingsProfileSuggestDisabled(context)} · $explainability',
                  ),
                  onChanged: (enabled) async {
                    await state.setAutoProfileSuggestEnabled(enabled);
                    await state.evaluateAutoProfileSuggestion(signal: null);
                    if (!mounted) return;
                    UnitanaToast.showSuccess(
                      context,
                      DashboardCopy.settingsProfileSuggestUpdated(context),
                    );
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
                  title: Text(DashboardCopy.settingsOptionLicenses(context)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future.microtask(_openLicensesPage);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
        return SafeArea(
          child: Padding(
            key: const ValueKey('settings_about_sheet'),
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                const SizedBox(height: 6),
                Text(
                  DashboardCopy.settingsAboutTagline(context),
                  key: const ValueKey('settings_about_tagline'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardCopy.settingsAboutBody(context),
                  key: const ValueKey('settings_about_body'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardCopy.settingsAboutLegalese(context),
                  key: const ValueKey('settings_about_legalese'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
        builder: (_) => LicensePage(
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

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfilesBoardScreen(
          state: state,
          onSwitchProfile: (profileId) async {
            await _switchActiveProfileAndReload(profileId);
          },
          onEditProfile: _editProfileFromBoard,
          onAddProfile: () async {
            await _createAndOpenNewProfileWizard(reopenOnCancel: false);
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
    setState(() {
      _isEditingWidgets = true;
      _focusTileId = focusTileId;
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

  Future<void> _createAndOpenNewProfileWizard({
    bool reopenOnCancel = true,
  }) async {
    final previousProfileId = state.activeProfileId;
    final profile = UnitanaProfile(
      id: _nextProfileId(),
      name: DashboardCopy.profilesDefaultName(context),
      places: const <Place>[],
      defaultPlaceId: null,
    );

    await state.createProfile(profile);
    if (!mounted) return;
    await _switchActiveProfileAndReload(profile.id);
    if (!mounted) return;
    await _openEditProfileWizard(
      reopenSwitcherOnCancel: reopenOnCancel,
      discardProfileIdOnCancel: profile.id,
      returnToProfileIdOnCancel: previousProfileId,
      successToast: DashboardCopy.dashboardProfileCreated(context),
    );
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
              child: _HeaderIconButton(
                key: const Key('dashboard_tools_button'),
                tooltip: DashboardCopy.dashboardOpenToolsTooltip(context),
                icon: Icons.handyman_rounded,
                onTap: _openToolPickerFromMenu,
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
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _HeaderIconButton(
                    key: const Key('dashboard_menu_button'),
                    tooltip: DashboardCopy.dashboardOpenMenuTooltip(context),
                    icon: Icons.menu_rounded,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (sheetContext) {
                          // Bottom sheets are particularly prone to small-phone
                          // overflows when built as a natural-height Column.
                          // Use a scrollable list so the sheet can adapt to
                          // tight viewports without RenderFlex overflow.
                          final maxH =
                              MediaQuery.of(sheetContext).size.height *
                              _kMenuSheetHeightFactor;
                          return SafeArea(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxH),
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(bottom: 8),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      2,
                                      6,
                                      2,
                                    ),
                                    child: Row(
                                      children: [
                                        const Spacer(),
                                        _sheetCloseButton(sheetContext),
                                      ],
                                    ),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.switch_account),
                                    title: Text(
                                      DashboardCopy.dashboardMenuProfiles(
                                        context,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      Future.microtask(_openProfilesBoard);
                                    },
                                  ),
                                  ListTile(
                                    key: const ValueKey(
                                      'dashboard_menu_settings',
                                    ),
                                    leading: const Icon(Icons.settings),
                                    title: Text(
                                      DashboardCopy.dashboardMenuSettings(
                                        context,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      Future.microtask(_openSettingsSheet);
                                    },
                                  ),
                                  if (!_isEditingWidgets)
                                    ListTile(
                                      key: const Key('dashboard_edit_mode'),
                                      leading: const Icon(Icons.edit),
                                      title: Text(
                                        DashboardCopy.dashboardMenuEditWidgets(
                                          context,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        Future.microtask(_enterEditWidgets);
                                      },
                                    ),
                                  ListTile(
                                    key: const ValueKey(
                                      'dashboard_menu_reset_defaults',
                                    ),
                                    leading: const Icon(Icons.restore),
                                    title: Text(
                                      DashboardCopy.dashboardMenuResetDefaults(
                                        context,
                                      ),
                                    ),
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
                                    title: Text(
                                      DashboardCopy.dashboardMenuDeveloperTools(
                                        context,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      Future.microtask(
                                        _openDeveloperToolsSheet,
                                      );
                                    },
                                  ),
                                ],
                              ),
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

              return CustomScrollView(
                controller: _scrollController,
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
                            padding: const EdgeInsets.symmetric(horizontal: 72),
                            child: Transform.translate(
                              offset: const Offset(
                                _kRefreshClusterVisualNudgeX,
                                0,
                              ),
                              child: Align(
                                alignment: Alignment.center,
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
                                        color: DraculaPalette.purple.withAlpha(
                                          220,
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
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
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left),
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
                ],
              );
            },
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
