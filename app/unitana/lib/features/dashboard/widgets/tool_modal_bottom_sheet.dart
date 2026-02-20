import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/unitana_notice_card.dart';
import '../../../common/debug/picker_perf_trace.dart';
import '../../../data/cities.dart' show kCurrencySymbols;
import '../../../data/city_picker_engine.dart';
import '../../../data/city_label_utils.dart';
import '../../../data/city_repository.dart';
import '../../../data/country_currency_map.dart';
import '../../../theme/dracula_palette.dart';
import '../../../models/place.dart';
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_copy.dart';
import '../models/dashboard_exceptions.dart';
import '../models/flight_time_estimator.dart';
import '../models/freshness_copy.dart';
import '../models/jet_lag_planner.dart';
import '../models/lens_accents.dart';
import '../models/numeric_input_policy.dart';
import '../models/place_geo_lookup.dart';
import '../models/time_zone_catalog.dart';
import '../models/tool_definitions.dart';
import '../models/canonical_tools.dart';

import 'destructive_confirmation_sheet.dart';
import 'pulse_swap_icon.dart';

/// Bottom sheet calculator for tool tiles.
///
/// Layout contract:
/// - Top: calculator input + result
/// - Bottom: last 10 executions (most recent first)
class ToolModalBottomSheet extends StatefulWidget {
  final ToolDefinition tool;
  final DashboardSessionController session;

  /// True if the active reality prefers metric as its dominant unit system.
  /// This sets the default conversion direction so the input matches the
  /// currently-dominant system.
  final bool preferMetric;

  /// True if the active reality prefers a 24-hour time display.
  ///
  /// This must be derived from the active Place (home/destination) and is
  /// intentionally separate from unitSystem (metric/imperial).
  final bool prefer24h;

  /// Optional live exchange rate used by Currency (EUR -> USD).
  ///
  /// This is passed from the dashboard so we can keep the tool surface
  /// frontend-complete while Weather and full FX wiring remain deferred.
  final double? eurToUsd;
  final double? Function(String fromCode, String toCode)? currencyRateForPair;
  final bool currencyIsStale;
  final bool currencyShouldRetryNow;
  final DateTime? currencyLastErrorAt;
  final DateTime? currencyLastRefreshedAt;
  final bool currencyNetworkEnabled;
  final Duration currencyRefreshCadence;
  final Future<void> Function()? onRetryCurrencyNow;

  /// Optional context for inferring Currency direction.
  ///
  /// If provided, Currency defaults to home -> destination when the active
  /// reality is home, and destination -> home when the active reality is
  /// destination.
  final Place? home;
  final Place? destination;
  final bool canAddWidget;
  final Future<void> Function()? onAddWidget;

  const ToolModalBottomSheet({
    super.key,
    required this.tool,
    required this.session,
    required this.preferMetric,
    this.prefer24h = false,
    this.eurToUsd,
    this.currencyRateForPair,
    this.currencyIsStale = false,
    this.currencyShouldRetryNow = false,
    this.currencyLastErrorAt,
    this.currencyLastRefreshedAt,
    this.currencyNetworkEnabled = true,
    this.currencyRefreshCadence = const Duration(hours: 12),
    this.onRetryCurrencyNow,
    this.home,
    this.destination,
    this.canAddWidget = false,
    this.onAddWidget,
  });

  static Future<void> show(
    BuildContext context, {
    required ToolDefinition tool,
    required DashboardSessionController session,
    required bool preferMetric,
    bool prefer24h = false,
    double? eurToUsd,
    double? Function(String fromCode, String toCode)? currencyRateForPair,
    bool currencyIsStale = false,
    bool currencyShouldRetryNow = false,
    DateTime? currencyLastErrorAt,
    DateTime? currencyLastRefreshedAt,
    bool currencyNetworkEnabled = true,
    Duration currencyRefreshCadence = const Duration(hours: 12),
    Future<void> Function()? onRetryCurrencyNow,
    Place? home,
    Place? destination,
    bool canAddWidget = false,
    Future<void> Function()? onAddWidget,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ToolModalBottomSheet(
        tool: tool,
        session: session,
        preferMetric: preferMetric,
        prefer24h: prefer24h,
        eurToUsd: eurToUsd,
        currencyRateForPair: currencyRateForPair,
        currencyIsStale: currencyIsStale,
        currencyShouldRetryNow: currencyShouldRetryNow,
        currencyLastErrorAt: currencyLastErrorAt,
        currencyLastRefreshedAt: currencyLastRefreshedAt,
        currencyNetworkEnabled: currencyNetworkEnabled,
        currencyRefreshCadence: currencyRefreshCadence,
        onRetryCurrencyNow: onRetryCurrencyNow,
        home: home,
        destination: destination,
        canAddWidget: canAddWidget,
        onAddWidget: onAddWidget,
      ),
    );
  }

  @override
  State<ToolModalBottomSheet> createState() => _ToolModalBottomSheetState();
}

/// Shared color policy for tool sheets across dark/light themes.
///
/// Principle:
/// - Dark mode keeps Dracula semantics.
/// - Light mode prioritizes readability first (near-black text on light cards),
///   and uses accents sparingly for emphasis only.
class _ToolModalThemePolicy {
  const _ToolModalThemePolicy._();

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withAlpha(238);

  static Color textMuted(BuildContext context, {int alpha = 225}) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(alpha);

  static Color panelBg(BuildContext context) => isLight(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(235)
      : DraculaPalette.currentLine;

  static Color panelBgSoft(BuildContext context) => isLight(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(210)
      : DraculaPalette.currentLine.withAlpha(180);

  static Color panelBorder(BuildContext context, {int alpha = 170}) =>
      isLight(context)
      ? Theme.of(context).colorScheme.outline.withAlpha(205)
      : DraculaPalette.comment.withAlpha(alpha);

  static Color headingTone(BuildContext context) => isLight(context)
      ? Theme.of(context).colorScheme.primary.withAlpha(225)
      : DraculaPalette.purple;

  static Color successTone(BuildContext context) =>
      isLight(context) ? const Color(0xFF2E7D32) : DraculaPalette.green;

  static Color warningTone(BuildContext context) =>
      isLight(context) ? const Color(0xFF8A3D12) : DraculaPalette.orange;

  static Color infoTone(BuildContext context) => isLight(context)
      ? Theme.of(context).colorScheme.primary.withAlpha(225)
      : DraculaPalette.cyan;

  static Color dangerTone(BuildContext context) =>
      isLight(context) ? const Color(0xFFB00020) : DraculaPalette.pink;
}

class _TerminalLine extends StatelessWidget {
  final String prompt;
  final String input;
  final String output;
  final bool emphasize;
  final Color arrowColor;

  const _TerminalLine({
    required this.prompt,
    required this.input,
    required this.output,
    required this.emphasize,
    required this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = _ToolModalThemePolicy.textPrimary(context);
    final promptTone = _ToolModalThemePolicy.successTone(context);
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: primaryText,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
    );

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(
            text: prompt,
            style: base?.copyWith(
              color: promptTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' $input '),
          TextSpan(
            text: '→',
            style: base?.copyWith(
              color: arrowColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' $output'),
        ],
      ),
    );
  }
}

class _LookupEntry {
  final String keyId;
  final String label;
  final Map<String, String> valuesBySystem;
  final String? note;
  final bool approximate;

  const _LookupEntry({
    required this.keyId,
    required this.label,
    required this.valuesBySystem,
    this.note,
    this.approximate = false,
  });
}

typedef _TimeZonePickerSelection = ({String zoneId, String displayLabel});

enum _PaceMode { running, rowing }

class _ToolModalBottomSheetState extends State<ToolModalBottomSheet> {
  // MVP: Currency tool supports EUR ↔ USD, using a live/demo EUR→USD rate.
  // We infer a default direction from home vs destination when context is
  // provided by the dashboard.
  //
  // NOTE: This is intentionally small-scope and does not attempt a full
  // multi-currency system.

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _timeConvertController = TextEditingController();
  final TextEditingController _unitPriceAController = TextEditingController();
  final TextEditingController _unitQtyAController = TextEditingController();
  final TextEditingController _unitPriceBController = TextEditingController();
  final TextEditingController _unitQtyBController = TextEditingController();
  final TextEditingController _hydrationExerciseController =
      TextEditingController();
  final TextEditingController _paceGoalTimeController = TextEditingController(
    text: '25:00',
  );
  final TextEditingController _paceBuilderDistanceController =
      TextEditingController(text: '5');
  final TextEditingController _paceBuilderTimeController =
      TextEditingController(text: '25:00');
  final TextEditingController _energyWeightController = TextEditingController(
    text: '70',
  );
  Timer? _noticeTimer;
  Timer? _timeTicker;
  Timer? _jetLagTipTicker;
  String? _noticeText;
  UnitanaNoticeKind _noticeKind = UnitanaNoticeKind.success;
  int _jetLagTipIndex = 0;
  bool _jetLagTipsAutoRotateEnabled = true;

  /// Direction flag used by ToolConverters.
  /// - height: forward => cm -> ft/in
  /// - baking: forward => cup -> ml
  /// - liquids: forward => oz -> ml
  /// - area: forward => m² -> ft²
  bool _forward = true;

  // Multi-unit support (medium-scope): Volume and Pressure can choose among
  // a small set of units via unit pills, while most tools remain dual-unit.
  //
  // These are display + conversion units, not persistence keys. History remains
  // keyed by tool id and stores the rendered labels.
  String? _fromUnitOverride;
  String? _toUnitOverride;
  String? _currencyFromOverride;
  String? _currencyToOverride;
  String? _lookupFromSystem;
  String? _lookupToSystem;
  String? _lookupEntryKey;
  int _lookupMatrixPageIndex = 0;
  String? _timeFromZoneId;
  String? _timeToZoneId;
  String? _timeFromDisplayLabel;
  String? _timeToDisplayLabel;
  List<int> _tipPresetPercents = const <int>[10, 15, 20];
  int _tipPercent = 15;
  int _tipSplitCount = 1;
  String _tipRoundingMode = 'none';
  List<int> _taxPresetPercents = const <int>[5, 8, 10];
  int _taxPercent = 8;
  String _taxMode = 'add_on';
  bool _unitPriceCompareEnabled = false;
  String _unitPriceUnitA = 'g';
  String _unitPriceUnitB = 'g';
  String _hydrationWeightUnit = 'kg';
  String _hydrationClimateBand = 'temperate';
  int _jetLagBedtimeMinutes = 23 * 60;
  int _jetLagWakeMinutes = 7 * 60;
  bool _jetLagOverlapExpanded = false;
  double _paceGoalDistanceKm = 5.0;
  _PaceMode _paceMode = _PaceMode.running;
  String _paceBuilderDistanceUnit = 'km';
  String _energyWeightUnit = 'kg';
  String _energyActivity = 'moderate';

  bool get _isMultiUnitTool =>
      widget.tool.canonicalToolId == CanonicalToolId.distance ||
      widget.tool.canonicalToolId == CanonicalToolId.area ||
      widget.tool.canonicalToolId == CanonicalToolId.liquids ||
      widget.tool.canonicalToolId == CanonicalToolId.volume ||
      widget.tool.canonicalToolId == CanonicalToolId.pressure ||
      widget.tool.canonicalToolId == CanonicalToolId.weight ||
      widget.tool.canonicalToolId == CanonicalToolId.dataStorage ||
      widget.tool.canonicalToolId == CanonicalToolId.energy ||
      widget.tool.id == 'baking';
  bool get _isLookupTool =>
      widget.tool.canonicalToolId == CanonicalToolId.shoeSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.clothingSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.paperSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.mattressSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.cupsGramsEstimates;
  bool get _isFullMatrixLookupTool =>
      widget.tool.canonicalToolId == CanonicalToolId.shoeSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.clothingSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.paperSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.mattressSizes;
  bool get _isClothingLookupTool =>
      widget.tool.canonicalToolId == CanonicalToolId.clothingSizes;
  bool get _isTipHelperTool => widget.tool.id == 'tip_helper';
  bool get _isTaxVatTool => widget.tool.id == 'tax_vat_helper';
  bool get _isUnitPriceTool => widget.tool.id == 'unit_price_helper';
  bool get _isHydrationTool => widget.tool.id == 'hydration';
  bool get _isJetLagDeltaTool => widget.tool.id == 'jet_lag_delta';
  bool get _isWorldClockMapTool => widget.tool.id == 'world_clock_delta';
  bool get _isTimeTool =>
      widget.tool.canonicalToolId == CanonicalToolId.time ||
      widget.tool.id == 'time';
  bool get _isTimeZoneConverterTool => widget.tool.id == 'time_zone_converter';
  bool get _supportsUnitPicker => _isMultiUnitTool || _isCurrencyTool;

  List<String> get _multiUnitChoices {
    if (widget.tool.id == 'baking') {
      return const <String>['tsp', 'tbsp', 'cup', 'ml', 'L'];
    }
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.distance:
        return const <String>['m', 'km', 'mi', 'yd', 'ft', 'in'];
      case CanonicalToolId.area:
        return const <String>['m²', 'ft²', 'yd²', 'acre', 'ha'];
      case CanonicalToolId.liquids:
        return const <String>['tsp', 'tbsp', 'cup', 'mL', 'L', 'pt', 'qt'];
      case CanonicalToolId.volume:
        return const <String>['mL', 'L', 'pt', 'qt', 'gal'];
      case CanonicalToolId.pressure:
        return const <String>['kPa', 'psi', 'bar', 'atm'];
      case CanonicalToolId.weight:
        return const <String>['g', 'kg', 'oz', 'lb', 'st'];
      case CanonicalToolId.dataStorage:
        return const <String>['B', 'KB', 'MB', 'GB', 'TB'];
      case CanonicalToolId.energy:
        return const <String>['cal', 'kJ'];
      default:
        return const <String>[];
    }
  }

  List<String> get _currencyChoices {
    final out = kCountryToCurrencyCode.values
        .map((v) => v.trim().toUpperCase())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    out.sort();
    return out;
  }

  /// Inline result display line (separate from the History list).
  String? _resultLine;

  @override
  void initState() {
    super.initState();
    _forward = _defaultForwardFor(
      toolId: widget.tool.canonicalToolId,
      preferMetric: widget.preferMetric,
      prefer24h: widget.prefer24h,
    );

    if (_isCurrencyTool) {
      _forward = _defaultCurrencyForward();
      _seedCurrencySuggestedInput();
    }

    if (_isLookupTool) {
      _seedLookupDefaults();
    }

    if (_isTipHelperTool) {
      _seedTipHelperDefaults();
    }

    if (_isTaxVatTool) {
      _seedTaxVatDefaults();
    }

    if (_isUnitPriceTool) {
      _seedUnitPriceDefaults();
    }

    if (_isHydrationTool) {
      _seedHydrationDefaults();
    }

    if (widget.tool.id == 'energy') {
      _seedEnergyDefaults();
    }

    if (_isTimeTool) {
      _seedTimeToolDefaults();
      _ensureTimeZoneCatalogLoaded();
      if (_isJetLagDeltaTool) {
        _seedJetLagScheduleDefaults();
        _startJetLagTipTickerIfNeeded();
      }
      if (_isTimeZoneConverterTool) {
        _seedTimeConverterInput();
      }
      _timeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    }

    if (_isMultiUnitTool) {
      _seedMultiUnitOverrides();
    }

    final latest = widget.session.latestFor(widget.tool.id);
    if (latest != null) {
      _resultLine = '${latest.inputLabel}  →  ${latest.outputLabel}';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.maybeOf(context);
    final shouldAutoRotate =
        !((mq?.disableAnimations ?? false) ||
            (mq?.accessibleNavigation ?? false));
    if (shouldAutoRotate == _jetLagTipsAutoRotateEnabled) return;
    _jetLagTipsAutoRotateEnabled = shouldAutoRotate;
    if (_jetLagTipsAutoRotateEnabled) {
      _startJetLagTipTickerIfNeeded();
    } else {
      _jetLagTipTicker?.cancel();
      _jetLagTipTicker = null;
      _jetLagTipIndex = 0;
    }
  }

  void _startJetLagTipTickerIfNeeded() {
    if (!_isJetLagDeltaTool || !_jetLagTipsAutoRotateEnabled) return;
    if (_jetLagTipTicker != null) return;
    _jetLagTipTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _jetLagTipIndex += 1;
      });
    });
  }

  void _ensureTimeZoneCatalogLoaded() {
    if (CityRepository.instance.cities.isNotEmpty) return;
    CityRepository.instance.load().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _seedJetLagScheduleDefaults() {
    final home = widget.home;
    if (home == null) return;
    // Keep deterministic defaults if explicit profile sleep windows do not
    // exist yet in app state.
    _jetLagBedtimeMinutes = 23 * 60;
    _jetLagWakeMinutes = 7 * 60;
  }

  int _normalizeMinutesOfDay(int minutes) {
    var out = minutes % (24 * 60);
    if (out < 0) out += 24 * 60;
    return out;
  }

  String _formatMinutesOfDay(int minutes, {required bool use24h}) {
    final norm = _normalizeMinutesOfDay(minutes);
    final hh = norm ~/ 60;
    final mm = (norm % 60).toString().padLeft(2, '0');
    if (use24h) {
      return '${hh.toString().padLeft(2, '0')}:$mm';
    }
    final isPm = hh >= 12;
    var h12 = hh % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:$mm ${isPm ? 'PM' : 'AM'}';
  }

  int _jetLagShiftedMinutes({
    required int baseMinutes,
    required JetLagPlan plan,
  }) {
    if (plan.isNoShift) return baseMinutes;
    final delta = plan.direction == JetLagDirection.eastbound
        ? -plan.dailyShiftMinutes
        : plan.dailyShiftMinutes;
    return _normalizeMinutesOfDay(baseMinutes + delta);
  }

  String _countryFlag(String countryCode) {
    final cc = countryCode.trim().toUpperCase();
    if (cc.length != 2) return '';
    final first = cc.codeUnitAt(0);
    final second = cc.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) return '';
    return String.fromCharCodes(<int>[first + 127397, second + 127397]);
  }

  List<String> _jetLagTipsForPlan(JetLagPlan plan, String destinationLabel) {
    return DashboardCopy.jetLagTips(
      plan: plan,
      destinationLabel: destinationLabel,
    );
  }

  Future<void> _pickJetLagTime({required bool bedtime}) async {
    final initial = bedtime ? _jetLagBedtimeMinutes : _jetLagWakeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: DashboardCopy.jetLagSchedulePickerHelp(
        context,
        bedtime: bedtime,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (bedtime) {
        _jetLagBedtimeMinutes = minutes;
      } else {
        _jetLagWakeMinutes = minutes;
      }
    });
  }

  @override
  void dispose() {
    _timeTicker?.cancel();
    _noticeTimer?.cancel();
    _jetLagTipTicker?.cancel();
    _timeConvertController.dispose();
    _unitPriceAController.dispose();
    _unitQtyAController.dispose();
    _unitPriceBController.dispose();
    _unitQtyBController.dispose();
    _hydrationExerciseController.dispose();
    _paceGoalTimeController.dispose();
    _paceBuilderDistanceController.dispose();
    _paceBuilderTimeController.dispose();
    _energyWeightController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _swapUnits() {
    if (_isTimeTool) {
      _swapTimeZones();
      return;
    }

    if (_isLookupTool) {
      _swapLookupSystems();
      return;
    }

    if (_isMultiUnitTool) {
      setState(() {
        _forward = !_forward;
        if (_fromUnitOverride == null || _toUnitOverride == null) {
          _seedMultiUnitOverrides();
        } else {
          final tmp = _fromUnitOverride;
          _fromUnitOverride = _toUnitOverride;
          _toUnitOverride = tmp;
        }
      });
      return;
    }

    setState(() {
      _forward = !_forward;
      if (_isCurrencyTool && _controller.text.trim().isEmpty) {
        _seedCurrencySuggestedInput(force: true);
      }
    });
  }

  void _seedMultiUnitOverrides() {
    if (widget.tool.id == 'baking') {
      _fromUnitOverride = _forward ? 'cup' : 'ml';
      _toUnitOverride = _forward ? 'ml' : 'cup';
      return;
    }
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.volume:
        _fromUnitOverride = _forward ? 'L' : 'gal';
        _toUnitOverride = _forward ? 'gal' : 'L';
        return;
      case CanonicalToolId.pressure:
        _fromUnitOverride = _forward ? 'kPa' : 'psi';
        _toUnitOverride = _forward ? 'psi' : 'kPa';
        return;
      case CanonicalToolId.weight:
        _fromUnitOverride = _forward ? 'kg' : 'lb';
        _toUnitOverride = _forward ? 'lb' : 'kg';
        return;
      case CanonicalToolId.dataStorage:
        _fromUnitOverride = _forward ? 'GB' : 'MB';
        _toUnitOverride = _forward ? 'MB' : 'GB';
        return;
      case CanonicalToolId.energy:
        _fromUnitOverride = _forward ? 'cal' : 'kJ';
        _toUnitOverride = _forward ? 'kJ' : 'cal';
        return;
      default:
        _fromUnitOverride = null;
        _toUnitOverride = null;
        return;
    }
  }

  List<String> _lookupSystemsForTool() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.shoeSizes:
        return const <String>[
          'US Men',
          'US Women',
          'EU',
          'UK',
          'AU',
          'JP (cm)',
        ];
      case CanonicalToolId.paperSizes:
        return const <String>['ISO', 'US', 'JIS', 'ANSI/ARCH'];
      case CanonicalToolId.clothingSizes:
        return const <String>['US', 'EU', 'UK', 'JP'];
      case CanonicalToolId.mattressSizes:
        return const <String>['US', 'EU', 'UK', 'AU', 'JP'];
      case CanonicalToolId.cupsGramsEstimates:
        return const <String>['Cup', 'Tbsp', 'Tsp', 'Weight'];
      default:
        return const <String>[];
    }
  }

  List<_LookupEntry> _lookupEntriesForTool() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.shoeSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'shoe_2',
            label: '20.0',
            valuesBySystem: <String, String>{
              'US Men': '2',
              'US Women': '3.5',
              'EU': '34',
              'UK': '1',
              'AU': '1',
              'JP (cm)': '20.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_3',
            label: '21.0',
            valuesBySystem: <String, String>{
              'US Men': '3',
              'US Women': '4.5',
              'EU': '35',
              'UK': '2',
              'AU': '2',
              'JP (cm)': '21.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_4',
            label: '22.0',
            valuesBySystem: <String, String>{
              'US Men': '4',
              'US Women': '5.5',
              'EU': '36',
              'UK': '3.5',
              'AU': '3.5',
              'JP (cm)': '22.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_4_5',
            label: '22.5',
            valuesBySystem: <String, String>{
              'US Men': '4.5',
              'US Women': '6',
              'EU': '36.5',
              'UK': '4',
              'AU': '4',
              'JP (cm)': '22.5 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_5',
            label: '23.0',
            valuesBySystem: <String, String>{
              'US Men': '5',
              'US Women': '6.5',
              'EU': '37',
              'UK': '4.5',
              'AU': '4.5',
              'JP (cm)': '23.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_5_5',
            label: '23.5',
            valuesBySystem: <String, String>{
              'US Men': '5.5',
              'US Women': '7',
              'EU': '37.5',
              'UK': '5',
              'AU': '5',
              'JP (cm)': '23.5 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_6',
            label: '24.0',
            valuesBySystem: <String, String>{
              'US Men': '6',
              'US Women': '7.5',
              'EU': '38',
              'UK': '5.5',
              'AU': '5.5',
              'JP (cm)': '24.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_6_5',
            label: '24.5',
            valuesBySystem: <String, String>{
              'US Men': '6.5',
              'US Women': '8',
              'EU': '39',
              'UK': '5.5',
              'AU': '5.5',
              'JP (cm)': '24.5 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_7',
            label: '25.0',
            valuesBySystem: <String, String>{
              'US Men': '7',
              'US Women': '8.5',
              'EU': '40',
              'UK': '6',
              'AU': '6',
              'JP (cm)': '25.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_8',
            label: '26.0',
            valuesBySystem: <String, String>{
              'US Men': '8',
              'US Women': '9.5',
              'EU': '41',
              'UK': '7',
              'AU': '7',
              'JP (cm)': '26.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_9',
            label: '27.0',
            valuesBySystem: <String, String>{
              'US Men': '9',
              'US Women': '10.5',
              'EU': '42',
              'UK': '8',
              'AU': '8',
              'JP (cm)': '27.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_10',
            label: '28.0',
            valuesBySystem: <String, String>{
              'US Men': '10',
              'US Women': '11.5',
              'EU': '43',
              'UK': '9',
              'AU': '9',
              'JP (cm)': '28.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_11',
            label: '29.0',
            valuesBySystem: <String, String>{
              'US Men': '11',
              'US Women': '12.5',
              'EU': '44.5',
              'UK': '10',
              'AU': '10',
              'JP (cm)': '29.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_12',
            label: '30.0',
            valuesBySystem: <String, String>{
              'US Men': '12',
              'US Women': '13.5',
              'EU': '46',
              'UK': '11',
              'AU': '11',
              'JP (cm)': '30.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_13',
            label: '31.0',
            valuesBySystem: <String, String>{
              'US Men': '13',
              'US Women': '14.5',
              'EU': '47',
              'UK': '12',
              'AU': '12',
              'JP (cm)': '31.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_14',
            label: '32.0',
            valuesBySystem: <String, String>{
              'US Men': '14',
              'US Women': '15.5',
              'EU': '48',
              'UK': '13',
              'AU': '13',
              'JP (cm)': '32.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_14_5',
            label: '32.5',
            valuesBySystem: <String, String>{
              'US Men': '14.5',
              'US Women': '16',
              'EU': '49',
              'UK': '13.5',
              'AU': '13.5',
              'JP (cm)': '32.5 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_15',
            label: '33.0',
            valuesBySystem: <String, String>{
              'US Men': '15',
              'US Women': '16.5',
              'EU': '50',
              'UK': '14',
              'AU': '14',
              'JP (cm)': '33.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_16',
            label: '34.0',
            valuesBySystem: <String, String>{
              'US Men': '16',
              'US Women': '17.5',
              'EU': '51',
              'UK': '15',
              'AU': '15',
              'JP (cm)': '34.0 cm',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_17',
            label: '35.0',
            valuesBySystem: <String, String>{
              'US Men': '17',
              'US Women': '18.5',
              'EU': '52',
              'UK': '16',
              'AU': '16',
              'JP (cm)': '35.0 cm',
            },
          ),
        ];
      case CanonicalToolId.clothingSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'cloth_w_tops_xs',
            label: 'Women Tops • XS',
            valuesBySystem: <String, String>{
              'US': '2',
              'EU': '34',
              'UK': '6',
              'JP': '5',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_w_tops_s',
            label: 'Women Tops • S',
            valuesBySystem: <String, String>{
              'US': '4-6',
              'EU': '36-38',
              'UK': '8-10',
              'JP': '7-9',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_w_bottoms_6',
            label: 'Women Bottoms • US 6',
            valuesBySystem: <String, String>{
              'US': '6',
              'EU': '38',
              'UK': '10',
              'JP': '9',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_w_bottoms_10',
            label: 'Women Bottoms • US 10',
            valuesBySystem: <String, String>{
              'US': '10',
              'EU': '42',
              'UK': '14',
              'JP': '13',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_m_tops_m',
            label: 'Men Tops • M',
            valuesBySystem: <String, String>{
              'US': 'M',
              'EU': '48',
              'UK': 'M',
              'JP': 'L',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_m_tops_l',
            label: 'Men Tops • L',
            valuesBySystem: <String, String>{
              'US': 'L',
              'EU': '50',
              'UK': 'L',
              'JP': 'LL',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_m_bottoms_32',
            label: 'Men Bottoms • Waist 32',
            valuesBySystem: <String, String>{
              'US': '32',
              'EU': '48',
              'UK': '32',
              'JP': '82',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_m_bottoms_34',
            label: 'Men Bottoms • Waist 34',
            valuesBySystem: <String, String>{
              'US': '34',
              'EU': '50',
              'UK': '34',
              'JP': '86',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_outer_unisex_m',
            label: 'Outerwear (Unisex) • M',
            valuesBySystem: <String, String>{
              'US': 'M',
              'EU': '48',
              'UK': 'M',
              'JP': 'L',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cloth_outer_unisex_xl',
            label: 'Outerwear (Unisex) • XL',
            valuesBySystem: <String, String>{
              'US': 'XL',
              'EU': '54',
              'UK': 'XL',
            },
            note:
                'Approximate reference only • Source: public standards + retailer aggregate.',
            approximate: true,
          ),
        ];
      case CanonicalToolId.paperSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'paper_a5',
            label: 'A5',
            valuesBySystem: <String, String>{
              'ISO': 'A5 (148 x 210 mm)',
              'US': 'Half Letter (5.5 x 8.5 in)',
              'JIS': 'B6 (128 x 182 mm)',
              'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
            },
            note: 'Closest common equivalents by region.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_a4',
            label: 'A4',
            valuesBySystem: <String, String>{
              'ISO': 'A4 (210 x 297 mm)',
              'US': 'Letter (8.5 x 11 in)',
              'JIS': 'B5 (182 x 257 mm)',
              'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
            },
            note: 'Closest common equivalents by region.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_a3',
            label: 'A3',
            valuesBySystem: <String, String>{
              'ISO': 'A3 (297 x 420 mm)',
              'US': 'Tabloid (11 x 17 in)',
              'JIS': 'B4 (257 x 364 mm)',
              'ANSI/ARCH': 'ANSI B (11 x 17 in)',
            },
            note: 'Closest common equivalents by region.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_b5',
            label: 'B5',
            valuesBySystem: <String, String>{
              'ISO': 'B5 (176 x 250 mm)',
              'US': 'Statement (5.5 x 8.5 in)',
              'JIS': 'B5 (182 x 257 mm)',
              'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
            },
            note: 'ISO B-series and JIS B-series are different dimensions.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_b4',
            label: 'B4',
            valuesBySystem: <String, String>{
              'ISO': 'B4 (250 x 353 mm)',
              'US': 'Legal (8.5 x 14 in)',
              'JIS': 'B4 (257 x 364 mm)',
              'ANSI/ARCH': 'ANSI B (11 x 17 in)',
            },
            note: 'ISO B-series and JIS B-series are different dimensions.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_letter',
            label: 'Letter',
            valuesBySystem: <String, String>{
              'ISO': 'A4 (210 x 297 mm)',
              'US': '216 x 279 mm (8.5 x 11 in)',
              'JIS': 'B5 (182 x 257 mm)',
              'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
            },
            note: 'Closest common equivalents by region.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_legal',
            label: 'Legal',
            valuesBySystem: <String, String>{
              'ISO': 'B4 (250 x 353 mm)',
              'US': '216 x 356 mm (8.5 x 14 in)',
              'JIS': 'B4 (257 x 364 mm)',
              'ANSI/ARCH': 'ANSI B (11 x 17 in)',
            },
            note: 'Closest common equivalents by region.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_arch_d',
            label: 'ARCH D',
            valuesBySystem: <String, String>{
              'ISO': 'A1 (594 x 841 mm)',
              'US': 'ARCH D (24 x 36 in)',
              'JIS': 'B2 (515 x 728 mm)',
              'ANSI/ARCH': 'ARCH D (24 x 36 in)',
            },
            note: 'Architecture/engineering sheet equivalents.',
            approximate: true,
          ),
        ];
      case CanonicalToolId.mattressSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'matt_twin',
            label: 'Twin',
            valuesBySystem: <String, String>{
              'US': 'Twin (38 x 75 in)',
              'EU': 'Single (90 x 200 cm)',
              'UK': 'Single (90 x 190 cm)',
              'AU': 'Single (92 x 188 cm)',
              'JP': 'Single (97 x 195 cm)',
            },
            note: 'Regional naming varies by vendor.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_single_xl',
            label: 'Twin XL / Long Single',
            valuesBySystem: <String, String>{
              'US': 'Twin XL (38 x 80 in)',
              'EU': 'Single XL (90 x 210 cm)',
              'UK': 'Long Single (90 x 200 cm)',
              'AU': 'Long Single (92 x 203 cm)',
              'JP': 'Semi-double (120 x 195 cm)',
            },
            note: 'Useful for dorm and split-king setups.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_full',
            label: 'Full / Double',
            valuesBySystem: <String, String>{
              'US': 'Full (54 x 75 in)',
              'EU': 'Double (140 x 200 cm)',
              'UK': 'Double (135 x 190 cm)',
              'AU': 'Double (138 x 188 cm)',
              'JP': 'Double (140 x 195 cm)',
            },
            note: 'Regional naming varies by vendor.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_queen',
            label: 'Queen',
            valuesBySystem: <String, String>{
              'US': 'Queen (60 x 80 in)',
              'EU': 'King (160 x 200 cm)',
              'UK': 'King (150 x 200 cm)',
              'AU': 'Queen (153 x 203 cm)',
              'JP': 'Queen (160 x 195 cm)',
            },
            note: 'Approximate cross-region equivalent.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_king',
            label: 'King',
            valuesBySystem: <String, String>{
              'US': 'King (76 x 80 in)',
              'EU': 'Super King (180 x 200 cm)',
              'UK': 'Super King (180 x 200 cm)',
              'AU': 'King (183 x 203 cm)',
              'JP': 'King (180 x 195 cm)',
            },
            note: 'Approximate cross-region equivalent.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_super_king_us',
            label: 'California King',
            valuesBySystem: <String, String>{
              'US': 'California King (72 x 84 in)',
              'EU': 'Super King (180 x 210 cm)',
              'UK': 'Super King (180 x 200 cm)',
              'AU': 'Super King (203 x 203 cm)',
              'JP': 'Wide King (200 x 200 cm)',
            },
            note: 'Cross-region equivalence is approximate by shape and area.',
            approximate: true,
          ),
        ];
      case CanonicalToolId.cupsGramsEstimates:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'cupsgrams_flour',
            label: 'Flour (all-purpose)',
            valuesBySystem: <String, String>{
              'Cup': '1 cup',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '120 g',
            },
            note: 'Approximate scoop-and-level reference.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_sugar',
            label: 'Sugar (granulated)',
            valuesBySystem: <String, String>{
              'Cup': '1 cup',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '200 g',
            },
            note: 'Pack density varies by crystal size and humidity.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_brown_sugar',
            label: 'Brown sugar (packed)',
            valuesBySystem: <String, String>{
              'Cup': '1 cup packed',
              'Tbsp': '16 tbsp packed',
              'Tsp': '48 tsp packed',
              'Weight': '220 g',
            },
            note: 'Assumes packed cup measurement.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_butter',
            label: 'Butter',
            valuesBySystem: <String, String>{
              'Cup': '1 cup / 2 sticks',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '227 g',
            },
            note: 'Equivalent to 2 US sticks.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_rice',
            label: 'Rice (uncooked white)',
            valuesBySystem: <String, String>{
              'Cup': '1 cup',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '185 g',
            },
            note: 'Estimate before cooking.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_oats',
            label: 'Oats (rolled)',
            valuesBySystem: <String, String>{
              'Cup': '1 cup',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '90 g',
            },
            note: 'Rolled oats are lighter by volume than flour.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'cupsgrams_honey',
            label: 'Honey',
            valuesBySystem: <String, String>{
              'Cup': '1 cup',
              'Tbsp': '16 tbsp',
              'Tsp': '48 tsp',
              'Weight': '340 g',
            },
            note: 'Dense liquid; weight is significantly higher per cup.',
            approximate: true,
          ),
        ];
      default:
        return const <_LookupEntry>[];
    }
  }

  _LookupEntry? _activeLookupEntry() {
    final rows = _lookupEntriesForTool();
    if (rows.isEmpty) return null;
    final key = _lookupEntryKey;
    if (key == null) return rows.first;
    for (final row in rows) {
      if (row.keyId == key) return row;
    }
    return rows.first;
  }

  String _lookupValue({required _LookupEntry row, required String system}) {
    return row.valuesBySystem[system] ?? '—';
  }

  void _seedLookupDefaults() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.shoeSizes:
        _lookupFromSystem = 'US Men';
        _lookupToSystem = 'EU';
        _lookupEntryKey = 'shoe_9';
        return;
      case CanonicalToolId.paperSizes:
        _lookupFromSystem = 'ISO';
        _lookupToSystem = 'US';
        _lookupEntryKey = 'paper_a4';
        return;
      case CanonicalToolId.clothingSizes:
        _lookupFromSystem = 'US';
        _lookupToSystem = 'EU';
        _lookupEntryKey = 'cloth_w_tops_s';
        return;
      case CanonicalToolId.mattressSizes:
        _lookupFromSystem = 'US';
        _lookupToSystem = 'EU';
        _lookupEntryKey = 'matt_queen';
        return;
      case CanonicalToolId.cupsGramsEstimates:
        _lookupFromSystem = 'Cup';
        _lookupToSystem = 'Weight';
        _lookupEntryKey = 'cupsgrams_flour';
        return;
      default:
        _lookupFromSystem = null;
        _lookupToSystem = null;
        _lookupEntryKey = null;
        return;
    }
  }

  void _seedTipHelperDefaults() {
    final countryCode = _activeTipCountryCode();
    _tipPresetPercents = _tipPresetsForCountry(countryCode);
    _tipPercent = _tipPresetPercents.contains(15)
        ? 15
        : _tipPresetPercents[(_tipPresetPercents.length / 2).floor()];
    _tipSplitCount = 1;
    _tipRoundingMode = 'none';
    if (_controller.text.trim().isEmpty) {
      _controller.text = '100';
    }
  }

  void _seedTaxVatDefaults() {
    final countryCode = _activeTipCountryCode();
    _taxPresetPercents = _taxPresetsForCountry(countryCode);
    _taxPercent = _taxPresetPercents.contains(8)
        ? 8
        : _taxPresetPercents[(_taxPresetPercents.length / 2).floor()];
    _taxMode = 'add_on';
    if (_controller.text.trim().isEmpty) {
      _controller.text = '100';
    }
  }

  void _seedUnitPriceDefaults() {
    if (_unitPriceAController.text.trim().isEmpty) {
      _unitPriceAController.text = '4.99';
    }
    if (_unitQtyAController.text.trim().isEmpty) {
      _unitQtyAController.text = '500';
    }
    if (_unitPriceBController.text.trim().isEmpty) {
      _unitPriceBController.text = '6.49';
    }
    if (_unitQtyBController.text.trim().isEmpty) {
      _unitQtyBController.text = '750';
    }
    _unitPriceCompareEnabled = false;
    _unitPriceUnitA = 'g';
    _unitPriceUnitB = 'g';
  }

  void _seedHydrationDefaults() {
    if (_controller.text.trim().isEmpty) {
      _controller.text = '70';
    }
    if (_hydrationExerciseController.text.trim().isEmpty) {
      _hydrationExerciseController.text = '30';
    }
    _hydrationWeightUnit = widget.preferMetric ? 'kg' : 'lb';
    _hydrationClimateBand = 'temperate';
  }

  void _seedEnergyDefaults() {
    if (_energyWeightController.text.trim().isEmpty) {
      _energyWeightController.text = widget.preferMetric ? '70' : '155';
    }
    _energyWeightUnit = widget.preferMetric ? 'kg' : 'lb';
    _energyActivity = 'moderate';
  }

  String _activeTipCountryCode() {
    final preferred = widget.session.reality == DashboardReality.destination
        ? widget.destination
        : widget.home;
    final fallback = preferred == widget.destination
        ? widget.home
        : widget.destination;
    return (preferred?.countryCode ?? fallback?.countryCode ?? 'US')
        .trim()
        .toUpperCase();
  }

  List<int> _tipPresetsForCountry(String countryCode) {
    switch (countryCode) {
      case 'US':
      case 'CA':
        return const <int>[15, 18, 20];
      case 'JP':
      case 'KR':
        return const <int>[0, 5, 10];
      case 'PT':
      case 'ES':
      case 'IT':
      case 'FR':
      case 'DE':
        return const <int>[5, 10, 15];
      default:
        return const <int>[10, 15, 20];
    }
  }

  List<int> _taxPresetsForCountry(String countryCode) {
    switch (countryCode) {
      case 'US':
        return const <int>[6, 8, 10];
      case 'CA':
        return const <int>[5, 13, 15];
      case 'GB':
      case 'FR':
      case 'DE':
      case 'IT':
      case 'ES':
        return const <int>[5, 10, 20];
      case 'JP':
        return const <int>[8, 10];
      default:
        return const <int>[5, 8, 10];
    }
  }

  String _tipCurrencyCode() {
    final cc = _activeTipCountryCode();
    final code = kCountryToCurrencyCode[cc];
    if (code == null || code.trim().isEmpty) return 'USD';
    return code.trim().toUpperCase();
  }

  double? _parseTipAmount() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || !parsed.isFinite) return null;
    if (parsed < 0) return null;
    return parsed;
  }

  double? _parseTaxVatAmount() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || !parsed.isFinite) return null;
    if (parsed < 0) return null;
    return parsed;
  }

  static const Map<String, double> _unitPriceMassToG = <String, double>{
    'g': 1.0,
    'kg': 1000.0,
    'oz': 28.349523125,
    'lb': 453.59237,
  };
  static const Map<String, double> _unitPriceVolumeToMl = <String, double>{
    'mL': 1.0,
    'L': 1000.0,
    'fl oz': 29.5735295625,
  };

  bool _isUnitPriceMassUnit(String unit) => _unitPriceMassToG.containsKey(unit);
  bool _isUnitPriceVolumeUnit(String unit) =>
      _unitPriceVolumeToMl.containsKey(unit);

  bool _sameUnitPriceFamily(String a, String b) {
    return (_isUnitPriceMassUnit(a) && _isUnitPriceMassUnit(b)) ||
        (_isUnitPriceVolumeUnit(a) && _isUnitPriceVolumeUnit(b));
  }

  String _defaultFamilyUnitFor(String unit) {
    if (_isUnitPriceMassUnit(unit)) return 'g';
    if (_isUnitPriceVolumeUnit(unit)) return 'mL';
    return 'g';
  }

  void _handleUnitPriceUnitSelected({
    required bool forProductA,
    required String unit,
  }) {
    setState(() {
      if (forProductA) {
        _unitPriceUnitA = unit;
        if (_unitPriceCompareEnabled &&
            !_sameUnitPriceFamily(_unitPriceUnitA, _unitPriceUnitB)) {
          _unitPriceUnitB = _defaultFamilyUnitFor(unit);
        }
      } else {
        _unitPriceUnitB = unit;
        if (_unitPriceCompareEnabled &&
            !_sameUnitPriceFamily(_unitPriceUnitA, _unitPriceUnitB)) {
          _unitPriceUnitA = _defaultFamilyUnitFor(unit);
        }
      }
    });
  }

  List<String> get _unitPriceUnits => const <String>[
    'g',
    'kg',
    'oz',
    'lb',
    'mL',
    'L',
    'fl oz',
  ];

  double? _parsePositiveText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _unitPriceToBaseAmount({
    required double quantity,
    required String unit,
  }) {
    final massFactor = _unitPriceMassToG[unit];
    if (massFactor != null) return quantity * massFactor;
    final volumeFactor = _unitPriceVolumeToMl[unit];
    if (volumeFactor != null) return quantity * volumeFactor;
    return null;
  }

  String _unitPricePrimaryCurrencyCode() {
    final preferDestination =
        widget.session.reality == DashboardReality.destination;
    final preferred = preferDestination ? widget.destination : widget.home;
    final fallback = preferDestination ? widget.home : widget.destination;
    final code = currencyCodeForCountryCode(
      preferred?.countryCode ?? fallback?.countryCode,
    );
    return code;
  }

  String? _unitPriceSecondaryCurrencyCode() {
    final primary = _unitPricePrimaryCurrencyCode();
    final preferDestination =
        widget.session.reality == DashboardReality.destination;
    final secondaryPlace = preferDestination ? widget.home : widget.destination;
    final code = currencyCodeForCountryCode(secondaryPlace?.countryCode);
    if (code.trim().toUpperCase() == primary.trim().toUpperCase()) {
      return null;
    }
    return code;
  }

  String _moneyWithCurrency(double amount, String code) {
    final symbol = _currencySymbol(code);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  double? _convertCurrencyAmount({
    required double amount,
    required String fromCode,
    required String toCode,
  }) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    if (from == to) return amount;

    final pairRate = widget.currencyRateForPair?.call(from, to);
    if (pairRate != null && pairRate > 0) {
      return amount * pairRate;
    }

    final rate = (widget.eurToUsd == null || widget.eurToUsd! <= 0)
        ? 1.10
        : widget.eurToUsd!;
    if (from == 'EUR' && to == 'USD') return amount * rate;
    if (from == 'USD' && to == 'EUR') return amount / rate;
    return null;
  }

  double _applyTipRounding(double value) {
    switch (_tipRoundingMode) {
      case 'nearest':
        return value.roundToDouble();
      case 'up':
        return value.ceilToDouble();
      case 'down':
        return value.floorToDouble();
      case 'none':
      default:
        return value;
    }
  }

  String _moneyWithCode(double amount) {
    final code = _tipCurrencyCode();
    final symbol = _currencySymbol(code);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  double? _parseHydrationWeightKg() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    if (_hydrationWeightUnit == 'lb') {
      return parsed * 0.45359237;
    }
    return parsed;
  }

  int? _parseHydrationExerciseMinutes() {
    final raw = _hydrationExerciseController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  double _hydrationClimateLitersBonus() {
    switch (_hydrationClimateBand) {
      case 'cool':
        return 0.0;
      case 'warm':
        return 0.35;
      case 'hot':
        return 0.7;
      case 'temperate':
      default:
        return 0.15;
    }
  }

  Widget _buildHydrationBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final weightKg = _parseHydrationWeightKg();
    final exerciseMinutes = _parseHydrationExerciseMinutes();

    final baseLiters = weightKg == null ? null : (weightKg * 0.033);
    final exerciseLiters = exerciseMinutes == null
        ? null
        : (exerciseMinutes * 0.006);
    final climateLiters = _hydrationClimateLitersBonus();
    final totalLiters = (baseLiters == null || exerciseLiters == null)
        ? null
        : math.max(1.0, baseLiters + exerciseLiters + climateLiters);
    final totalOz = totalLiters == null ? null : totalLiters * 33.814;

    String climateLabel(String band) {
      switch (band) {
        case 'cool':
          return 'Cool';
        case 'warm':
          return 'Warm';
        case 'hot':
          return 'Hot';
        case 'temperate':
        default:
          return 'Temperate';
      }
    }

    return ListView(
      key: ValueKey('tool_hydration_scroll_${widget.tool.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_hydration_weight_${widget.tool.id}'),
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Body weight ($_hydrationWeightUnit)',
            hintText: _hydrationWeightUnit == 'kg' ? '70' : '155',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: ValueKey('tool_hydration_unit_${widget.tool.id}_kg'),
              label: const Text('kg'),
              selected: _hydrationWeightUnit == 'kg',
              onSelected: (_) => setState(() {
                _hydrationWeightUnit = 'kg';
              }),
            ),
            ChoiceChip(
              key: ValueKey('tool_hydration_unit_${widget.tool.id}_lb'),
              label: const Text('lb'),
              selected: _hydrationWeightUnit == 'lb',
              onSelected: (_) => setState(() {
                _hydrationWeightUnit = 'lb';
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: ValueKey('tool_hydration_exercise_${widget.tool.id}'),
          controller: _hydrationExerciseController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Exercise minutes today',
            hintText: '30',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['cool', 'temperate', 'warm', 'hot'].map((band) {
            return ChoiceChip(
              key: ValueKey('tool_hydration_climate_${widget.tool.id}_$band'),
              label: Text(climateLabel(band)),
              selected: _hydrationClimateBand == band,
              onSelected: (_) => setState(() {
                _hydrationClimateBand = band;
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_hydration_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: (totalLiters == null || totalOz == null)
              ? Text(
                  'Enter valid weight and exercise minutes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLine(
                      prompt: '>',
                      input: 'Daily fluid estimate',
                      output:
                          '${totalLiters.toStringAsFixed(1)} L (${totalOz.toStringAsFixed(0)} fl oz)',
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DashboardCopy.disclaimerMedical(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTipHelperBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final amount = _parseTipAmount();
    final tipRaw = amount == null ? null : amount * (_tipPercent / 100.0);
    final totalRaw = amount == null ? null : amount + tipRaw!;
    final totalRounded = totalRaw == null ? null : _applyTipRounding(totalRaw);
    final perPerson = totalRounded == null
        ? null
        : totalRounded / _tipSplitCount;
    final roundDelta = (totalRounded != null && totalRaw != null)
        ? (totalRounded - totalRaw)
        : null;

    return ListView(
      key: ValueKey('tool_tip_scroll_${widget.tool.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_tip_amount_${widget.tool.id}'),
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: DashboardCopy.tipBillAmountLabel(
              context,
              _tipCurrencyCode(),
            ),
            hintText: DashboardCopy.tipAmountHint(context),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _tipPresetPercents)
              ChoiceChip(
                key: ValueKey('tool_tip_chip_${widget.tool.id}_$p'),
                label: Text('$p%'),
                selected: _tipPercent == p,
                onSelected: (_) => setState(() {
                  _tipPercent = p;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              DashboardCopy.tipSplitLabel(context),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: _ToolModalThemePolicy.headingTone(context),
              ),
            ),
            const Spacer(),
            IconButton(
              key: ValueKey('tool_tip_split_minus_${widget.tool.id}'),
              onPressed: _tipSplitCount <= 1
                  ? null
                  : () => setState(() {
                      _tipSplitCount = math.max(1, _tipSplitCount - 1);
                    }),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text(
              '$_tipSplitCount',
              key: ValueKey('tool_tip_split_value_${widget.tool.id}'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            IconButton(
              key: ValueKey('tool_tip_split_plus_${widget.tool.id}'),
              onPressed: () => setState(() {
                _tipSplitCount = math.min(12, _tipSplitCount + 1);
              }),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('none', DashboardCopy.tipRoundingLabel(context, 'none')),
                ('nearest', DashboardCopy.tipRoundingLabel(context, 'nearest')),
                ('up', DashboardCopy.tipRoundingLabel(context, 'up')),
                ('down', DashboardCopy.tipRoundingLabel(context, 'down')),
              ].map((pair) {
                return ChoiceChip(
                  key: ValueKey('tool_tip_round_${widget.tool.id}_${pair.$1}'),
                  label: Text(pair.$2),
                  selected: _tipRoundingMode == pair.$1,
                  onSelected: (_) => setState(() {
                    _tipRoundingMode = pair.$1;
                  }),
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_tip_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: amount == null
              ? Text(
                  DashboardCopy.tipInvalidAmount(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.tipLineLabel(context, _tipPercent),
                      output: _moneyWithCode(tipRaw!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.tipTotalLabel(context),
                      output: _moneyWithCode(totalRounded!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.tipPerPersonLabel(
                        context,
                        _tipSplitCount,
                      ),
                      output: _moneyWithCode(perPerson!),
                      emphasize: false,
                      arrowColor: accent,
                    ),
                    if (roundDelta != null && roundDelta.abs() >= 0.005) ...[
                      const SizedBox(height: 8),
                      Text(
                        DashboardCopy.tipRoundingAdjustment(
                          context,
                          sign: roundDelta > 0 ? '+' : '',
                          deltaAmount: _moneyWithCode(roundDelta).replaceFirst(
                            _currencySymbol(_tipCurrencyCode()),
                            '',
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTaxVatBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final amount = _parseTaxVatAmount();
    final rate = _taxPercent / 100.0;
    final isAddOn = _taxMode == 'add_on';
    final subtotal = amount == null
        ? null
        : (isAddOn ? amount : amount / (1.0 + rate));
    final tax = amount == null
        ? null
        : (isAddOn ? amount * rate : amount - subtotal!);
    final total = amount == null ? null : (isAddOn ? amount + tax! : amount);

    return ListView(
      key: ValueKey('tool_tax_scroll_${widget.tool.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_tax_amount_${widget.tool.id}'),
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: DashboardCopy.taxAmountLabel(
              context,
              isAddOn: isAddOn,
              currencyCode: _tipCurrencyCode(),
            ),
            hintText: DashboardCopy.taxAmountHint(context),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: ValueKey('tool_tax_mode_${widget.tool.id}_add_on'),
              label: Text(DashboardCopy.taxModeAddOn(context)),
              selected: isAddOn,
              onSelected: (_) => setState(() {
                _taxMode = 'add_on';
              }),
            ),
            ChoiceChip(
              key: ValueKey('tool_tax_mode_${widget.tool.id}_inclusive'),
              label: Text(DashboardCopy.taxModeInclusive(context)),
              selected: !isAddOn,
              onSelected: (_) => setState(() {
                _taxMode = 'inclusive';
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _taxPresetPercents)
              ChoiceChip(
                key: ValueKey('tool_tax_chip_${widget.tool.id}_$p'),
                label: Text('$p%'),
                selected: _taxPercent == p,
                onSelected: (_) => setState(() {
                  _taxPercent = p;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_tax_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: amount == null
              ? Text(
                  DashboardCopy.taxInvalidAmount(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.taxSubtotalLine(context),
                      output: _moneyWithCode(subtotal!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.taxLineLabel(context, _taxPercent),
                      output: _moneyWithCode(tax!),
                      emphasize: false,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: DashboardCopy.taxTotalLine(context),
                      output: _moneyWithCode(total!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DashboardCopy.taxModeHelp(context, isAddOn: isAddOn),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUnitPriceBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBgSoft = _ToolModalThemePolicy.panelBgSoft(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final primaryCurrencyCode = _unitPricePrimaryCurrencyCode();
    final secondaryCurrencyCode = _unitPriceSecondaryCurrencyCode();
    final activePlaceName =
        (widget.session.reality == DashboardReality.destination
            ? widget.destination?.cityName
            : widget.home?.cityName) ??
        DashboardCopy.weatherCityNotSet(context);
    final oppositePlaceName =
        (widget.session.reality == DashboardReality.destination
            ? widget.home?.cityName
            : widget.destination?.cityName) ??
        DashboardCopy.weatherCityNotSet(context);
    final priceA = _parsePositiveText(_unitPriceAController.text);
    final qtyA = _parsePositiveText(_unitQtyAController.text);
    final baseA = (priceA == null || qtyA == null)
        ? null
        : _unitPriceToBaseAmount(quantity: qtyA, unit: _unitPriceUnitA);
    final perBaseA = (baseA == null || baseA <= 0) ? null : priceA! / baseA;

    final aMass = _isUnitPriceMassUnit(_unitPriceUnitA);
    final aVolume = _isUnitPriceVolumeUnit(_unitPriceUnitA);

    final per100A = perBaseA == null
        ? null
        : aMass
        ? perBaseA * 100.0
        : aVolume
        ? perBaseA * 100.0
        : null;
    final per1kA = perBaseA == null
        ? null
        : aMass
        ? perBaseA * 1000.0
        : aVolume
        ? perBaseA * 1000.0
        : null;
    final per100ASecondary = (per100A != null && secondaryCurrencyCode != null)
        ? _convertCurrencyAmount(
            amount: per100A,
            fromCode: primaryCurrencyCode,
            toCode: secondaryCurrencyCode,
          )
        : null;
    final per1kASecondary = (per1kA != null && secondaryCurrencyCode != null)
        ? _convertCurrencyAmount(
            amount: per1kA,
            fromCode: primaryCurrencyCode,
            toCode: secondaryCurrencyCode,
          )
        : null;

    final priceB = _parsePositiveText(_unitPriceBController.text);
    final qtyB = _parsePositiveText(_unitQtyBController.text);
    final baseB = (priceB == null || qtyB == null)
        ? null
        : _unitPriceToBaseAmount(quantity: qtyB, unit: _unitPriceUnitB);
    final perBaseB = (baseB == null || baseB <= 0) ? null : priceB! / baseB;

    final comparable =
        _unitPriceCompareEnabled &&
        perBaseA != null &&
        perBaseB != null &&
        ((_isUnitPriceMassUnit(_unitPriceUnitA) &&
                _isUnitPriceMassUnit(_unitPriceUnitB)) ||
            (_isUnitPriceVolumeUnit(_unitPriceUnitA) &&
                _isUnitPriceVolumeUnit(_unitPriceUnitB)));

    String? compareText;
    if (_unitPriceCompareEnabled && !comparable) {
      compareText = DashboardCopy.unitPriceCompareInvalid(context);
    } else if (comparable) {
      final delta = (perBaseA - perBaseB).abs();
      final pct = (delta / math.min(perBaseA, perBaseB)) * 100.0;
      if (perBaseA < perBaseB) {
        compareText = DashboardCopy.unitPriceCompareA(
          context,
          pct.toStringAsFixed(1),
        );
      } else if (perBaseB < perBaseA) {
        compareText = DashboardCopy.unitPriceCompareB(
          context,
          pct.toStringAsFixed(1),
        );
      } else {
        compareText = DashboardCopy.unitPriceCompareEqual(context);
      }
    }

    Widget productCard({
      required String title,
      required TextEditingController priceController,
      required TextEditingController qtyController,
      required String selectedUnit,
      required ValueChanged<String> onUnitSelected,
      required String keyPrefix,
      required bool isPrimaryCard,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: isPrimaryCard ? accent.withAlpha(28) : panelBgSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimaryCard ? accent.withAlpha(170) : panelBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _ToolModalThemePolicy.headingTone(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('tool_unit_price_price_$keyPrefix'),
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: DashboardCopy.unitPriceLabelPrice(
                  context,
                  primaryCurrencyCode,
                ),
                hintText: DashboardCopy.unitPricePriceHint(context),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: ValueKey('tool_unit_price_qty_$keyPrefix'),
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: DashboardCopy.unitPriceLabelQuantity(context),
                      hintText: DashboardCopy.unitPriceQuantityHint(context),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: ValueKey('tool_unit_price_unit_$keyPrefix'),
                  onPressed: () async {
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final unit in _unitPriceUnits)
                              ListTile(
                                title: Text(unit),
                                trailing: unit == selectedUnit
                                    ? const Icon(Icons.check_rounded)
                                    : null,
                                onTap: () => Navigator.of(context).pop(unit),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (picked == null) return;
                    onUnitSelected(picked);
                  },
                  child: Text(selectedUnit),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final normalizedTarget = aMass
        ? '1 kg'
        : aVolume
        ? '1 L'
        : '1 base';

    return ListView(
      key: ValueKey('tool_unit_price_scroll_${widget.tool.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: accent.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withAlpha(140)),
          ),
          child: Builder(
            builder: (context) {
              final coach = DashboardCopy.unitPriceCoach(
                context,
                primaryCurrency: primaryCurrencyCode,
                secondaryCurrency: secondaryCurrencyCode,
              );
              final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _ToolModalThemePolicy.textPrimary(
                  context,
                ).withAlpha(230),
                fontWeight: FontWeight.w700,
              );
              const prefix = 'How to use:';
              if (!coach.startsWith(prefix)) {
                return Text(coach, style: baseStyle);
              }
              return Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: [
                    TextSpan(
                      text: '$prefix ',
                      style: baseStyle?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(text: coach.substring(prefix.length).trimLeft()),
                  ],
                ),
              );
            },
          ),
        ),
        if (secondaryCurrencyCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: panelBgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: panelBorder),
            ),
            child: Text(
              '$activePlaceName ($primaryCurrencyCode) • $oppositePlaceName ($secondaryCurrencyCode)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        productCard(
          title: DashboardCopy.unitPriceProductTitle(context, isA: true),
          priceController: _unitPriceAController,
          qtyController: _unitQtyAController,
          selectedUnit: _unitPriceUnitA,
          onUnitSelected: (unit) =>
              _handleUnitPriceUnitSelected(forProductA: true, unit: unit),
          keyPrefix: '${widget.tool.id}_a',
          isPrimaryCard: true,
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          key: ValueKey('tool_unit_price_compare_${widget.tool.id}'),
          value: _unitPriceCompareEnabled,
          contentPadding: EdgeInsets.zero,
          title: Text(
            DashboardCopy.unitPriceCompareToggle(context),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          onChanged: (v) {
            setState(() {
              _unitPriceCompareEnabled = v;
              if (_unitPriceCompareEnabled &&
                  !_sameUnitPriceFamily(_unitPriceUnitA, _unitPriceUnitB)) {
                _unitPriceUnitB = _defaultFamilyUnitFor(_unitPriceUnitA);
              }
            });
          },
        ),
        if (_unitPriceCompareEnabled) ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: ValueKey('tool_unit_price_swap_${widget.tool.id}'),
              onPressed: _swapUnitPriceProducts,
              icon: const Icon(Icons.swap_vert_rounded),
              label: Text(DashboardCopy.swapCta(context)),
            ),
          ),
          const SizedBox(height: 8),
          productCard(
            title: DashboardCopy.unitPriceProductTitle(context, isA: false),
            priceController: _unitPriceBController,
            qtyController: _unitQtyBController,
            selectedUnit: _unitPriceUnitB,
            onUnitSelected: (unit) =>
                _handleUnitPriceUnitSelected(forProductA: false, unit: unit),
            keyPrefix: '${widget.tool.id}_b',
            isPrimaryCard: false,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          key: ValueKey('tool_unit_price_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: perBaseA == null
              ? Text(
                  DashboardCopy.unitPriceInvalidProductA(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLine(
                      prompt: '>',
                      input: 'Product A',
                      output:
                          '${_moneyWithCurrency(per100A!, primaryCurrencyCode)} per ${aMass ? '100g' : '100mL'}',
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: 'Product A',
                      output:
                          '${_moneyWithCurrency(per1kA!, primaryCurrencyCode)} per ${aMass ? 'kg' : 'L'}',
                      emphasize: false,
                      arrowColor: accent,
                    ),
                    if (secondaryCurrencyCode != null &&
                        per100ASecondary != null &&
                        per1kASecondary != null) ...[
                      const SizedBox(height: 8),
                      _TerminalLine(
                        prompt: '>',
                        input: oppositePlaceName,
                        output:
                            '${_moneyWithCurrency(per100ASecondary, secondaryCurrencyCode)} per ${aMass ? '100g' : '100mL'}',
                        emphasize: false,
                        arrowColor: accent,
                      ),
                      const SizedBox(height: 6),
                      _TerminalLine(
                        prompt: '>',
                        input: oppositePlaceName,
                        output:
                            '${_moneyWithCurrency(per1kASecondary, secondaryCurrencyCode)} per ${aMass ? 'kg' : 'L'}',
                        emphasize: false,
                        arrowColor: accent,
                      ),
                    ],
                    if (_unitPriceCompareEnabled && compareText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        compareText,
                        key: ValueKey(
                          'tool_unit_price_compare_result_${widget.tool.id}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (comparable) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Normalized basket ($normalizedTarget): '
                        '${_moneyWithCurrency(perBaseA * 1000, primaryCurrencyCode)} vs '
                        '${_moneyWithCurrency(perBaseB * 1000, primaryCurrencyCode)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _swapLookupSystems() {
    final from = _lookupFromSystem;
    final to = _lookupToSystem;
    if (from == null || to == null) return;
    setState(() {
      _lookupFromSystem = to;
      _lookupToSystem = from;
    });
  }

  void _swapUnitPriceProducts() {
    if (!_unitPriceCompareEnabled) return;
    setState(() {
      final aPrice = _unitPriceAController.text;
      final aQty = _unitQtyAController.text;
      final aUnit = _unitPriceUnitA;
      _unitPriceAController.text = _unitPriceBController.text;
      _unitQtyAController.text = _unitQtyBController.text;
      _unitPriceUnitA = _unitPriceUnitB;
      _unitPriceBController.text = aPrice;
      _unitQtyBController.text = aQty;
      _unitPriceUnitB = aUnit;
    });
  }

  bool get _hasCustomLookupSelection {
    final defaults = () {
      switch (widget.tool.canonicalToolId) {
        case CanonicalToolId.shoeSizes:
          return ('US Men', 'EU', 'shoe_9');
        case CanonicalToolId.paperSizes:
          return ('ISO', 'US', 'paper_a4');
        case CanonicalToolId.mattressSizes:
          return ('US', 'EU', 'matt_queen');
        case CanonicalToolId.cupsGramsEstimates:
          return ('Cup', 'Weight', 'cupsgrams_flour');
        default:
          return ('', '', '');
      }
    }();
    return _lookupFromSystem != defaults.$1 ||
        _lookupToSystem != defaults.$2 ||
        _lookupEntryKey != defaults.$3;
  }

  Future<void> _pickLookupSystem({required bool isFrom}) async {
    final choices = _lookupSystemsForTool();
    if (choices.isEmpty) return;
    final current = isFrom ? _lookupFromSystem : _lookupToSystem;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final value in choices)
              ListTile(
                key: ValueKey(
                  'tool_lookup_system_item_${widget.tool.id}_${isFrom ? 'from' : 'to'}_${_sanitizeUnitKey(value)}',
                ),
                title: Text(value),
                trailing: value == current
                    ? Icon(
                        Icons.check_rounded,
                        color: _ToolModalThemePolicy.headingTone(context),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _lookupFromSystem = selected;
      } else {
        _lookupToSystem = selected;
      }
    });
  }

  Future<void> _pickLookupEntry() async {
    final rows = _lookupEntriesForTool();
    if (rows.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final row in rows)
              ListTile(
                key: ValueKey(
                  'tool_lookup_entry_item_${widget.tool.id}_${row.keyId}',
                ),
                title: Text(row.label),
                trailing: row.keyId == _lookupEntryKey
                    ? Icon(
                        Icons.check_rounded,
                        color: _ToolModalThemePolicy.headingTone(context),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(row.keyId),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _lookupEntryKey = selected;
    });
  }

  String _sanitizeUnitKey(String unit) {
    // Keep stable-ish keys even with symbols.
    return unit.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  }

  String? _currencySymbolOrNull(String code) {
    final raw = kCurrencySymbols[code.toUpperCase()];
    if (raw == null) return null;
    final symbol = raw.trim();
    if (symbol.isEmpty) return null;
    if (symbol.toUpperCase() == code.toUpperCase()) return null;
    return symbol;
  }

  bool get _hasCustomUnitSelection {
    if (_isLookupTool) {
      return _hasCustomLookupSelection;
    }
    if (_isCurrencyTool) {
      return _currencyFromOverride != null || _currencyToOverride != null;
    }
    if (!_isMultiUnitTool) return false;
    final defaults = _defaultMultiUnitPair();
    return _fromUnitOverride != defaults.$1 || _toUnitOverride != defaults.$2;
  }

  (String, String) _defaultMultiUnitPair() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.volume:
        return _forward ? ('L', 'gal') : ('gal', 'L');
      case CanonicalToolId.pressure:
        return _forward ? ('kPa', 'psi') : ('psi', 'kPa');
      case CanonicalToolId.weight:
        return _forward ? ('kg', 'lb') : ('lb', 'kg');
      case CanonicalToolId.dataStorage:
        return _forward ? ('GB', 'MB') : ('MB', 'GB');
      case CanonicalToolId.energy:
        return _forward ? ('cal', 'kJ') : ('kJ', 'cal');
      default:
        return ('', '');
    }
  }

  void _resetUnitSelectionToDefaults() {
    setState(() {
      if (_isLookupTool) {
        _seedLookupDefaults();
      } else if (_isCurrencyTool) {
        _currencyFromOverride = null;
        _currencyToOverride = null;
        _seedCurrencySuggestedInput(force: true);
      } else if (_isMultiUnitTool) {
        _seedMultiUnitOverrides();
      }
    });
  }

  Future<void> _pickUnit({required bool isFrom}) async {
    final choices = _isCurrencyTool ? _currencyChoices : _multiUnitChoices;
    if (choices.isEmpty) return;

    final current = _isCurrencyTool
        ? (isFrom ? _fromCurrencyCode : _toCurrencyCode)
        : (isFrom ? _fromUnitOverride : _toUnitOverride);

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DashboardCopy.unitPickerTitle(
                          context,
                          isCurrencyTool: _isCurrencyTool,
                          isFrom: isFrom,
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _ToolModalThemePolicy.textPrimary(context),
                            ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey(
                        'tool_unit_picker_close_${widget.tool.id}_${isFrom ? 'from' : 'to'}',
                      ),
                      tooltip: DashboardCopy.unitPickerCloseTooltip(context),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  key: ValueKey(
                    'tool_unit_picker_${widget.tool.id}_${isFrom ? 'from' : 'to'}',
                  ),
                  shrinkWrap: true,
                  children: [
                    for (final u in choices)
                      ListTile(
                        key: ValueKey(
                          'tool_unit_item_${widget.tool.id}_${isFrom ? 'from' : 'to'}_${_sanitizeUnitKey(u)}',
                        ),
                        title: Text(
                          u,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _ToolModalThemePolicy.textPrimary(
                                  context,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: _isCurrencyTool
                            ? Builder(
                                builder: (_) {
                                  final symbol = _currencySymbolOrNull(u);
                                  if (symbol == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    symbol,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              _ToolModalThemePolicy.textMuted(
                                                context,
                                              ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  );
                                },
                              )
                            : null,
                        trailing: (u == current)
                            ? Icon(
                                Icons.check_rounded,
                                color: _ToolModalThemePolicy.headingTone(
                                  context,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(u),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (_isCurrencyTool) {
        final oldFrom = _fromCurrencyCode;
        final oldTo = _toCurrencyCode;
        final nextFrom = isFrom ? selected : oldFrom;
        final nextTo = isFrom ? oldTo : selected;
        _currencyFromOverride = nextFrom;
        _currencyToOverride = nextTo;
        _forward = true;
        _seedCurrencySuggestedInput(force: true);
      } else if (isFrom) {
        _fromUnitOverride = selected;
      } else {
        _toUnitOverride = selected;
      }
    });
  }

  void _showNotice(String text, UnitanaNoticeKind kind) {
    _noticeTimer?.cancel();
    setState(() {
      _noticeText = text;
      _noticeKind = kind;
    });

    _noticeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _noticeText = null;
      });
    });
  }

  Future<bool> _confirmClearHistory(BuildContext context) async {
    return showDestructiveConfirmationSheet(
      context,
      title: DashboardCopy.clearHistoryTitle(context),
      message: DashboardCopy.clearHistoryMessage(context),
      confirmLabel: DashboardCopy.clearCta(context),
    );
  }

  bool _defaultForwardFor({
    required String toolId,
    required bool preferMetric,
    required bool prefer24h,
  }) {
    // NOTE: toolId is a canonical tool id.
    // Forward direction means "left input" -> "right output".
    // For metric-preferring contexts, we default the left input to the metric unit.
    switch (toolId) {
      case 'length':
        // cm <-> ft/in
        return preferMetric;
      case 'distance':
        // km <-> mi
        return preferMetric;
      case 'speed':
        // km/h <-> mph
        return preferMetric;
      case 'pace':
        // min/km <-> min/mi
        return preferMetric;
      case 'liquids':
        // cups/oz <-> ml (metric prefers ml input)
        return !preferMetric;
      case 'area':
        // m² <-> ft²
        return preferMetric;
      case 'volume':
        // L <-> gal
        return preferMetric;
      case 'pressure':
        // kPa <-> psi
        return preferMetric;
      case 'shoe_sizes':
        // Shoe sizes are commonly entered as US first for travelers.
        // Keep the default stable (US -> EU) regardless of active reality;
        // users can swap directions if they want EU -> US.
        return false;
      case 'temperature':
        // °C <-> °F
        return preferMetric;
      case 'weight':
        // kg <-> lb
        return preferMetric;
      case 'data_storage':
        // GB <-> MB
        return true;
      case 'energy':
        // calories (kcal) <-> kJ
        return true;
      case 'time':
        // 24h <-> 12h
        return prefer24h;
      default:
        return true;
    }
  }

  bool get _isCurrencyTool =>
      widget.tool.canonicalToolId == 'currency' ||
      widget.tool.id == 'currency_convert';

  String _currencyCodeForPlace(Place? place) =>
      currencyCodeForCountryCode(place?.countryCode);

  String get _homeCurrencyCode => _currencyCodeForPlace(widget.home);
  String get _destinationCurrencyCode =>
      _currencyCodeForPlace(widget.destination);

  String get _baseFromCurrencyCode =>
      _currencyFromOverride ?? _homeCurrencyCode;
  String get _baseToCurrencyCode =>
      _currencyToOverride ?? _destinationCurrencyCode;

  String get _fromCurrencyCode =>
      _forward ? _baseFromCurrencyCode : _baseToCurrencyCode;
  String get _toCurrencyCode =>
      _forward ? _baseToCurrencyCode : _baseFromCurrencyCode;

  String _currencySymbol(String code) =>
      kCurrencySymbols[code.toUpperCase()] ?? code.toUpperCase();

  void _seedCurrencySuggestedInput({bool force = false}) {
    if (!force && _controller.text.trim().isNotEmpty) return;
    final pairRate = widget.currencyRateForPair?.call(
      _fromCurrencyCode,
      _toCurrencyCode,
    );
    final base = _currencyDisplayBaseAmount(pairRate);
    _controller.text = _fmtSeedAmount(base);
  }

  double _currencyDisplayBaseAmount(double? pairRate) {
    if (pairRate == null || pairRate <= 0) return 1;
    if (pairRate < 0.0002) return 10000;
    if (pairRate < 0.002) return 1000;
    if (pairRate < 0.02) return 100;
    if (pairRate < 0.2) return 10;
    return 1;
  }

  String _fmtSeedAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  bool _defaultCurrencyForward() {
    // When the active reality is Destination, default to converting Destination
    // currency back into Home currency.
    return widget.session.reality != DashboardReality.destination;
  }

  String get _fromUnit {
    switch (widget.tool.id) {
      case 'currency_convert':
        return _fromCurrencyCode;
      case 'distance':
        return _forward ? 'km' : 'mi';
      case 'speed':
        return _forward ? 'km/h' : 'mph';
      case 'pace':
        return _forward ? 'min/km' : 'min/mi';
      case 'temperature':
      case 'oven_temperature':
        return _forward ? '°C' : '°F';
      case 'time':
        return _forward ? '24h' : '12h';
      case 'height':
        return _forward ? 'cm' : 'ft/in';
      case 'baking':
        return _fromUnitOverride ?? (_forward ? 'cup' : 'ml');
      case 'liquids':
        return _forward ? 'oz' : 'ml';
      case 'area':
        return _forward ? 'm²' : 'ft²';
      case 'volume':
        return _fromUnitOverride ?? (_forward ? 'L' : 'gal');
      case 'pressure':
        return _fromUnitOverride ?? (_forward ? 'kPa' : 'psi');
      case 'weight':
      case 'body_weight':
        return _fromUnitOverride ?? (_forward ? 'kg' : 'lb');
      case 'data_storage':
        return _fromUnitOverride ?? (_forward ? 'GB' : 'MB');
      case 'energy':
        return _fromUnitOverride ?? (_forward ? 'cal' : 'kJ');
      default:
        return '';
    }
  }

  String get _toUnit {
    switch (widget.tool.id) {
      case 'currency_convert':
        return _toCurrencyCode;
      case 'distance':
        return _forward ? 'mi' : 'km';
      case 'speed':
        return _forward ? 'mph' : 'km/h';
      case 'pace':
        return _forward ? 'min/mi' : 'min/km';
      case 'temperature':
      case 'oven_temperature':
        return _forward ? '°F' : '°C';
      case 'time':
        return _forward ? '12h' : '24h';
      case 'height':
        return _forward ? 'ft/in' : 'cm';
      case 'baking':
        return _toUnitOverride ?? (_forward ? 'ml' : 'cup');
      case 'liquids':
        return _forward ? 'ml' : 'oz';
      case 'area':
        return _forward ? 'ft²' : 'm²';
      case 'volume':
        return _toUnitOverride ?? (_forward ? 'gal' : 'L');
      case 'pressure':
        return _toUnitOverride ?? (_forward ? 'psi' : 'kPa');
      case 'weight':
      case 'body_weight':
        return _toUnitOverride ?? (_forward ? 'lb' : 'kg');
      case 'data_storage':
        return _toUnitOverride ?? (_forward ? 'MB' : 'GB');
      case 'energy':
        return _toUnitOverride ?? (_forward ? 'kJ' : 'cal');
      default:
        return '';
    }
  }

  void _runConversion() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    if (_isCurrencyTool) {
      final normalized = input.replaceAll(',', '').trim();
      final value = double.tryParse(normalized);
      if (value == null) {
        _showNotice(
          'Invalid input, please enter a number',
          UnitanaNoticeKind.error,
        );
        return;
      }

      final rate = (widget.eurToUsd == null || widget.eurToUsd! <= 0)
          ? 1.10
          : widget.eurToUsd!;

      final from = _fromCurrencyCode;
      final to = _toCurrencyCode;

      double out;
      if (from == to) {
        out = value;
      } else {
        final pairRate = widget.currencyRateForPair?.call(from, to);
        if (pairRate != null && pairRate > 0) {
          out = value * pairRate;
        } else if (from == 'EUR' && to == 'USD') {
          out = value * rate;
        } else if (from == 'USD' && to == 'EUR') {
          out = value / rate;
        } else {
          // Deterministic fallback when pair data is unavailable.
          out = value;
        }
      }

      final record = ConversionRecord(
        toolId: widget.tool.id,
        lensId: widget.tool.lensId,
        fromUnit: from,
        toUnit: to,
        inputLabel: '${_currencySymbol(from)}${value.toStringAsFixed(2)}',
        outputLabel: '${_currencySymbol(to)}${out.toStringAsFixed(2)}',
        timestamp: DateTime.now(),
      );

      widget.session.addRecord(record);
      FocusScope.of(context).unfocus();

      setState(() {
        _resultLine = '${record.inputLabel}  →  ${record.outputLabel}';
      });
      return;
    }

    final normalizedInput = (widget.tool.id == 'baking')
        ? _normalizeBakingInput(input)
        : input;
    if (normalizedInput == null) {
      _showNotice(
        'Invalid input, please enter a number',
        UnitanaNoticeKind.error,
      );
      return;
    }

    final result = _isMultiUnitTool
        ? ToolConverters.convertWithUnits(
            toolId: widget.tool.canonicalToolId,
            fromUnit: _fromUnit,
            toUnit: _toUnit,
            input: normalizedInput,
          )
        : ToolConverters.convert(
            toolId: widget.tool.canonicalToolId,
            lensId: widget.tool.lensId,
            forward: _forward,
            input: normalizedInput,
          );

    if (result == null) {
      _showNotice(
        'Invalid input, please enter a number',
        UnitanaNoticeKind.error,
      );
      return;
    }

    final record = ConversionRecord(
      toolId: widget.tool.id,
      lensId: widget.tool.lensId,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
      inputLabel: '$input $_fromUnit',
      outputLabel: result,
      timestamp: DateTime.now(),
    );

    widget.session.addRecord(record);
    FocusScope.of(context).unfocus();

    setState(() {
      _resultLine = '${record.inputLabel}  →  ${record.outputLabel}';
    });
  }

  bool get _requiresFreeformInput {
    // Height in the imperial direction accepts inputs like 5'10".
    return (widget.tool.id == 'height' && !_forward) ||
        widget.tool.id == 'pace' ||
        widget.tool.id == 'time' ||
        widget.tool.id == 'baking';
  }

  String _toolInputHint(BuildContext context) {
    if (widget.tool.id == 'pace') {
      return DashboardCopy.paceInputHint(context);
    }
    return DashboardCopy.toolInputHint(context);
  }

  String? _toolInputCoachCopy(BuildContext context) {
    if (widget.tool.id == 'pace') {
      return DashboardCopy.paceInputCoach(context, fromUnit: _fromUnit);
    }
    if (widget.tool.id == 'baking') {
      return DashboardCopy.bakingInputCoach(context);
    }
    return null;
  }

  String? _normalizeBakingInput(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final direct = double.tryParse(cleaned);
    if (direct != null && direct.isFinite) {
      return direct.toString();
    }

    final mixedFraction = RegExp(
      r'^([+-]?\d+)\s+(\d+)\s*/\s*(\d+)$',
    ).firstMatch(cleaned);
    if (mixedFraction != null) {
      final whole = int.tryParse(mixedFraction.group(1)!);
      final numer = int.tryParse(mixedFraction.group(2)!);
      final denom = int.tryParse(mixedFraction.group(3)!);
      if (whole == null || numer == null || denom == null || denom == 0) {
        return null;
      }
      final sign = whole < 0 ? -1.0 : 1.0;
      final absWhole = whole.abs().toDouble();
      final value = sign * (absWhole + (numer / denom));
      return value.toString();
    }

    final simpleFraction = RegExp(
      r'^([+-]?\d+)\s*/\s*(\d+)$',
    ).firstMatch(cleaned);
    if (simpleFraction != null) {
      final numer = int.tryParse(simpleFraction.group(1)!);
      final denom = int.tryParse(simpleFraction.group(2)!);
      if (numer == null || denom == null || denom == 0) return null;
      final value = numer / denom;
      return value.toString();
    }
    return null;
  }

  double? _parsePaceMinutesValue(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final mmss = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(cleaned);
    if (mmss != null) {
      final min = int.parse(mmss.group(1)!);
      final sec = int.parse(mmss.group(2)!);
      return min + (sec / 60.0);
    }
    final asDouble = double.tryParse(cleaned);
    if (asDouble == null || asDouble <= 0) return null;
    return asDouble;
  }

  double? _currentPaceMinutes() {
    final fromInput = _parsePaceMinutesValue(_controller.text);
    if (fromInput != null) return fromInput;
    final latest = widget.session.latestFor(widget.tool.id);
    if (latest == null) return null;
    return _parsePaceMinutesValue(_stripKnownUnitSuffix(latest.inputLabel));
  }

  double? _currentPacePerKmMinutes() {
    if (widget.tool.id != 'pace') return null;
    final input = _currentPaceMinutes();
    if (input == null || input <= 0) return null;
    return _fromUnit == 'min/mi' ? (input / 1.609344) : input;
  }

  String _formatPace(double minutes) {
    final whole = minutes.floor();
    final sec = ((minutes - whole) * 60).round().clamp(0, 59);
    return '$whole:${sec.toString().padLeft(2, '0')}';
  }

  String _formatDurationMinutes(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double? _parseDurationMinutesValue(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final hhmmss = RegExp(
      r'^(\d{1,2}):([0-5]\d):([0-5]\d)$',
    ).firstMatch(cleaned);
    if (hhmmss != null) {
      final hh = int.parse(hhmmss.group(1)!);
      final mm = int.parse(hhmmss.group(2)!);
      final ss = int.parse(hhmmss.group(3)!);
      return (hh * 60) + mm + (ss / 60.0);
    }
    final mmss = RegExp(r'^(\d{1,3}):([0-5]\d)$').firstMatch(cleaned);
    if (mmss != null) {
      final mm = int.parse(mmss.group(1)!);
      final ss = int.parse(mmss.group(2)!);
      return mm + (ss / 60.0);
    }
    return null;
  }

  double? _parsePositiveDouble(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  String? _toolDisclaimerCopy(BuildContext context) {
    switch (widget.tool.id) {
      case 'energy':
      case 'hydration':
        return DashboardCopy.disclaimerMedical(context);
      default:
        return null;
    }
  }

  Widget _buildDisclaimerCard(
    BuildContext context, {
    required String text,
    Key? key,
  }) {
    final panelBg = _ToolModalThemePolicy.panelBgSoft(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 16,
            color: textMuted.withAlpha(220),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<({String label, double minutes})> _goalCheckpointPlan({
    required double goalDurationMinutes,
    required double goalDistanceKm,
  }) {
    const checkpoints = <double>[0.25, 0.50, 0.75, 1.0];
    return checkpoints
        .map((fraction) {
          final km = goalDistanceKm * fraction;
          final minutesAtCheckpoint = goalDurationMinutes * fraction;
          final kmLabel = km >= 10
              ? km.toStringAsFixed(1)
              : km.toStringAsFixed(2);
          return (
            label: '${(fraction * 100).round()}% • ${kmLabel}km',
            minutes: minutesAtCheckpoint,
          );
        })
        .toList(growable: false);
  }

  Widget _buildPaceInsightsCard(BuildContext context, Color accent) {
    final perKm = _currentPacePerKmMinutes();
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    if (perKm == null || perKm <= 0) {
      return const SizedBox.shrink();
    }

    final kmh = 60 / perKm;
    final mph = kmh / 1.609344;
    final perMi = perKm * 1.609344;
    final goalDuration = _parseDurationMinutesValue(
      _paceGoalTimeController.text,
    );
    final goalPerKm = (goalDuration != null && goalDuration > 0)
        ? (goalDuration / _paceGoalDistanceKm)
        : null;
    final goalPerMi = goalPerKm == null ? null : (goalPerKm * 1.609344);
    final checkpoints = goalDuration == null
        ? const <({String label, double minutes})>[]
        : _goalCheckpointPlan(
            goalDurationMinutes: goalDuration,
            goalDistanceKm: _paceGoalDistanceKm,
          );
    final runTargets = <({String label, double km})>[
      (label: '5K', km: 5.0),
      (label: '10K', km: 10.0),
      (label: 'Half', km: 21.0975),
      (label: 'Marathon', km: 42.195),
    ];
    final rowTargets = <({String label, double km})>[
      (label: '500m', km: 0.5),
      (label: '2K', km: 2.0),
      (label: '5K', km: 5.0),
      (label: '10K', km: 10.0),
    ];
    final raceTargets = _paceMode == _PaceMode.rowing ? rowTargets : runTargets;
    final builderDistanceRaw = _parsePositiveDouble(
      _paceBuilderDistanceController.text,
    );
    final builderDuration = _parseDurationMinutesValue(
      _paceBuilderTimeController.text,
    );
    final builderDistanceKm = switch (_paceBuilderDistanceUnit) {
      'km' => builderDistanceRaw,
      'mi' => builderDistanceRaw == null ? null : builderDistanceRaw * 1.609344,
      'm' => builderDistanceRaw == null ? null : builderDistanceRaw / 1000.0,
      _ => builderDistanceRaw,
    };
    final builderPerKm =
        (builderDistanceKm != null &&
            builderDistanceKm > 0 &&
            builderDuration != null &&
            builderDuration > 0)
        ? (builderDuration / builderDistanceKm)
        : null;
    final builderPerMi = builderPerKm == null
        ? null
        : (builderPerKm * 1.609344);
    final builderSplit500 = builderPerKm == null ? null : (builderPerKm / 2.0);

    return Container(
      key: const ValueKey('tool_pace_insights_card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pace Insights',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatPace(perKm)} min/km • ${_formatPace(perMi)} min/mi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${kmh.toStringAsFixed(1)} km/h • ${mph.toStringAsFixed(1)} mph',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textMuted.withAlpha(236),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_PaceMode>(
            key: const ValueKey('tool_pace_mode'),
            segments: const [
              ButtonSegment(value: _PaceMode.running, label: Text('Run')),
              ButtonSegment(value: _PaceMode.rowing, label: Text('Row')),
            ],
            selected: {_paceMode},
            onSelectionChanged: (selection) {
              final next = selection.isEmpty
                  ? _PaceMode.running
                  : selection.first;
              setState(() {
                _paceMode = next;
                if (_paceMode == _PaceMode.rowing && _paceGoalDistanceKm > 10) {
                  _paceGoalDistanceKm = 2.0;
                }
              });
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final target in raceTargets)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelBg.withAlpha(216),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: panelBorder.withAlpha(170)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Text(
                      '${target.label} ${_formatDurationMinutes(perKm * target.km)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _ToolModalThemePolicy.textPrimary(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: panelBorder.withAlpha(150)),
          const SizedBox(height: 10),
          Text(
            'Distance + Time → Pace',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('tool_pace_builder_distance'),
                  controller: _paceBuilderDistanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: _paceMode == _PaceMode.rowing ? '2000' : '5',
                    labelText: 'Distance',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final unit
                      in _paceMode == _PaceMode.rowing
                          ? const <String>['m', 'km']
                          : const <String>['km', 'mi'])
                    ChoiceChip(
                      key: ValueKey('tool_pace_builder_unit_$unit'),
                      label: Text(unit),
                      selected: _paceBuilderDistanceUnit == unit,
                      onSelected: (_) {
                        setState(() {
                          _paceBuilderDistanceUnit = unit;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('tool_pace_builder_time'),
            controller: _paceBuilderTimeController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: 'Duration (mm:ss or h:mm:ss)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (builderPerKm != null && builderPerMi != null) ...[
            const SizedBox(height: 8),
            Text(
              'Derived pace: ${_formatPace(builderPerKm)} min/km • ${_formatPace(builderPerMi)} min/mi'
              '${builderSplit500 == null ? '' : ' • ${_formatPace(builderSplit500)} /500m'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('tool_pace_builder_apply'),
                onPressed: () {
                  final minutesForFromUnit = _fromUnit == 'min/mi'
                      ? builderPerMi
                      : builderPerKm;
                  setState(() {
                    _controller.text = _formatPace(minutesForFromUnit);
                  });
                },
                icon: const Icon(Icons.input_rounded, size: 16),
                label: const Text('Use as input pace'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: panelBorder.withAlpha(150)),
          const SizedBox(height: 10),
          Text(
            'Goal Planner',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final item in const <({String label, double km})>[
                (label: '5K', km: 5.0),
                (label: '10K', km: 10.0),
                (label: 'Half', km: 21.0975),
                (label: 'Marathon', km: 42.195),
              ])
                if (_paceMode == _PaceMode.running || item.km <= 10.0)
                  ChoiceChip(
                    key: ValueKey('tool_pace_goal_dist_${item.label}'),
                    label: Text(item.label),
                    selected: _paceGoalDistanceKm == item.km,
                    onSelected: (_) {
                      setState(() {
                        _paceGoalDistanceKm = item.km;
                      });
                    },
                  ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('tool_pace_goal_input'),
            controller: _paceGoalTimeController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: 'Goal time (mm:ss or h:mm:ss)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (goalPerKm != null) ...[
            const SizedBox(height: 8),
            Text(
              _paceMode == _PaceMode.rowing
                  ? 'Required split: ${_formatPace(goalPerKm / 2.0)} /500m • ${_formatPace(goalPerKm)} min/km'
                  : 'Required pace: ${_formatPace(goalPerKm)} min/km • ${_formatPace(goalPerMi!)} min/mi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: _PaceCheckpointBarChart(
                checkpoints: checkpoints,
                accent: accent,
                textColor: _ToolModalThemePolicy.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final cp in checkpoints)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: panelBg.withAlpha(216),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: panelBorder.withAlpha(160)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Text(
                        '${cp.label} ${_formatDurationMinutes(cp.minutes)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _ToolModalThemePolicy.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Enter a goal time to see required pace and split checkpoints.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnergyPlannerCard(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    final weightRaw = _parsePositiveDouble(_energyWeightController.text);
    final weightKg = switch (_energyWeightUnit) {
      'lb' => weightRaw == null ? null : weightRaw * 0.453592,
      _ => weightRaw,
    };
    final activityFactor = switch (_energyActivity) {
      'light' => 0.95,
      'high' => 1.22,
      _ => 1.08,
    };
    final maintenance = weightKg == null
        ? null
        : (weightKg * 33.0 * activityFactor);
    final cutTarget = maintenance == null
        ? null
        : math.max(1000.0, maintenance - 350);
    final gainTarget = maintenance == null ? null : maintenance + 250;

    return Container(
      key: const ValueKey('tool_energy_planner_card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Energy Snapshot',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('tool_energy_weight_input'),
                  controller: _energyWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Body weight',
                    hintText: '70',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                key: const ValueKey('tool_energy_weight_unit_kg'),
                label: const Text('kg'),
                selected: _energyWeightUnit == 'kg',
                onSelected: (_) => setState(() {
                  _energyWeightUnit = 'kg';
                }),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const ValueKey('tool_energy_weight_unit_lb'),
                label: const Text('lb'),
                selected: _energyWeightUnit == 'lb',
                onSelected: (_) => setState(() {
                  _energyWeightUnit = 'lb';
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_light'),
                label: const Text('Light'),
                selected: _energyActivity == 'light',
                onSelected: (_) => setState(() {
                  _energyActivity = 'light';
                }),
              ),
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_moderate'),
                label: const Text('Moderate'),
                selected: _energyActivity == 'moderate',
                onSelected: (_) => setState(() {
                  _energyActivity = 'moderate';
                }),
              ),
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_high'),
                label: const Text('High'),
                selected: _energyActivity == 'high',
                onSelected: (_) => setState(() {
                  _energyActivity = 'high';
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (maintenance != null && cutTarget != null && gainTarget != null)
            Text(
              'Maintain: ${maintenance.round()} cal (${(maintenance * 4.184).round()} kJ)\n'
              'Cut: ${cutTarget.round()} cal • Gain: ${gainTarget.round()} cal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              'Enter body weight to estimate a rough daily calorie target.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _stripKnownUnitSuffix(String label) {
    var working = label.trim();
    // Strip common currency symbol prefixes so currency history entries can
    // be edited back into a raw numeric input.
    working = working.replaceFirst(RegExp(r'^[\$€£¥]\s*'), '');
    // Remove thousands separators for a cleaner edit experience.
    working = working.replaceAll(',', '');

    const suffixes = <String>[
      'eu',
      'us',
      'us m',
      'cm',
      'ft/in',
      // Weight
      'kg',
      'lb',
      'lbs',
      'g',
      'st',
      'km',
      'mi',
      'km/h',
      'mph',
      'min/km',
      'min/mi',
      '°c',
      '°f',
      '24h',
      '12h',
      'ml',
      'cup',
      'oz',
      'm²',
      'm2',
      'ft²',
      'ft2',
      'usd',
      'eur',
      'b',
      'kb',
      'mb',
      'gb',
      'tb',
      'kcal',
      'cal',
      'kj',
    ];

    final lower = working.toLowerCase();
    for (final s in suffixes) {
      final withSpace = ' $s';
      if (lower.endsWith(withSpace)) {
        return working.substring(0, working.length - withSpace.length).trim();
      }
    }
    return working.trim();
  }

  String _trimTrailingZerosForClipboard(String value) {
    final s = value.trim();
    final m = RegExp(r'^(-?\d+)(?:\.(\d+))?$').firstMatch(s);
    if (m == null) return s;

    final whole = m.group(1) ?? s;
    final frac = m.group(2);
    if (frac == null) return whole;

    if (RegExp(r'^0+$').hasMatch(frac)) return whole;

    final trimmed = frac.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return whole;
    return '$whole.$trimmed';
  }

  String _lookupReferenceLabel(_LookupEntry row) {
    return switch (widget.tool.canonicalToolId) {
      CanonicalToolId.shoeSizes => row.valuesBySystem['JP (cm)'] ?? row.label,
      CanonicalToolId.clothingSizes => row.label,
      CanonicalToolId.paperSizes => row.label,
      CanonicalToolId.mattressSizes => row.label,
      _ => row.label,
    };
  }

  String _lookupReferenceHeader() {
    return switch (widget.tool.canonicalToolId) {
      CanonicalToolId.shoeSizes => 'Foot (cm)',
      CanonicalToolId.clothingSizes => 'Category',
      _ => 'Reference',
    };
  }

  String _lookupMatrixHeaderLabel(String system) {
    if (widget.tool.canonicalToolId != CanonicalToolId.shoeSizes) {
      return system;
    }
    return switch (system) {
      'US Men' => 'US M',
      'US Women' => 'US W',
      _ => system,
    };
  }

  List<String> _lookupMatrixValueSystems() {
    final systems = _lookupSystemsForTool();
    return widget.tool.canonicalToolId == CanonicalToolId.shoeSizes
        ? systems.where((s) => s != 'JP (cm)').toList(growable: false)
        : systems;
  }

  Widget _buildLookupBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    final selectedTone = _ToolModalThemePolicy.dangerTone(context);
    final row = _activeLookupEntry();
    final from = _lookupFromSystem;
    final to = _lookupToSystem;
    if (row == null || from == null || to == null) {
      return const SizedBox.shrink();
    }

    Future<void> copyLookupCell({
      required String value,
      required String label,
      _LookupEntry? row,
      String? system,
    }) async {
      final copiedLabel = DashboardCopy.copiedNotice(context, label);
      final normalized = value.trim();
      await Clipboard.setData(ClipboardData(text: normalized));
      if (row != null &&
          system != null &&
          (widget.tool.canonicalToolId == CanonicalToolId.shoeSizes ||
              widget.tool.canonicalToolId == CanonicalToolId.clothingSizes ||
              widget.tool.canonicalToolId == CanonicalToolId.paperSizes ||
              widget.tool.canonicalToolId == CanonicalToolId.mattressSizes)) {
        await widget.session.setMatrixWidgetSelection(
          toolId: widget.tool.id,
          rowKey: row.keyId,
          system: system,
          value: normalized,
          referenceLabel: _lookupReferenceLabel(row),
          primaryLabel: normalized,
          secondaryLabel: '$system • ${_lookupReferenceLabel(row)}',
        );
      }
      if (!mounted) return;
      _showNotice(copiedLabel, UnitanaNoticeKind.info);
    }

    if (_isFullMatrixLookupTool) {
      final systems = _lookupMatrixValueSystems();
      final rows = _lookupEntriesForTool();
      const pageSize = 2;
      final pageCount = (systems.length / pageSize).ceil().clamp(1, 999);
      final pageIndex = _lookupMatrixPageIndex.clamp(0, pageCount - 1);
      final pageStart = pageIndex * pageSize;
      final visibleSystems = systems
          .skip(pageStart)
          .take(pageSize)
          .toList(growable: false);
      final visibleLabel = visibleSystems.join(' • ');

      Widget headerCell(
        String text, {
        required double width,
        required Alignment alignment,
      }) {
        return SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Align(
              alignment: alignment,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textMuted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }

      Widget valueCell({
        required String keySuffix,
        required String text,
        required String copyLabel,
        required String rowKey,
        required _LookupEntry row,
        required String system,
        required double width,
        required bool selected,
        Alignment alignment = Alignment.center,
      }) {
        return SizedBox(
          width: width,
          child: InkWell(
            key: ValueKey(
              'tool_lookup_matrix_cell_${widget.tool.id}_$keySuffix',
            ),
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              setState(() {
                _lookupEntryKey = rowKey;
              });
              await copyLookupCell(
                value: text,
                label: copyLabel,
                row: row,
                system: system,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Align(
                alignment: alignment,
                child: Text(
                  text,
                  textAlign: alignment == Alignment.centerLeft
                      ? TextAlign.left
                      : TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textPrimary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        key: ValueKey('tool_lookup_scroll_${widget.tool.id}'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DashboardCopy.lookupSizeMatrix(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: headingTone,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DashboardCopy.lookupMatrixHelp(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isClothingLookupTool) ...[
              const SizedBox(height: 8),
              Container(
                key: const ValueKey('tool_lookup_disclaimer_clothing_sizes'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: panelBorder),
                ),
                child: Text(
                  'Sizes vary by brand and cut. Use this as a reference and check retailer size charts.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  key: ValueKey('tool_lookup_matrix_prev_${widget.tool.id}'),
                  onPressed: pageIndex > 0
                      ? () {
                          setState(() {
                            _lookupMatrixPageIndex = pageIndex - 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    'Page ${pageIndex + 1} / $pageCount • $visibleLabel',
                    key: ValueKey(
                      'tool_lookup_matrix_page_label_${widget.tool.id}',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('tool_lookup_matrix_next_${widget.tool.id}'),
                  onPressed: pageIndex < pageCount - 1
                      ? () {
                          setState(() {
                            _lookupMatrixPageIndex = pageIndex + 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Text(
              'Swipe left/right to change table pages.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                key: ValueKey('tool_lookup_matrix_${widget.tool.id}'),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: panelBorder),
                ),
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity <= -200 && pageIndex < pageCount - 1) {
                      setState(() {
                        _lookupMatrixPageIndex = pageIndex + 1;
                      });
                    } else if (velocity >= 200 && pageIndex > 0) {
                      setState(() {
                        _lookupMatrixPageIndex = pageIndex - 1;
                      });
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sizeColWidth = _isClothingLookupTool ? 150.0 : 94.0;
                      final valueColWidth =
                          ((constraints.maxWidth - sizeColWidth) /
                                  visibleSystems.length)
                              .clamp(98.0, 170.0);
                      final fullWidth =
                          sizeColWidth +
                          (visibleSystems.length * valueColWidth);

                      return SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                headerCell(
                                  _lookupReferenceHeader(),
                                  width: sizeColWidth,
                                  alignment: Alignment.centerLeft,
                                ),
                                for (final system in visibleSystems)
                                  headerCell(
                                    _lookupMatrixHeaderLabel(system),
                                    width: valueColWidth,
                                    alignment: Alignment.center,
                                  ),
                              ],
                            ),
                            Divider(height: 1, color: textMuted.withAlpha(90)),
                            Expanded(
                              child: ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, i) {
                                  final entry = rows[i];
                                  final selected =
                                      entry.keyId == _lookupEntryKey;
                                  return Column(
                                    children: [
                                      Container(
                                        key: ValueKey(
                                          'tool_lookup_matrix_row_${widget.tool.id}_${entry.keyId}',
                                        ),
                                        width: fullWidth,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? accent.withAlpha(36)
                                              : Colors.transparent,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: sizeColWidth,
                                              child: InkWell(
                                                key: ValueKey(
                                                  'tool_lookup_matrix_size_${widget.tool.id}_${entry.keyId}',
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () {
                                                  setState(() {
                                                    _lookupEntryKey =
                                                        entry.keyId;
                                                  });
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 8,
                                                      ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      _lookupReferenceLabel(
                                                        entry,
                                                      ),
                                                      maxLines:
                                                          _isClothingLookupTool
                                                          ? 2
                                                          : 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: selected
                                                                ? selectedTone
                                                                : textPrimary,
                                                            fontWeight: selected
                                                                ? FontWeight
                                                                      .w800
                                                                : FontWeight
                                                                      .w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            for (final system in visibleSystems)
                                              valueCell(
                                                keySuffix:
                                                    '${entry.keyId}_${_sanitizeUnitKey(system)}',
                                                text: _lookupValue(
                                                  row: entry,
                                                  system: system,
                                                ),
                                                copyLabel: '$system value',
                                                rowKey: entry.keyId,
                                                row: entry,
                                                system: system,
                                                width: valueColWidth,
                                                selected: selected,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_isClothingLookupTool &&
                                          entry.note != null &&
                                          entry.note!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            8,
                                            0,
                                            8,
                                            8,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              entry.note!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: textMuted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (i != rows.length - 1)
                                        Divider(
                                          height: 1,
                                          color: textMuted.withAlpha(70),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final fromValue = _lookupValue(row: row, system: from);
    final toValue = _lookupValue(row: row, system: to);
    final rows = _lookupEntriesForTool();
    final idx = rows.indexWhere((r) => r.keyId == row.keyId);
    final proximityRows = <_LookupEntry>[
      if (idx > 0) rows[idx - 1],
      row,
      if (idx >= 0 && idx < rows.length - 1) rows[idx + 1],
    ];

    Widget matrixHeaderCell(String text, {required Alignment alignment}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Align(
            alignment: alignment,
            child: Text(
              text,
              textAlign: alignment == Alignment.centerLeft
                  ? TextAlign.left
                  : TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    Widget matrixValueCell({
      required String keySuffix,
      required String text,
      required bool isSelected,
      required String copyLabel,
      required String system,
      required _LookupEntry rowEntry,
      Alignment alignment = Alignment.center,
    }) {
      return Expanded(
        child: InkWell(
          key: ValueKey('tool_lookup_matrix_cell_${widget.tool.id}_$keySuffix'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => copyLookupCell(
            value: text,
            label: copyLabel,
            row: rowEntry,
            system: system,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Align(
              alignment: alignment,
              child: Text(
                text,
                textAlign: alignment == Alignment.centerLeft
                    ? TextAlign.left
                    : TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      key: ValueKey('tool_lookup_scroll_${widget.tool.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: ValueKey('tool_lookup_from_${widget.tool.id}'),
                onPressed: () => _pickLookupSystem(isFrom: true),
                child: Text(DashboardCopy.lookupFromLabel(context, from)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: ValueKey('tool_lookup_swap_${widget.tool.id}'),
              onPressed: _swapLookupSystems,
              child: const Icon(Icons.swap_horiz_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: ValueKey('tool_lookup_to_${widget.tool.id}'),
                onPressed: () => _pickLookupSystem(isFrom: false),
                child: Text(DashboardCopy.lookupToLabel(context, to)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: ValueKey('tool_lookup_size_${widget.tool.id}'),
          onPressed: _pickLookupEntry,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(DashboardCopy.lookupSizeLabel(context, row.label)),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: ValueKey('tool_units_reset_${widget.tool.id}'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: _hasCustomUnitSelection
                ? _resetUnitSelectionToDefaults
                : null,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(DashboardCopy.lookupResetDefaults(context)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: ValueKey('tool_lookup_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: _TerminalLine(
            prompt: '>',
            input: '$from: $fromValue',
            output: '$to: $toValue',
            emphasize: true,
            arrowColor: accent,
          ),
        ),
        if (row.note != null) ...[
          const SizedBox(height: 8),
          Text(
            row.approximate
                ? DashboardCopy.lookupApproximate(context, row.note!)
                : row.note!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (proximityRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            DashboardCopy.lookupSizeMatrix(context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: headingTone,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DashboardCopy.lookupMatrixHelp(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: ValueKey('tool_lookup_matrix_${widget.tool.id}'),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: panelBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    matrixHeaderCell(
                      _lookupReferenceHeader(),
                      alignment: Alignment.centerLeft,
                    ),
                    matrixHeaderCell(from, alignment: Alignment.center),
                    matrixHeaderCell(to, alignment: Alignment.center),
                  ],
                ),
                Divider(height: 1, color: textMuted.withAlpha(90)),
                for (var i = 0; i < proximityRows.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final n = proximityRows[i];
                      final isSelected = n.keyId == row.keyId;
                      return Container(
                        key: ValueKey(
                          'tool_lookup_matrix_row_${widget.tool.id}_${n.keyId}',
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withAlpha(36)
                              : Colors.transparent,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: accent.withAlpha(220),
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                key: ValueKey(
                                  'tool_lookup_matrix_size_${widget.tool.id}_${n.keyId}',
                                ),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _lookupEntryKey = n.keyId;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 9,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _lookupReferenceLabel(n),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? selectedTone
                                                : textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            matrixValueCell(
                              keySuffix: '${n.keyId}_from',
                              text: _lookupValue(row: n, system: from),
                              isSelected: isSelected,
                              copyLabel: '$from value',
                              system: from,
                              rowEntry: n,
                            ),
                            matrixValueCell(
                              keySuffix: '${n.keyId}_to',
                              text: _lookupValue(row: n, system: to),
                              isSelected: isSelected,
                              copyLabel: '$to value',
                              system: to,
                              rowEntry: n,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (i != proximityRows.length - 1)
                    Divider(height: 1, color: textMuted.withAlpha(70)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<TimeZoneOption> _timeZoneOptions() {
    return TimeZoneCatalog.options(
      home: widget.home,
      destination: widget.destination,
    );
  }

  static const Map<String, List<String>> _tzAbbrevAliases =
      <String, List<String>>{
        'UTC': <String>['UTC'],
        'GMT': <String>['UTC', 'Europe/London'],
        'EST': <String>['America/New_York'],
        'EDT': <String>['America/New_York'],
        'CST': <String>['America/Chicago'],
        'CDT': <String>['America/Chicago'],
        'MST': <String>['America/Denver'],
        'MDT': <String>['America/Denver'],
        'PST': <String>['America/Los_Angeles'],
        'PDT': <String>['America/Los_Angeles'],
        'CET': <String>['Europe/Paris', 'Europe/Berlin', 'Europe/Madrid'],
        'CEST': <String>['Europe/Paris', 'Europe/Berlin', 'Europe/Madrid'],
        'IST': <String>['Asia/Kolkata'],
        'JST': <String>['Asia/Tokyo'],
      };

  List<TimeZoneCityOption> _featuredCityOptions({
    required List<TimeZoneCityOption> cityOptions,
  }) {
    if (cityOptions.isEmpty) return const <TimeZoneCityOption>[];
    return TimeZoneCatalog.mainstreamCityOptionsFromAll(
      all: cityOptions,
      home: widget.home,
      destination: widget.destination,
      limit: 24,
    );
  }

  List<String> _aliasZonesForQuery(String rawQuery) {
    final token = rawQuery.trim().toUpperCase();
    return _tzAbbrevAliases[token] ?? const <String>[];
  }

  List<TimeZoneCityOption> _searchCityOptions({
    required String rawQuery,
    required List<TimeZoneCityOption> featured,
    required List<CityPickerEngineEntry<TimeZoneCityOption>> allEntries,
    required List<CityPickerEngineEntry<TimeZoneCityOption>> featuredEntries,
  }) {
    final sw = PickerPerfTrace.start('time_city_filter');
    final normalized = CityPickerEngine.normalizeQuery(rawQuery);
    if (normalized.isEmpty) {
      PickerPerfTrace.logElapsed(
        'time_city_filter',
        sw,
        extra: 'query=empty results=${featured.length}',
      );
      return featured;
    }
    final aliasZones = _aliasZonesForQuery(rawQuery).toSet();
    final preferredZones = <String>{
      if (widget.home != null) widget.home!.timeZoneId,
      if (widget.destination != null) widget.destination!.timeZoneId,
    };
    final sourceEntries = normalized.length < 3 ? featuredEntries : allEntries;
    final out = CityPickerEngine.searchEntries(
      entries: sourceEntries,
      queryRaw: rawQuery,
      preferredTimeZoneIds: preferredZones,
      aliasTimeZoneIds: aliasZones,
      maxCandidates: 260,
      maxResults: 40,
      shortQueryAllowsTimeZonePrefix: true,
      dedupeByTimeZone: true,
      dedupeByCityCountry: true,
      allowTimeZoneOnlyMatches: true,
      deprioritizeTimeZoneOnlyMatches: true,
    ).map((entry) => entry.value).toList(growable: false);
    PickerPerfTrace.logElapsed(
      'time_city_filter',
      sw,
      extra: 'query="$normalized" results=${out.length}',
      minMs: 6,
    );
    return out;
  }

  List<TimeZoneOption> _searchZoneOptions({
    required String rawQuery,
    required List<CityPickerEngineEntry<TimeZoneOption>> entries,
  }) {
    final sw = PickerPerfTrace.start('time_zone_filter');
    final query = rawQuery.trim();
    if (query.isEmpty) {
      PickerPerfTrace.logElapsed('time_zone_filter', sw, extra: 'query=empty');
      return const <TimeZoneOption>[];
    }
    final normalized = CityPickerEngine.normalizeQuery(query);
    final aliasZones = _aliasZonesForQuery(query).toSet();
    final preferredZones = <String>{
      if (widget.home != null) widget.home!.timeZoneId,
      if (widget.destination != null) widget.destination!.timeZoneId,
    };
    final out = CityPickerEngine.searchEntries(
      entries: entries,
      queryRaw: query,
      preferredTimeZoneIds: preferredZones,
      aliasTimeZoneIds: aliasZones,
      maxCandidates: 180,
      maxResults: 12,
      shortQueryAllowsTimeZonePrefix: true,
      dedupeByTimeZone: false,
      allowTimeZoneOnlyMatches: true,
      deprioritizeTimeZoneOnlyMatches: false,
    ).map((entry) => entry.value).toList(growable: false);
    PickerPerfTrace.logElapsed(
      'time_zone_filter',
      sw,
      extra: 'query="$normalized" results=${out.length}',
      minMs: 6,
    );
    return out;
  }

  void _seedTimeToolDefaults() {
    final home = widget.home;
    final destination = widget.destination;
    final options = _timeZoneOptions();
    final fallback = options.isEmpty ? 'UTC' : options.first.id;

    if (_isJetLagDeltaTool) {
      // Jet Lag is a travel-planning tool. Keep defaults stable as
      // Home -> Destination regardless of the active hero reality.
      _timeFromZoneId = home?.timeZoneId ?? fallback;
      _timeToZoneId = destination?.timeZoneId ?? fallback;
    } else if (widget.session.reality == DashboardReality.destination) {
      _timeFromZoneId = destination?.timeZoneId ?? fallback;
      _timeToZoneId = home?.timeZoneId ?? fallback;
    } else {
      _timeFromZoneId = home?.timeZoneId ?? fallback;
      _timeToZoneId = destination?.timeZoneId ?? fallback;
    }

    if (_timeFromZoneId == _timeToZoneId) {
      _timeToZoneId = options.where((o) => o.id != _timeFromZoneId).isNotEmpty
          ? options.firstWhere((o) => o.id != _timeFromZoneId).id
          : 'UTC';
    }
    _timeFromDisplayLabel = _displayLabelForZone(_timeFromZoneId!, options);
    _timeToDisplayLabel = _displayLabelForZone(_timeToZoneId!, options);
  }

  String _displayLabelForZone(String zoneId, List<TimeZoneOption> options) {
    final match = options.where((o) => o.id == zoneId);
    if (match.isNotEmpty) return match.first.label;
    return zoneId;
  }

  void _swapTimeZones() {
    setState(() {
      final oldFrom = _timeFromZoneId;
      final tmp = _timeFromZoneId;
      _timeFromZoneId = _timeToZoneId;
      _timeToZoneId = tmp;
      final tmpLabel = _timeFromDisplayLabel;
      _timeFromDisplayLabel = _timeToDisplayLabel;
      _timeToDisplayLabel = tmpLabel;
      _jetLagOverlapExpanded = false;
      if (_isTimeZoneConverterTool &&
          oldFrom != null &&
          _timeFromZoneId != null) {
        _rebaseTimeConverterInput(
          oldFromZoneId: oldFrom,
          newFromZoneId: _timeFromZoneId!,
        );
      }
    });
  }

  void _seedTimeConverterInput() {
    final fromId = _timeFromZoneId;
    if (fromId == null) return;
    final nowLocal = TimezoneUtils.nowInZone(fromId).local;
    _timeConvertController.text = _formatLocalDateTime(nowLocal);
  }

  String _formatLocalDateTime(DateTime dt) {
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  DateTime? _parseLocalDateTime(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2}):(\d{2})$',
    ).firstMatch(trimmed);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final dt = DateTime(year, month, day, hour, minute);
    if (dt.year != year ||
        dt.month != month ||
        dt.day != day ||
        dt.hour != hour ||
        dt.minute != minute) {
      return null;
    }
    return dt;
  }

  void _rebaseTimeConverterInput({
    required String oldFromZoneId,
    required String newFromZoneId,
  }) {
    final parsed = _parseLocalDateTime(_timeConvertController.text);
    if (parsed == null) {
      _seedTimeConverterInput();
      return;
    }
    final utc = TimezoneUtils.localToUtc(oldFromZoneId, parsed);
    final rebased = TimezoneUtils.nowInZone(newFromZoneId, nowUtc: utc).local;
    _timeConvertController.text = _formatLocalDateTime(rebased);
  }

  void _runTimeZoneConversion() {
    final fromId = _timeFromZoneId;
    final toId = _timeToZoneId;
    if (fromId == null || toId == null) return;

    final localInput = _parseLocalDateTime(_timeConvertController.text);
    if (localInput == null) {
      _showNotice(
        DashboardCopy.timeConverterInputError(context),
        UnitanaNoticeKind.error,
      );
      return;
    }

    final utc = TimezoneUtils.localToUtc(fromId, localInput);
    final toLocal = TimezoneUtils.nowInZone(toId, nowUtc: utc).local;
    final use24h = widget.prefer24h;
    final outputClock = use24h
        ? TimezoneUtils.formatClock(
            ZoneTime(local: toLocal, offsetHours: 0, abbreviation: ''),
            use24h: true,
          )
        : TimezoneUtils.formatClock(
            ZoneTime(local: toLocal, offsetHours: 0, abbreviation: ''),
            use24h: false,
          );
    final outputDate = _formatLocalDateTime(
      DateTime(
        toLocal.year,
        toLocal.month,
        toLocal.day,
        toLocal.hour,
        toLocal.minute,
      ),
    ).substring(0, 10);
    final outputLabel = '$outputDate $outputClock';
    final inputLabel = _formatLocalDateTime(localInput);

    final record = ConversionRecord(
      toolId: widget.tool.id,
      lensId: widget.tool.lensId,
      fromUnit: fromId,
      toUnit: toId,
      inputLabel: '$inputLabel ($fromId)',
      outputLabel: '$outputLabel ($toId)',
      timestamp: DateTime.now(),
    );
    widget.session.addRecord(record);
    FocusScope.of(context).unfocus();
    setState(() {
      _resultLine = '${record.inputLabel}  →  ${record.outputLabel}';
    });
  }

  Future<void> _pickTimeZone({required bool isFrom}) async {
    final openSw = PickerPerfTrace.start(
      'time_picker_open_${isFrom ? 'from' : 'to'}',
    );
    final zoneOptions = _timeZoneOptions();
    final allCityOptions = TimeZoneCatalog.cityOptions(
      home: widget.home,
      destination: widget.destination,
    );
    final featuredCityOptions = _featuredCityOptions(
      cityOptions: allCityOptions,
    );
    final allCityEntries = CityPickerEngine.sortByBaseScore(
      CityPickerEngine.buildEntries<TimeZoneCityOption>(
        items: allCityOptions,
        keyOf: (o) => o.key,
        cityNameOf: (o) => o.label,
        countryCodeOf: (o) => o.countryCode,
        countryNameOf: (o) => o.countryCode,
        timeZoneIdOf: (o) => o.timeZoneId,
        extraSearchTermsOf: (o) => <String>[o.subtitle],
        mainstreamCountryBonus: 70,
      ),
    );
    final cityEntryByKey = <String, CityPickerEngineEntry<TimeZoneCityOption>>{
      for (final entry in allCityEntries) entry.key: entry,
    };
    final featuredCityEntries = featuredCityOptions
        .map((o) => cityEntryByKey[o.key])
        .whereType<CityPickerEngineEntry<TimeZoneCityOption>>()
        .toList(growable: false);
    final zoneEntries = CityPickerEngine.sortByBaseScore(
      CityPickerEngine.buildEntries<TimeZoneOption>(
        items: zoneOptions,
        keyOf: (o) => o.id,
        cityNameOf: (o) => o.label,
        countryCodeOf: (_) => '',
        countryNameOf: (_) => '',
        timeZoneIdOf: (o) => o.id,
        extraSearchTermsOf: (o) => <String>[o.subtitle ?? '', o.id],
        mainstreamCountryBonus: 0,
      ),
    );
    PickerPerfTrace.logElapsed(
      'time_picker_catalog_ready_${isFrom ? 'from' : 'to'}',
      openSw,
      extra:
          'zones=${zoneOptions.length} cities=${allCityOptions.length} featured=${featuredCityOptions.length}',
      minMs: 2,
    );
    if (zoneOptions.isEmpty) return;
    final currentLabel = isFrom ? _timeFromDisplayLabel : _timeToDisplayLabel;
    Timer? searchDebounce;
    var modalActive = true;
    var liveQuery = '';
    var appliedQuery = '';
    var firstBuildLogged = false;
    final selected =
        await showModalBottomSheet<_TimeZonePickerSelection>(
          context: context,
          showDragHandle: true,
          builder: (context) => StatefulBuilder(
            builder: (context, setModalState) {
              if (!firstBuildLogged) {
                firstBuildLogged = true;
                PickerPerfTrace.logElapsed(
                  'time_picker_first_build_${isFrom ? 'from' : 'to'}',
                  openSw,
                  extra: 'initialQuery="${appliedQuery.trim()}"',
                );
              }
              final filteredCity = _searchCityOptions(
                rawQuery: appliedQuery,
                featured: featuredCityOptions,
                allEntries: allCityEntries,
                featuredEntries: featuredCityEntries,
              );
              final filteredZone = _searchZoneOptions(
                rawQuery: appliedQuery,
                entries: zoneEntries,
              );
              final isSearching = liveQuery.trim() != appliedQuery.trim();
              final currentZoneId = isFrom ? _timeFromZoneId : _timeToZoneId;
              final selectedCityKey =
                  filteredCity
                      .where((o) => o.label == currentLabel)
                      .map((o) => o.key)
                      .cast<String?>()
                      .firstWhere((k) => k != null, orElse: () => null) ??
                  filteredCity
                      .where((o) => o.timeZoneId == currentZoneId)
                      .map((o) => o.key)
                      .cast<String?>()
                      .firstWhere((k) => k != null, orElse: () => null);
              final hasSelectedCityRow = filteredCity.any(
                (o) => o.key == selectedCityKey,
              );
              return SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: TextField(
                          key: ValueKey(
                            'tool_time_zone_search_${isFrom ? 'from' : 'to'}',
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              liveQuery = value;
                            });
                            searchDebounce?.cancel();
                            searchDebounce = Timer(
                              const Duration(milliseconds: 110),
                              () {
                                if (!mounted || !modalActive) return;
                                setModalState(() {
                                  appliedQuery = value;
                                });
                              },
                            );
                          },
                          decoration: InputDecoration(
                            hintText:
                                DashboardCopy.timePickerExpandedSearchHint(
                                  context,
                                ),
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (isSearching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DashboardCopy.timePickerSearching(context),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _ToolModalThemePolicy.textMuted(
                                        context,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _TimeZoneQuickChip(
                              label: 'EST',
                              detail: DashboardCopy.timePickerQuickChipDetail(
                                context,
                                'EST',
                              ),
                              onTap: () => Navigator.of(context).pop((
                                zoneId: 'America/New_York',
                                displayLabel: _displayLabelForZone(
                                  'America/New_York',
                                  zoneOptions,
                                ),
                              )),
                            ),
                            _TimeZoneQuickChip(
                              label: 'CST',
                              detail: DashboardCopy.timePickerQuickChipDetail(
                                context,
                                'CST',
                              ),
                              onTap: () => Navigator.of(context).pop((
                                zoneId: 'America/Chicago',
                                displayLabel: _displayLabelForZone(
                                  'America/Chicago',
                                  zoneOptions,
                                ),
                              )),
                            ),
                            _TimeZoneQuickChip(
                              label: 'PST',
                              detail: DashboardCopy.timePickerQuickChipDetail(
                                context,
                                'PST',
                              ),
                              onTap: () => Navigator.of(context).pop((
                                zoneId: 'America/Los_Angeles',
                                displayLabel: _displayLabelForZone(
                                  'America/Los_Angeles',
                                  zoneOptions,
                                ),
                              )),
                            ),
                            _TimeZoneQuickChip(
                              label: 'UTC',
                              detail: DashboardCopy.timePickerQuickChipDetail(
                                context,
                                'UTC',
                              ),
                              onTap: () => Navigator.of(context).pop((
                                zoneId: 'UTC',
                                displayLabel: _displayLabelForZone(
                                  'UTC',
                                  zoneOptions,
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                              child: Text(
                                DashboardCopy.timePickerPrimaryHeader(
                                  context,
                                  hasQuery: appliedQuery.trim().isNotEmpty,
                                ),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: _ToolModalThemePolicy.textMuted(
                                        context,
                                        alpha: 232,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            for (final option in filteredCity)
                              Builder(
                                builder: (context) {
                                  final isSelected =
                                      option.key == selectedCityKey;
                                  return ListTile(
                                    key: ValueKey(
                                      'tool_time_city_item_${isFrom ? 'from' : 'to'}_${_sanitizeUnitKey(option.key)}',
                                    ),
                                    title: Text(
                                      [
                                            CityLabelUtils.countryFlag(
                                              option.countryCode,
                                            ),
                                            CityLabelUtils.cleanCityName(
                                              option.label,
                                            ),
                                          ]
                                          .where((part) => part.isNotEmpty)
                                          .join(' '),
                                    ),
                                    subtitle: Text(
                                      option.subtitle == option.timeZoneId
                                          ? option.timeZoneId
                                          : '${option.subtitle} · ${option.timeZoneId}',
                                    ),
                                    selected: isSelected,
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color:
                                                _ToolModalThemePolicy.headingTone(
                                                  context,
                                                ).withAlpha(238),
                                          )
                                        : null,
                                    onTap: () => Navigator.of(context).pop((
                                      zoneId: option.timeZoneId,
                                      displayLabel:
                                          CityLabelUtils.cleanCityName(
                                            option.label,
                                          ),
                                    )),
                                  );
                                },
                              ),
                            if (filteredCity.isEmpty && filteredZone.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  6,
                                ),
                                child: Text(
                                  DashboardCopy.timePickerNoMatchesHint(
                                    context,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: _ToolModalThemePolicy.textMuted(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            if (filteredZone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  2,
                                  16,
                                  6,
                                ),
                                child: Text(
                                  DashboardCopy.timePickerDirectZonesHeader(
                                    context,
                                  ),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: _ToolModalThemePolicy.textMuted(
                                          context,
                                          alpha: 232,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              for (final option in filteredZone)
                                Builder(
                                  builder: (context) {
                                    final isSelected =
                                        !hasSelectedCityRow &&
                                        option.id == currentZoneId;
                                    return ListTile(
                                      key: ValueKey(
                                        'tool_time_zone_item_${isFrom ? 'from' : 'to'}_${_sanitizeUnitKey(option.id)}',
                                      ),
                                      title: Text(option.label),
                                      subtitle: Text(
                                        option.subtitle ?? option.id,
                                      ),
                                      selected: isSelected,
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_rounded,
                                              color:
                                                  _ToolModalThemePolicy.headingTone(
                                                    context,
                                                  ).withAlpha(238),
                                            )
                                          : null,
                                      onTap: () => Navigator.of(context).pop((
                                        zoneId: option.id,
                                        displayLabel: option.label,
                                      )),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).whenComplete(() {
          modalActive = false;
          searchDebounce?.cancel();
        });
    PickerPerfTrace.logElapsed(
      'time_picker_closed_${isFrom ? 'from' : 'to'}',
      openSw,
      extra: selected == null ? 'dismissed' : 'selected=${selected.zoneId}',
    );
    if (selected == null || !mounted) return;
    final previousFrom = _timeFromZoneId;
    setState(() {
      final selectedId = selected.zoneId;
      if (isFrom) {
        _timeFromZoneId = selectedId;
        _timeFromDisplayLabel = selected.displayLabel;
      } else {
        _timeToZoneId = selectedId;
        _timeToDisplayLabel = selected.displayLabel;
      }
      if (_timeFromZoneId == _timeToZoneId) {
        final alt = zoneOptions
            .firstWhere(
              (o) => o.id != selectedId,
              orElse: () => zoneOptions.first,
            )
            .id;
        if (isFrom) {
          _timeToZoneId = alt;
          _timeToDisplayLabel = _displayLabelForZone(alt, zoneOptions);
        } else {
          _timeFromZoneId = alt;
          _timeFromDisplayLabel = _displayLabelForZone(alt, zoneOptions);
        }
      }
      _jetLagOverlapExpanded = false;
      if (_isTimeZoneConverterTool &&
          isFrom &&
          previousFrom != null &&
          _timeFromZoneId != null) {
        _rebaseTimeConverterInput(
          oldFromZoneId: previousFrom,
          newFromZoneId: _timeFromZoneId!,
        );
      }
    });
  }

  Widget _buildTimeToolBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    final infoTone = _ToolModalThemePolicy.infoTone(context);
    final warningTone = _ToolModalThemePolicy.warningTone(context);

    final options = _timeZoneOptions();
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    _timeFromZoneId ??= options.first.id;
    _timeToZoneId ??= options.length > 1 ? options[1].id : 'UTC';
    if (_timeFromZoneId == _timeToZoneId) {
      _timeToZoneId = options
          .firstWhere(
            (o) => o.id != _timeFromZoneId,
            orElse: () => options.first,
          )
          .id;
    }

    final fromId = _timeFromZoneId!;
    final toId = _timeToZoneId!;
    String labelFor(String id) => options
        .firstWhere(
          (o) => o.id == id,
          orElse: () => (id: id, label: id, subtitle: null),
        )
        .label;
    final fromDisplayLabel = _timeFromDisplayLabel ?? labelFor(fromId);
    final toDisplayLabel = _timeToDisplayLabel ?? labelFor(toId);

    final nowUtc = DateTime.now().toUtc();
    final fromNow = TimezoneUtils.nowInZone(fromId, nowUtc: nowUtc);
    final toNow = TimezoneUtils.nowInZone(toId, nowUtc: nowUtc);
    final jetLagPlan = JetLagPlanner.planFromZoneTimes(
      fromNow: fromNow,
      toNow: toNow,
    );

    String clock(ZoneTime zt, {required bool use24h}) {
      return TimezoneUtils.formatClock(zt, use24h: use24h);
    }

    String zoneMeta(ZoneTime zt) {
      final minutes = zt.offsetMinutes;
      final sign = minutes >= 0 ? '+' : '-';
      final abs = minutes.abs();
      final hh = (abs ~/ 60).toString().padLeft(2, '0');
      final mm = (abs % 60).toString().padLeft(2, '0');
      return 'UTC$sign$hh:$mm ${zt.abbreviation}';
    }

    Future<void> addWidgetIfRequested() async {
      if (!widget.canAddWidget || widget.onAddWidget == null) return;
      final addedLabel = DashboardCopy.addedWidgetNotice(
        context,
        DashboardCopy.toolDisplayName(
          context,
          toolId: widget.tool.id,
          fallback: widget.tool.title,
        ),
      );
      final duplicateLabel = DashboardCopy.duplicateWidgetNotice(
        context,
        DashboardCopy.toolDisplayName(
          context,
          toolId: widget.tool.id,
          fallback: widget.tool.title,
        ),
      );
      final failedLabel = DashboardCopy.addWidgetFailedNotice(context);
      try {
        await widget.onAddWidget!.call();
        if (!mounted) return;
        _showNotice(addedLabel, UnitanaNoticeKind.success);
      } on DuplicateDashboardWidgetException catch (_) {
        if (!mounted) return;
        _showNotice(duplicateLabel, UnitanaNoticeKind.info);
      } catch (_) {
        if (!mounted) return;
        _showNotice(failedLabel, UnitanaNoticeKind.error);
      }
    }

    final timeConverterHistory = widget.session.historyFor(widget.tool.id);
    final deltaMetricLabel = jetLagPlan.deltaLabelForUi;
    final homeGeo = PlaceGeoLookup.forPlace(widget.home);
    final destinationGeo = PlaceGeoLookup.forPlace(widget.destination);
    final flightEstimate = FlightTimeEstimator.estimate(
      fromLat: homeGeo?.lat,
      fromLon: homeGeo?.lon,
      toLat: destinationGeo?.lat,
      toLon: destinationGeo?.lon,
    );

    Widget buildCurrentClocksCard() {
      final factsTitle = DashboardCopy.factsTitle(
        context,
        isJetLagTool: _isJetLagDeltaTool,
      );
      final dateImpact = JetLagPlanner.dateImpactLabel(
        fromLocal: fromNow.local,
        toLocal: toNow.local,
      );
      String cleanDisplayLabel(String raw, String fallback) {
        final cleaned = raw
            .replaceFirst(RegExp(r'^\s*(Home|Destination)\s*·\s*'), '')
            .trim();
        return cleaned.isEmpty ? fallback : cleaned;
      }

      String countryCodeFromLabel(String label) {
        final parts = label.split(',');
        if (parts.length < 2) return '';
        final tail = parts.last.trim();
        if (RegExp(r'^[A-Za-z]{2}$').hasMatch(tail)) return tail.toUpperCase();
        return '';
      }

      String cityNameFromLabel(String label, String fallback) {
        final pieces = label.split(',');
        final city = pieces.first.trim();
        return city.isEmpty ? fallback : city;
      }

      final fromLabelRaw = cleanDisplayLabel(
        _timeFromDisplayLabel ?? '',
        labelFor(fromId),
      );
      final toLabelRaw = cleanDisplayLabel(
        _timeToDisplayLabel ?? '',
        labelFor(toId),
      );
      final fromCity = cityNameFromLabel(fromLabelRaw, labelFor(fromId));
      final toCity = cityNameFromLabel(toLabelRaw, labelFor(toId));
      final fromCountryCode = countryCodeFromLabel(fromLabelRaw);
      final toCountryCode = countryCodeFromLabel(toLabelRaw);
      final fromFlag = _countryFlag(fromCountryCode);
      final toFlag = _countryFlag(toCountryCode);
      final fromPrefix = fromFlag.isEmpty ? '' : '$fromFlag ';
      final toPrefix = toFlag.isEmpty ? '' : '$toFlag ';
      final fromOffsetLabel = '$fromPrefix$fromCity';
      final toOffsetLabel = '$toPrefix$toCity';
      final directionCompact = DashboardCopy.timeDirection(
        context: context,
        direction: jetLagPlan.direction,
      );
      final dateImpactCompactRaw = dateImpact
          .replaceFirst('Destination is ', '')
          .replaceFirst('calendar ', '');
      final dateImpactCompact = DashboardCopy.dateImpactTitleCase(
        dateImpactCompactRaw,
      );
      final showDualAnalogClocks =
          !_isJetLagDeltaTool && !_isTimeZoneConverterTool;
      final fromDigitalHud =
          '${clock(fromNow, use24h: widget.prefer24h)} ${fromNow.abbreviation}';
      final toDigitalHud =
          '${clock(toNow, use24h: widget.prefer24h)} ${toNow.abbreviation}';

      Widget factsMetaLine({
        required String label,
        required String value,
        Color? labelColor,
        Color? valueColor,
        bool italicValue = false,
        bool breakValueLine = false,
      }) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: breakValueLine ? '$label\n' : '$label ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelColor ?? textMuted.withAlpha(222),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valueColor ?? textPrimary,
                  fontWeight: FontWeight.w700,
                  fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        key: const ValueKey('tool_time_now_card'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              factsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: infoTone,
              ),
            ),
            if (showDualAnalogClocks) ...[
              const SizedBox(height: 10),
              Row(
                key: const ValueKey('tool_time_dual_analog_row'),
                children: [
                  Expanded(
                    child: _TimeAnalogClockFace(
                      key: const ValueKey('tool_time_analog_clock_home'),
                      cityLabel: fromCity,
                      flagPrefix: fromPrefix,
                      localTime: fromNow.local,
                      digitalHud: fromDigitalHud,
                      accentColor: infoTone.withAlpha(232),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeAnalogClockFace(
                      key: const ValueKey('tool_time_analog_clock_destination'),
                      cityLabel: toCity,
                      flagPrefix: toPrefix,
                      localTime: toNow.local,
                      digitalHud: toDigitalHud,
                      accentColor: warningTone.withAlpha(232),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$fromPrefix$fromCity:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ${clock(fromNow, use24h: widget.prefer24h)} (${zoneMeta(fromNow)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$toPrefix$toCity:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ${clock(toNow, use24h: widget.prefer24h)} (${zoneMeta(toNow)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isJetLagDeltaTool)
              factsMetaLine(
                label: DashboardCopy.timeFactsOffsetLabel(context),
                value:
                    '$toOffsetLabel vs $fromOffsetLabel: $deltaMetricLabel · $directionCompact',
                valueColor: textPrimary,
                breakValueLine: true,
              )
            else
              factsMetaLine(
                label: DashboardCopy.timeFactsOffsetLabel(context),
                value: '$toOffsetLabel vs $fromOffsetLabel: $deltaMetricLabel',
              ),
            if (_isJetLagDeltaTool) ...[
              const SizedBox(height: 4),
              factsMetaLine(
                label: DashboardCopy.timeFactsDateLabel(context),
                value: dateImpactCompact,
                labelColor: textMuted,
                valueColor: textPrimary,
              ),
              if (flightEstimate != null) ...[
                const SizedBox(height: 4),
                factsMetaLine(
                  label: DashboardCopy.timeFactsFlightLabel(context),
                  value: flightEstimate.factsLabel.replaceFirst(
                    'Estimated flight time: ',
                    '',
                  ),
                  labelColor: infoTone.withAlpha(220),
                  valueColor: infoTone.withAlpha(236),
                  italicValue: true,
                ),
              ],
            ],
          ],
        ),
      );
    }

    Widget buildJetLagPlannerCard() {
      final showOverlapHints = true;
      final gateOverlap = jetLagPlan.absDeltaHours <= 3;
      final showOverlapDetails =
          showOverlapHints && (!gateOverlap || _jetLagOverlapExpanded);
      final targetBedtime = _jetLagShiftedMinutes(
        baseMinutes: _jetLagBedtimeMinutes,
        plan: jetLagPlan,
      );
      final targetWake = _jetLagShiftedMinutes(
        baseMinutes: _jetLagWakeMinutes,
        plan: jetLagPlan,
      );
      final tonightSleep = jetLagPlan.isNoShift
          ? _formatMinutesOfDay(_jetLagBedtimeMinutes, use24h: widget.prefer24h)
          : _formatMinutesOfDay(targetBedtime, use24h: widget.prefer24h);
      final tonightWake = jetLagPlan.isNoShift
          ? _formatMinutesOfDay(_jetLagWakeMinutes, use24h: widget.prefer24h)
          : _formatMinutesOfDay(targetWake, use24h: widget.prefer24h);
      final baselineSleep = _formatMinutesOfDay(
        _jetLagBedtimeMinutes,
        use24h: widget.prefer24h,
      );
      final baselineWake = _formatMinutesOfDay(
        _jetLagWakeMinutes,
        use24h: widget.prefer24h,
      );

      TextSpan scheduleValueSpans({
        required String sleepValue,
        required String wakeValue,
      }) {
        return TextSpan(
          children: [
            TextSpan(
              text: DashboardCopy.jetLagSleepPrefix(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted.withAlpha(236),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: sleepValue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textPrimary.withAlpha(240),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: DashboardCopy.jetLagWakePrefix(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted.withAlpha(236),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: wakeValue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textPrimary.withAlpha(240),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      }

      String overlapFor({required int destHour, required int destMinute}) {
        final destLocal = DateTime(
          toNow.local.year,
          toNow.local.month,
          toNow.local.day,
          destHour,
          destMinute,
        );
        final asUtc = TimezoneUtils.localToUtc(toId, destLocal);
        final homeAtThatTime = TimezoneUtils.nowInZone(fromId, nowUtc: asUtc);
        return TimezoneUtils.formatClock(
          homeAtThatTime,
          use24h: widget.prefer24h,
        );
      }

      final overlapMorning = overlapFor(destHour: 9, destMinute: 0);
      final overlapEvening = overlapFor(destHour: 20, destMinute: 0);
      final tipPool = _jetLagTipsForPlan(jetLagPlan, labelFor(toId));
      final tipIndex = _jetLagTipsAutoRotateEnabled
          ? _jetLagTipIndex % tipPool.length
          : 0;
      final tipText = tipPool[tipIndex];
      final fromCity = widget.home?.cityName ?? labelFor(fromId);
      final toCity = widget.destination?.cityName ?? labelFor(toId);

      Widget planMetaLine({
        required String label,
        required String value,
        Color? labelColor,
        Color? valueColor,
        bool italicValue = false,
      }) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelColor ?? warningTone.withAlpha(220),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valueColor ?? textPrimary,
                  fontWeight: FontWeight.w700,
                  fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }

      InlineSpan styledCallWindowLine(String line) {
        final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary.withAlpha(235),
        );
        final toCityStyle = baseStyle?.copyWith(
          color: warningTone.withAlpha(242),
          fontWeight: FontWeight.w800,
        );
        final fromCityStyle = baseStyle?.copyWith(
          color: infoTone.withAlpha(238),
          fontWeight: FontWeight.w800,
        );
        final timeStyle = baseStyle?.copyWith(
          color: textPrimary.withAlpha(248),
          fontWeight: FontWeight.w900,
        );

        final timeMatches = RegExp(
          r'\b\d{1,2}:\d{2}\b',
        ).allMatches(line).toList();

        final spans = <InlineSpan>[];
        var cursor = 0;
        while (cursor < line.length) {
          final toMatchAt = toCity.isEmpty ? -1 : line.indexOf(toCity, cursor);
          final fromMatchAt = fromCity.isEmpty
              ? -1
              : line.indexOf(fromCity, cursor);
          var timeMatchAt = -1;
          Match? nextTimeMatch;
          for (final match in timeMatches) {
            if (match.start >= cursor) {
              timeMatchAt = match.start;
              nextTimeMatch = match;
              break;
            }
          }

          final hasToMatch = toMatchAt >= 0;
          final hasFromMatch = fromMatchAt >= 0;
          final hasTimeMatch = timeMatchAt >= 0 && nextTimeMatch != null;
          if (!hasToMatch && !hasFromMatch && !hasTimeMatch) {
            spans.add(TextSpan(text: line.substring(cursor), style: baseStyle));
            break;
          }

          var matchStart = -1;
          var matchToken = '';
          var matchStyle = baseStyle;
          if (hasTimeMatch &&
              (!hasToMatch || timeMatchAt <= toMatchAt) &&
              (!hasFromMatch || timeMatchAt <= fromMatchAt)) {
            matchStart = timeMatchAt;
            matchToken = nextTimeMatch.group(0) ?? '';
            matchStyle = timeStyle;
          } else if (hasToMatch &&
              (!hasFromMatch || toMatchAt <= fromMatchAt)) {
            matchStart = toMatchAt;
            matchToken = toCity;
            matchStyle = toCityStyle;
          } else if (hasFromMatch) {
            matchStart = fromMatchAt;
            matchToken = fromCity;
            matchStyle = fromCityStyle;
          }

          if (matchStart > cursor) {
            spans.add(
              TextSpan(
                text: line.substring(cursor, matchStart),
                style: baseStyle,
              ),
            );
          }
          spans.add(TextSpan(text: matchToken, style: matchStyle));
          cursor = matchStart + matchToken.length;
        }

        return TextSpan(children: spans, style: baseStyle);
      }

      return Container(
        key: const ValueKey('tool_time_planner_card'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DashboardCopy.jetLagPlanTitle(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: warningTone,
              ),
            ),
            const SizedBox(height: 8),
            planMetaLine(
              label: DashboardCopy.timeFactsOffsetLabel(context),
              value: deltaMetricLabel,
            ),
            const SizedBox(height: 4),
            planMetaLine(
              label: DashboardCopy.jetLagBandLabel(context),
              value:
                  '${jetLagPlan.bandLabel} · ~${jetLagPlan.adjustmentDays} days',
            ),
            const SizedBox(height: 4),
            planMetaLine(
              label: DashboardCopy.jetLagDailyShiftLabel(context),
              value: jetLagPlan.dailyShiftLabel,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('tool_jetlag_bedtime_button'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _pickJetLagTime(bedtime: true),
                    child: Text(
                      DashboardCopy.jetLagBedtimeButton(
                        context,
                        _formatMinutesOfDay(
                          _jetLagBedtimeMinutes,
                          use24h: widget.prefer24h,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('tool_jetlag_wake_button'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _pickJetLagTime(bedtime: false),
                    child: Text(
                      DashboardCopy.jetLagWakeButton(
                        context,
                        _formatMinutesOfDay(
                          _jetLagWakeMinutes,
                          use24h: widget.prefer24h,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              key: const ValueKey('tool_jetlag_personalized_schedule'),
              TextSpan(
                children: [
                  TextSpan(
                    text: DashboardCopy.jetLagTonightTargetLabel(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: warningTone.withAlpha(218),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    children: [
                      scheduleValueSpans(
                        sleepValue: tonightSleep,
                        wakeValue: tonightWake,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!jetLagPlan.isNoShift) ...[
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: DashboardCopy.jetLagBaselineLabel(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: warningTone.withAlpha(218),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    scheduleValueSpans(
                      sleepValue: baselineSleep,
                      wakeValue: baselineWake,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '💡 ${DashboardCopy.quickTipsTitle(context)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: warningTone,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 42,
              child: Align(
                alignment: Alignment.topLeft,
                child: AnimatedSwitcher(
                  key: const ValueKey('tool_jetlag_tip_rotator'),
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    tipText,
                    key: ValueKey('tool_jetlag_tip_text_$tipIndex'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textMuted.withAlpha(236),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            if (showOverlapHints) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${DashboardCopy.callWindowsTitle(context)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: warningTone,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              if (gateOverlap && !_jetLagOverlapExpanded)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    key: const ValueKey('tool_jetlag_overlap_toggle'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      setState(() {
                        _jetLagOverlapExpanded = true;
                      });
                    },
                    child: Text(DashboardCopy.showCallWindowsCta(context)),
                  ),
                ),
              if (showOverlapDetails)
                Column(
                  key: const ValueKey('tool_jetlag_overlap_panel'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DashboardCopy.overlapIntro(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textMuted.withAlpha(232),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      styledCallWindowLine(
                        DashboardCopy.jetLagCallWindowMorning(
                          context,
                          toCity: toCity,
                          overlapMorning: overlapMorning,
                          fromCity: fromCity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      styledCallWindowLine(
                        DashboardCopy.jetLagCallWindowEvening(
                          context,
                          toCity: toCity,
                          overlapEvening: overlapEvening,
                          fromCity: fromCity,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      );
    }

    Widget buildWorldTimeMapCard() {
      String cityFromLabel(String raw, String fallback) {
        final cleaned = raw
            .replaceFirst(RegExp(r'^\s*(Home|Destination)\s*·\s*'), '')
            .trim();
        final comma = cleaned.indexOf(',');
        if (comma <= 0) return cleaned.isEmpty ? fallback : cleaned;
        final city = cleaned.substring(0, comma).trim();
        return city.isEmpty ? fallback : city;
      }

      final fromCity = cityFromLabel(fromDisplayLabel, labelFor(fromId));
      final toCity = cityFromLabel(toDisplayLabel, labelFor(toId));
      final fromOffsetHours = fromNow.offsetMinutes / 60.0;
      final toOffsetHours = toNow.offsetMinutes / 60.0;
      final deltaHours = ((toNow.offsetMinutes - fromNow.offsetMinutes) / 60.0)
          .toStringAsFixed(1);
      final sameZone = fromNow.offsetMinutes == toNow.offsetMinutes;

      return Container(
        key: const ValueKey('tool_time_world_map_card'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'World Time Zones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: headingTone,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sameZone
                  ? '$fromCity and $toCity are in the same UTC band right now.'
                  : '$toCity is ${deltaHours.startsWith('-') ? '' : '+'}$deltaHours hours from $fromCity.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _WorldTimeZoneBandMap(
              fromCity: fromCity,
              toCity: toCity,
              fromOffsetHours: fromOffsetHours,
              toOffsetHours: toOffsetHours,
            ),
          ],
        ),
      );
    }

    return ListView(
      key: const ValueKey('tool_time_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: panelBorder),
          ),
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('tool_time_from_zone'),
                dense: true,
                title: Text(
                  DashboardCopy.timeFromZoneTitle(
                    context,
                    isJetLagTool: _isJetLagDeltaTool,
                  ),
                ),
                subtitle: Text(fromDisplayLabel),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () => _pickTimeZone(isFrom: true),
              ),
              Divider(color: textMuted.withAlpha(120), height: 1),
              ListTile(
                key: const ValueKey('tool_time_to_zone'),
                dense: true,
                title: Text(
                  DashboardCopy.timeToZoneTitle(
                    context,
                    isJetLagTool: _isJetLagDeltaTool,
                  ),
                ),
                subtitle: Text(toDisplayLabel),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () => _pickTimeZone(isFrom: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          key: const ValueKey('tool_time_action_row'),
          children: [
            Expanded(
              child: (widget.canAddWidget && widget.onAddWidget != null)
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('tool_add_widget_time'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: panelBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: addWidgetIfRequested,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: accent,
                        ),
                        label: Text(
                          DashboardCopy.addWidgetCta(context),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  key: const ValueKey('tool_time_swap_zones'),
                  onPressed: _swapTimeZones,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(DashboardCopy.swapCta(context)),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 10),
        if (_isJetLagDeltaTool) ...[
          buildCurrentClocksCard(),
          const SizedBox(height: 10),
          buildJetLagPlannerCard(),
        ],
        if (!_isJetLagDeltaTool && !_isWorldClockMapTool)
          buildCurrentClocksCard(),
        if (_isWorldClockMapTool) ...[
          const SizedBox(height: 10),
          buildWorldTimeMapCard(),
        ],
        if (_isTimeZoneConverterTool) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('tool_time_converter_card'),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DashboardCopy.convertLocalTimeTitle(context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headingTone,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DashboardCopy.convertLocalTimeHelper(
                    context,
                    fromDisplayLabel,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('tool_time_convert_input'),
                  controller: _timeConvertController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: DashboardCopy.timeConverterInputHint(context),
                  ),
                  onSubmitted: (_) => _runTimeZoneConversion(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const ValueKey('tool_time_convert_run'),
                    onPressed: _runTimeZoneConversion,
                    child: Text(DashboardCopy.convertTimeCta(context)),
                  ),
                ),
                const SizedBox(height: 10),
                _ResultCard(
                  toolId: widget.tool.id,
                  lensId: widget.tool.lensId,
                  line: _resultLine,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  DashboardCopy.historyTitle(context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headingTone,
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('tool_time_history_clear'),
                  onPressed: timeConverterHistory.isEmpty
                      ? null
                      : () async {
                          final historyClearedLabel =
                              DashboardCopy.historyClearedNotice(context);
                          final confirmed = await _confirmClearHistory(context);
                          if (!confirmed) return;
                          widget.session.clearHistory(widget.tool.id);
                          _showNotice(
                            historyClearedLabel,
                            UnitanaNoticeKind.success,
                          );
                        },
                  child: Text(DashboardCopy.clearCta(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('tool_time_history_container'),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: panelBorder),
            ),
            child: timeConverterHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: _EmptyHistory(),
                  )
                : ListView.builder(
                    key: const ValueKey('tool_time_history_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: timeConverterHistory.length,
                    itemBuilder: (context, index) {
                      final record = timeConverterHistory[index];
                      return ListTile(
                        dense: true,
                        title: Text(record.outputLabel),
                        subtitle: Text(record.inputLabel),
                        trailing: Text(
                          record.timestamp
                              .toLocal()
                              .toIso8601String()
                              .substring(11, 16),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: textMuted.withAlpha(200)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  (String, Color, bool)? _currencyStatusBanner() {
    if (!_isCurrencyTool) return null;
    if (!widget.currencyNetworkEnabled) {
      return (
        'Live rates are turned off in this build. Conversions use saved rates.',
        _ToolModalThemePolicy.textMuted(context),
        false,
      );
    }

    final errorAt = widget.currencyLastErrorAt;
    if (!widget.currencyIsStale && errorAt == null) return null;

    final refreshedAt = widget.currencyLastRefreshedAt;
    final cadenceHours = widget.currencyRefreshCadence.inHours;
    final lastSavedLabel = refreshedAt == null
        ? null
        : FreshnessCopy.relativeAgeShort(
            now: DateTime.now(),
            then: refreshedAt,
          );

    if (errorAt != null) {
      final ageLabel = FreshnessCopy.relativeAgeShort(
        now: DateTime.now(),
        then: errorAt,
      );
      final canRetryNow = widget.currencyShouldRetryNow;
      if (lastSavedLabel != null) {
        if (canRetryNow) {
          return (
            'Live refresh hit an issue ($ageLabel). Using saved rates from $lastSavedLabel. You can retry now.',
            _ToolModalThemePolicy.infoTone(context),
            true,
          );
        }
        return (
          'Live refresh hit an issue ($ageLabel). Using saved rates from $lastSavedLabel. Auto-retry is on.',
          _ToolModalThemePolicy.textMuted(context),
          false,
        );
      }

      if (canRetryNow) {
        return (
          'Live rates are temporarily unavailable ($ageLabel). You can retry now.',
          _ToolModalThemePolicy.warningTone(context),
          true,
        );
      }
      return (
        'Live rates are temporarily unavailable ($ageLabel). Auto-retry is on.',
        _ToolModalThemePolicy.warningTone(context),
        false,
      );
    }

    if (refreshedAt != null) {
      return (
        'Using saved rates from $lastSavedLabel. Auto-refresh target: every $cadenceHours hours.',
        _ToolModalThemePolicy.textMuted(context),
        false,
      );
    }

    return (
      'Using saved rates. Auto-refresh target: every $cadenceHours hours.',
      _ToolModalThemePolicy.textMuted(context),
      false,
    );
  }

  Widget _buildSheetHeader({
    required Color accent,
    required Color textPrimary,
    required Color panelBorder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Balance the trailing close action so the title reads centered.
          const SizedBox(width: 44),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.tool.icon, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      DashboardCopy.toolDisplayName(
                        context,
                        toolId: widget.tool.id,
                        fallback: widget.tool.title,
                      ),
                      key: ValueKey('tool_title_${widget.tool.id}'),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style:
                          (Theme.of(context).textTheme.headlineSmall ??
                                  const TextStyle())
                              .merge(
                                GoogleFonts.robotoSlab(
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: DashboardCopy.closeToolTooltip(context),
            child: OutlinedButton(
              key: ValueKey('tool_close_${widget.tool.id}'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: panelBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: textPrimary.withAlpha(220),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyStatusBanner({
    required String text,
    required Color color,
    required bool canRetryNow,
    required Color panelBg,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        key: ValueKey('tool_currency_status_${widget.tool.id}'),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(170)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (canRetryNow && widget.onRetryCurrencyNow != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: ValueKey('tool_currency_retry_${widget.tool.id}'),
                    onPressed: () async {
                      final refreshingRatesLabel =
                          DashboardCopy.refreshingRatesNotice(context);
                      final refreshRatesFailedLabel =
                          DashboardCopy.refreshRatesFailedNotice(context);
                      try {
                        await widget.onRetryCurrencyNow!.call();
                        if (!mounted) return;
                        _showNotice(
                          refreshingRatesLabel,
                          UnitanaNoticeKind.info,
                        );
                      } catch (_) {
                        if (!mounted) return;
                        _showNotice(
                          refreshRatesFailedLabel,
                          UnitanaNoticeKind.error,
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(DashboardCopy.retryRatesCta(context)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection({
    required List<ConversionRecord> history,
    required Color textMuted,
    required Color panelBg,
    required Color panelBorder,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                DashboardCopy.historyTitle(context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _ToolModalThemePolicy.headingTone(context),
                ),
              ),
              Text(
                DashboardCopy.historyCopyHint(context),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: math.min(MediaQuery.sizeOf(context).height * 0.28, 280.0),
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: panelBorder),
            ),
            child: history.isEmpty
                ? const _EmptyHistory()
                : ListView.builder(
                    key: ValueKey('tool_history_list_${widget.tool.id}'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final r = history[index];
                      final isMostRecent = index == 0;

                      final inputLabel = r.inputLabel;
                      final outputLabel = r.outputLabel;
                      final timestamp = r.timestamp
                          .toLocal()
                          .toIso8601String()
                          .substring(11, 19);

                      return InkWell(
                        key: ValueKey('tool_history_${widget.tool.id}_$index'),
                        onTap: () async {
                          final toCopy = _stripKnownUnitSuffix(r.outputLabel);
                          await Clipboard.setData(ClipboardData(text: toCopy));
                          if (!mounted) return;
                          _showNotice(
                            'Copied result',
                            UnitanaNoticeKind.success,
                          );
                        },
                        onLongPress: () async {
                          final preservedText = _controller.text;

                          final raw = _stripKnownUnitSuffix(r.inputLabel);
                          final toCopy = _trimTrailingZerosForClipboard(raw);
                          await Clipboard.setData(ClipboardData(text: toCopy));
                          if (!mounted) return;

                          // Guard against accidental "restore/edit" regressions.
                          if (_controller.text != preservedText) {
                            _controller
                              ..text = preservedText
                              ..selection = TextSelection.collapsed(
                                offset: preservedText.length,
                              );
                          }
                          _showNotice(
                            'Copied input',
                            UnitanaNoticeKind.success,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TerminalLine(
                                      prompt: '>',
                                      input: inputLabel,
                                      output: outputLabel,
                                      emphasize: isMostRecent,
                                      arrowColor: isMostRecent
                                          ? _ToolModalThemePolicy.headingTone(
                                              context,
                                            )
                                          : _ToolModalThemePolicy.textMuted(
                                              context,
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timestamp,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: textMuted.withAlpha(200),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: history.isEmpty
                ? null
                : () async {
                    final historyClearedLabel =
                        DashboardCopy.historyClearedNotice(context);
                    final ok = await _confirmClearHistory(context);
                    if (!ok || !mounted) return;

                    widget.session.clearHistory(widget.tool.id);
                    setState(() {
                      _controller.clear();
                      _resultLine = null;
                    });
                    _showNotice(historyClearedLabel, UnitanaNoticeKind.success);
                  },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: _ToolModalThemePolicy.warningTone(context),
            ),
            child: Text(
              DashboardCopy.clearHistoryButtonLabel(context),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _ToolModalThemePolicy.warningTone(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultPostConversionSection({
    required Color accent,
    required List<ConversionRecord> history,
    required Color textMuted,
    required Color panelBg,
    required Color panelBorder,
  }) {
    final disclaimer = _toolDisclaimerCopy(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        _ResultCard(
          toolId: widget.tool.id,
          lensId: widget.tool.lensId,
          line: _resultLine,
        ),
        if (widget.tool.id == 'pace') ...[
          const SizedBox(height: 10),
          _buildPaceInsightsCard(context, accent),
        ],
        if (widget.tool.id == 'energy') ...[
          const SizedBox(height: 10),
          _buildEnergyPlannerCard(context, accent),
        ],
        if (disclaimer != null) ...[
          const SizedBox(height: 10),
          _buildDisclaimerCard(
            context,
            key: ValueKey('tool_disclaimer_${widget.tool.id}'),
            text: disclaimer,
          ),
        ],
        _buildHistorySection(
          history: history,
          textMuted: textMuted,
          panelBg: panelBg,
          panelBorder: panelBorder,
        ),
      ],
    );
  }

  Widget _buildDefaultCalculatorSection({
    required Color accent,
    required Color textMuted,
    required Color panelBorder,
    required NumericInputPolicy numericPolicy,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The smallest supported test surface (320px wide) can overflow if we
        // force the Convert button to live on the same row as the input.
        final isNarrow = constraints.maxWidth <= 340;

        final helperText = _toolInputCoachCopy(context);
        final inputBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DashboardCopy.editValueLabel(context),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              key: ValueKey('tool_input_${widget.tool.id}'),
              controller: _controller,
              keyboardType: _requiresFreeformInput
                  ? TextInputType.text
                  : TextInputType.numberWithOptions(
                      decimal: numericPolicy.allowDecimal,
                      signed: numericPolicy.allowNegative,
                    ),
              inputFormatters: _requiresFreeformInput
                  ? const <TextInputFormatter>[]
                  : <TextInputFormatter>[
                      NumericTextInputFormatter(policy: numericPolicy),
                    ],
              decoration: InputDecoration(hintText: _toolInputHint(context)),
              onSubmitted: (_) => _runConversion(),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 6),
              Text(
                helperText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, _) {
                final canAdd =
                    widget.canAddWidget && widget.onAddWidget != null;

                Widget buildUnitsAndSwap() {
                  final Widget unitsWidget = _supportsUnitPicker
                      ? Column(
                          key: ValueKey('tool_units_${widget.tool.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  key: ValueKey(
                                    'tool_unit_from_${widget.tool.id}',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(color: panelBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: () => _pickUnit(isFrom: true),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _fromUnit,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: accent.withAlpha(220),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '→',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: accent,
                                        ),
                                  ),
                                ),
                                OutlinedButton(
                                  key: ValueKey(
                                    'tool_unit_to_${widget.tool.id}',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(color: panelBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: () => _pickUnit(isFrom: false),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _toUnit,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: accent.withAlpha(220),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.tool.id == 'baking')
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  '$_fromUnit → $_toUnit',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: accent.withAlpha(230),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        )
                      : Text(
                          '$_fromUnit → $_toUnit',
                          key: ValueKey('tool_units_${widget.tool.id}'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        );

                  final swapButton = OutlinedButton(
                    key: ValueKey('tool_swap_${widget.tool.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(34, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: panelBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _swapUnits,
                    child: PulseSwapIcon(
                      color: accent.withAlpha(220),
                      size: 18,
                    ),
                  );

                  return Row(
                    key: ValueKey('tool_units_row_${widget.tool.id}'),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: unitsWidget,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Align(alignment: Alignment.center, child: swapButton),
                    ],
                  );
                }

                Widget buildAddWidgetButton() {
                  return OutlinedButton.icon(
                    key: ValueKey('tool_add_widget_${widget.tool.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: panelBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final addedLabel = DashboardCopy.addedWidgetNotice(
                        context,
                        DashboardCopy.toolDisplayName(
                          context,
                          toolId: widget.tool.id,
                          fallback: widget.tool.title,
                        ),
                      );
                      final duplicateLabel =
                          DashboardCopy.duplicateWidgetNotice(
                            context,
                            DashboardCopy.toolDisplayName(
                              context,
                              toolId: widget.tool.id,
                              fallback: widget.tool.title,
                            ),
                          );
                      final failedLabel = DashboardCopy.addWidgetFailedNotice(
                        context,
                      );
                      try {
                        await widget.onAddWidget!.call();
                        if (!mounted) return;
                        _showNotice(addedLabel, UnitanaNoticeKind.success);
                      } on DuplicateDashboardWidgetException catch (_) {
                        if (!mounted) return;
                        _showNotice(duplicateLabel, UnitanaNoticeKind.info);
                      } catch (_) {
                        if (!mounted) return;
                        _showNotice(failedLabel, UnitanaNoticeKind.error);
                      }
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: accent,
                    ),
                    label: Text(
                      DashboardCopy.addWidgetCta(context),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  );
                }

                Widget buildResetDefaultsButton() {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey('tool_units_reset_${widget.tool.id}'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: _hasCustomUnitSelection
                          ? _resetUnitSelectionToDefaults
                          : null,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset Defaults'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canAdd) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: buildAddWidgetButton(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    buildUnitsAndSwap(),
                    if (_supportsUnitPicker) ...[
                      const SizedBox(height: 4),
                      buildResetDefaultsButton(),
                    ],
                  ],
                );
              },
            ),
          ],
        );

        final convertButton = SizedBox(
          height: 52,
          child: FilledButton(
            key: ValueKey('tool_run_${widget.tool.id}'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _runConversion,
            child: Text(DashboardCopy.convertCta(context)),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              inputBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: convertButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: inputBlock),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: convertButton,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultToolBody({
    required Color accent,
    required Color textMuted,
    required Color panelBg,
    required Color panelBorder,
  }) {
    final history = widget.session.historyFor(widget.tool.id);
    final numericPolicy = ToolNumericPolicies.forToolId(widget.tool.id);
    return ListView(
      key: ValueKey('tool_scroll_${widget.tool.id}'),
      // Cache more offscreen content so widget tests can locate history items
      // reliably on small surfaces.
      cacheExtent: 1200,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildDefaultCalculatorSection(
          accent: accent,
          textMuted: textMuted,
          panelBorder: panelBorder,
          numericPolicy: numericPolicy,
        ),
        _buildDefaultPostConversionSection(
          accent: accent,
          history: history,
          textMuted: textMuted,
          panelBg: panelBg,
          panelBorder: panelBorder,
        ),
      ],
    );
  }

  Widget _buildToolBody({
    required Color accent,
    required Color textMuted,
    required Color panelBg,
    required Color panelBorder,
  }) {
    if (_isTimeTool) return _buildTimeToolBody(context, accent);
    if (_isLookupTool) return _buildLookupBody(context, accent);
    if (_isUnitPriceTool) return _buildUnitPriceBody(context, accent);
    if (_isHydrationTool) return _buildHydrationBody(context, accent);
    if (_isTaxVatTool) return _buildTaxVatBody(context, accent);
    if (_isTipHelperTool) return _buildTipHelperBody(context, accent);
    return _buildDefaultToolBody(
      accent: accent,
      textMuted: textMuted,
      panelBg: panelBg,
      panelBorder: panelBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        // Some tools may not have a lensId (legacy or internal tools). Fall back
        // to the default accent mapping rather than failing compilation.
        final accent = LensAccents.toolIconTintForBrightness(
          toolId: widget.tool.id,
          lensId: widget.tool.lensId,
          brightness: Theme.of(context).brightness,
        );
        final viewInsets = MediaQuery.of(context).viewInsets;
        final currencyStatus = _currencyStatusBanner();
        final textPrimary = _ToolModalThemePolicy.textPrimary(context);
        final textMuted = _ToolModalThemePolicy.textMuted(context);
        final panelBg = _ToolModalThemePolicy.panelBg(context);
        final panelBorder = _ToolModalThemePolicy.panelBorder(context);

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.85,
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  _buildSheetHeader(
                    accent: accent,
                    textPrimary: textPrimary,
                    panelBorder: panelBorder,
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _noticeText == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: UnitanaNoticeCard(
                              kind: _noticeKind,

                              key: ValueKey(
                                'tool_add_widget_notice_${widget.tool.id}',
                              ),
                              text: _noticeText!,
                            ),
                          ),
                  ),

                  if (currencyStatus != null)
                    _buildCurrencyStatusBanner(
                      text: currencyStatus.$1,
                      color: currencyStatus.$2,
                      canRetryNow: currencyStatus.$3,
                      panelBg: panelBg,
                    ),

                  // Body (scrollable on tight surfaces).
                  Expanded(
                    child: _buildToolBody(
                      accent: accent,
                      textMuted: textMuted,
                      panelBg: panelBg,
                      panelBorder: panelBorder,
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
}

class _ResultCard extends StatelessWidget {
  final String toolId;
  final String? lensId;
  final String? line;

  const _ResultCard({
    required this.toolId,
    required this.lensId,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    final accent = LensAccents.toolIconTintForBrightness(
      toolId: toolId,
      lensId: lensId,
      brightness: Theme.of(context).brightness,
    );
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);

    final resolved = line;
    String input;
    String output;
    if (resolved == null || resolved.trim().isEmpty) {
      input = 'Result';
      output = 'Run Convert';
    } else if (resolved.contains('→')) {
      final parts = resolved.split('→');
      input = parts.first.trim();
      output = parts.sublist(1).join('→').trim();
    } else {
      input = resolved.trim();
      output = '';
    }

    return Container(
      key: ValueKey('tool_result_$toolId'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
      ),
      child: _TerminalLine(
        prompt: '>',
        input: input,
        output: output,
        emphasize: true,
        arrowColor: accent,
      ),
    );
  }
}

class _TimeZoneQuickChip extends StatelessWidget {
  final String label;
  final String detail;
  final VoidCallback onTap;

  const _TimeZoneQuickChip({
    required this.label,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = _ToolModalThemePolicy.panelBgSoft(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context, alpha: 145);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    return ActionChip(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: panelBorder),
      backgroundColor: panelBg,
      label: Text(
        '$label · $detail',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimeAnalogClockFace extends StatelessWidget {
  final String cityLabel;
  final String flagPrefix;
  final DateTime localTime;
  final String digitalHud;
  final Color accentColor;

  const _TimeAnalogClockFace({
    super.key,
    required this.cityLabel,
    required this.flagPrefix,
    required this.localTime,
    required this.digitalHud,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = _ToolModalThemePolicy.panelBgSoft(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context, alpha: 120);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    final isLight = _ToolModalThemePolicy.isLight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$flagPrefix$cityLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: panelBg,
                    border: Border.all(color: panelBorder, width: 1.2),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _TimeAnalogClockPainter(
                    localTime: localTime,
                    accentColor: accentColor,
                    tickColor: _ToolModalThemePolicy.textMuted(context),
                    handColor: _ToolModalThemePolicy.textPrimary(context),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    key: ValueKey('tool_time_analog_hud_$cityLabel'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color:
                            (isLight
                                    ? Theme.of(context).colorScheme.outline
                                    : accentColor)
                                .withAlpha(165),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      digitalHud,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeAnalogClockPainter extends CustomPainter {
  final DateTime localTime;
  final Color accentColor;
  final Color tickColor;
  final Color handColor;

  const _TimeAnalogClockPainter({
    required this.localTime,
    required this.accentColor,
    required this.tickColor,
    required this.handColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final tickPaint = Paint()
      ..color = tickColor.withAlpha(150)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    for (var i = 0; i < 12; i++) {
      final angle = (math.pi * 2 * (i / 12)) - (math.pi / 2);
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 16);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final minutes = localTime.minute + (localTime.second / 60);
    final hours = (localTime.hour % 12) + (minutes / 60);
    final minuteAngle = (math.pi * 2 * (minutes / 60)) - (math.pi / 2);
    final hourAngle = (math.pi * 2 * (hours / 12)) - (math.pi / 2);

    final hourHandPaint = Paint()
      ..color = handColor.withAlpha(242)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final minuteHandPaint = Paint()
      ..color = accentColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1;

    final hourEnd =
        center +
        Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * 0.45);
    final minuteEnd =
        center +
        Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * 0.64);
    canvas.drawLine(center, hourEnd, hourHandPaint);
    canvas.drawLine(center, minuteEnd, minuteHandPaint);
    canvas.drawCircle(center, 3.2, Paint()..color = accentColor.withAlpha(232));
  }

  @override
  bool shouldRepaint(covariant _TimeAnalogClockPainter oldDelegate) {
    return oldDelegate.localTime.minute != localTime.minute ||
        oldDelegate.localTime.hour != localTime.hour ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.handColor != handColor;
  }
}

class _WorldTimeZoneBandMap extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final double fromOffsetHours;
  final double toOffsetHours;

  const _WorldTimeZoneBandMap({
    required this.fromCity,
    required this.toCity,
    required this.fromOffsetHours,
    required this.toOffsetHours,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = _ToolModalThemePolicy.panelBgSoft(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context, alpha: 130);
    final muted = _ToolModalThemePolicy.textMuted(context);
    final infoTone = _ToolModalThemePolicy.infoTone(context);
    final destTone = _ToolModalThemePolicy.dangerTone(context);
    final style = Theme.of(context).textTheme;
    final bands = List<int>.generate(27, (index) => index - 12);
    int nearestBand(double offset) {
      var best = bands.first;
      var bestDiff = (bands.first - offset).abs();
      for (final band in bands.skip(1)) {
        final diff = (band - offset).abs();
        if (diff < bestDiff) {
          best = band;
          bestDiff = diff;
        }
      }
      return best;
    }

    final fromBand = nearestBand(fromOffsetHours);
    final toBand = nearestBand(toOffsetHours);

    Color bandColor(int band) {
      final isHome = band == fromBand;
      final isDest = band == toBand;
      if (isHome && isDest) {
        return Color.lerp(infoTone, destTone, 0.5)!.withAlpha(185);
      }
      if (isHome) return infoTone.withAlpha(195);
      if (isDest) return destTone.withAlpha(195);
      return panelBg.withAlpha(170);
    }

    Widget legendPill({
      required String city,
      required double offset,
      required Color tone,
      required TextAlign align,
    }) {
      final offsetText =
          'UTC${offset >= 0 ? '+' : ''}${offset.toStringAsFixed(1)}';
      return DecoratedBox(
        decoration: BoxDecoration(
          color: panelBg.withAlpha(210),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tone.withAlpha(170)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: Column(
            crossAxisAlignment: align == TextAlign.right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: style.bodySmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                offsetText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: style.labelSmall?.copyWith(
                  color: muted.withAlpha(230),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('tool_time_world_map_bands'),
      height: 150,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.5,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        muted.withAlpha(210),
                        BlendMode.modulate,
                      ),
                      child: Image.asset(
                        'assets/maps/world_outline.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.06, -0.08),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WorldTimeBackdropPainter(
                        color: muted.withAlpha(60),
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final band in bands)
                      Expanded(
                        child: Tooltip(
                          message:
                              'UTC${band >= 0 ? '+' : ''}$band${band == fromBand ? ' • Home' : ''}${band == toBand ? ' • Destination' : ''}',
                          child: Container(
                            decoration: BoxDecoration(
                              color: bandColor(band),
                              border: Border(
                                right: BorderSide(
                                  color: muted.withAlpha(78),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: legendPill(
                    city: fromCity,
                    offset: fromOffsetHours,
                    tone: infoTone,
                    align: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: legendPill(
                    city: toCity,
                    offset: toOffsetHours,
                    tone: destTone,
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldTimeBackdropPainter extends CustomPainter {
  final Color color;

  const _WorldTimeBackdropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final gridStroke = Paint()
      ..color = color.withAlpha(56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    final latitudeStroke = Paint()
      ..color = color.withAlpha(78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;

    // Light lat/long graticule over raster Earth map.
    for (var i = 1; i <= 5; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridStroke);
    }
    for (var i = 1; i <= 23; i++) {
      final x = size.width * (i / 24);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridStroke);
    }
    final equatorY = size.height * 0.5;
    final tropicNorthY = size.height * (1 / 3);
    final tropicSouthY = size.height * (2 / 3);
    final polarSouthY = size.height * 0.82;
    canvas.drawLine(
      Offset(0, equatorY),
      Offset(size.width, equatorY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, tropicNorthY),
      Offset(size.width, tropicNorthY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, tropicSouthY),
      Offset(size.width, tropicSouthY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, polarSouthY),
      Offset(size.width, polarSouthY),
      latitudeStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldTimeBackdropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PaceCheckpointBarChart extends StatelessWidget {
  final List<({String label, double minutes})> checkpoints;
  final Color accent;
  final Color textColor;

  const _PaceCheckpointBarChart({
    required this.checkpoints,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) return const SizedBox.shrink();
    final maxMinutes = checkpoints
        .map((cp) => cp.minutes)
        .fold<double>(0, (a, b) => math.max(a, b));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final cp in checkpoints)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cp.label.split('•').first.trim(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxMinutes <= 0
                            ? 0
                            : (cp.minutes / maxMinutes),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                accent.withAlpha(170),
                                accent.withAlpha(105),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No history yet',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _ToolModalThemePolicy.textMuted(context),
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
