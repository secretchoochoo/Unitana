import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/unitana_notice_card.dart';
import '../../../common/debug/picker_perf_trace.dart';
import '../../../common/debug/runtime_perf_trace.dart';
import '../../../data/cities.dart' show kCurrencySymbols;
import '../../../data/city_picker_engine.dart';
import '../../../data/city_label_utils.dart';
import '../../../data/city_repository.dart';
import '../../../data/country_currency_map.dart';
import '../../../models/place.dart';
import '../../../theme/dracula_palette.dart';
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_copy.dart';
import '../models/dashboard_exceptions.dart';
import '../models/freshness_copy.dart';
import '../models/lens_accents.dart';
import '../models/numeric_input_policy.dart';
import '../models/time_zone_catalog.dart';
import '../models/tool_helper_calculators.dart';
import '../models/tool_lookup_catalog.dart';
import '../models/tool_pace_energy_helpers.dart';
import '../models/tool_time_helpers.dart';
import '../models/tool_definitions.dart';
import '../models/canonical_tools.dart';

import 'destructive_confirmation_sheet.dart';
import 'searchable_option_picker_sheet.dart';
import 'tool_default_surface.dart';
import 'tool_default_workspace.dart';
import 'tool_helper_surfaces.dart';
import 'tool_lookup_surface.dart';
import 'tool_lookup_workspace.dart';
import 'tool_time_surface.dart';
import 'tool_time_workspace.dart';

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
    this.currencyRefreshCadence = const Duration(minutes: 10),
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
    Duration currencyRefreshCadence = const Duration(minutes: 10),
    Future<void> Function()? onRetryCurrencyNow,
    Place? home,
    Place? destination,
    bool canAddWidget = false,
    Future<void> Function()? onAddWidget,
  }) {
    final openTrace = RuntimePerfTrace.start('tool_modal.open');
    var openLogged = false;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        if (!openLogged) {
          RuntimePerfTrace.logElapsed(
            'tool_modal.open',
            openTrace,
            extra: 'tool=${tool.id}',
            minMs: 1,
          );
          openLogged = true;
        }
        return ToolModalBottomSheet(
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
        );
      },
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
  final bool lineBreakBeforeOutput;

  const _TerminalLine({
    required this.prompt,
    required this.input,
    required this.output,
    required this.emphasize,
    required this.arrowColor,
    this.lineBreakBeforeOutput = false,
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
          TextSpan(text: lineBreakBeforeOutput ? '\n  $output' : ' $output'),
        ],
      ),
    );
  }
}

typedef _TimeZonePickerSelection = ({String zoneId, String displayLabel});

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
  final TextEditingController _taxRateController = TextEditingController();
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
  String? _lookupGroupKey;
  int _lookupMatrixPageIndex = 0;
  String? _timeFromZoneId;
  String? _timeToZoneId;
  String? _timeFromDisplayLabel;
  String? _timeToDisplayLabel;
  List<int> _tipPresetPercents = const <int>[10, 15, 20];
  int _tipPercent = 15;
  int _tipSplitCount = 1;
  String _tipRoundingMode = 'none';
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
  PaceActivityMode _paceMode = PaceActivityMode.running;
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
    _taxRateController.dispose();
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

  List<ToolLookupEntry> _lookupEntriesForTool() =>
      toolLookupEntriesFor(widget.tool.canonicalToolId);

  List<ToolLookupEntry> _visibleLookupEntriesForTool() {
    final rows = _lookupEntriesForTool();
    if (!_isClothingLookupTool) return rows;
    return toolLookupEntriesForGroup(
      canonicalToolId: widget.tool.canonicalToolId,
      rows: rows,
      groupKey: _lookupGroupKey,
    );
  }

  ToolLookupEntry? _activeLookupEntry() {
    final rows = _lookupEntriesForTool();
    if (rows.isEmpty) return null;
    final key = _lookupEntryKey;
    if (key == null) return rows.first;
    for (final row in rows) {
      if (row.keyId == key) return row;
    }
    return rows.first;
  }

  String _lookupValue({required ToolLookupEntry row, required String system}) {
    return row.valuesBySystem[system] ?? '—';
  }

  void _seedLookupDefaults() {
    final defaults = toolLookupDefaultsFor(widget.tool.canonicalToolId);
    _lookupFromSystem = defaults?.fromSystem;
    _lookupToSystem = defaults?.toSystem;
    _lookupEntryKey = defaults?.entryKey;
    final rows = _lookupEntriesForTool();
    final active = rows.cast<ToolLookupEntry?>().firstWhere(
      (row) => row?.keyId == _lookupEntryKey,
      orElse: () => rows.isEmpty ? null : rows.first,
    );
    _lookupGroupKey = active == null
        ? null
        : toolLookupGroupKeyForRow(
            canonicalToolId: widget.tool.canonicalToolId,
            row: active,
          );
  }

  void _seedTipHelperDefaults() {
    final countryCode = _activeTipCountryCode();
    _tipPresetPercents = tipPresetsForCountry(countryCode);
    _tipPercent = defaultTipPercentForCountry(countryCode);
    _tipSplitCount = 1;
    _tipRoundingMode = 'none';
    if (_controller.text.trim().isEmpty) {
      _controller.text = '100';
    }
  }

  void _seedTaxVatDefaults() {
    final countryCode = _activeTipCountryCode();
    _taxRateController.text = defaultTaxPercentForCountry(
      countryCode,
    ).toString();
    _taxMode = defaultTaxModeAddOnForCountry(countryCode)
        ? 'add_on'
        : 'inclusive';
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

  String _activePricingContextLabel() {
    final preferred = widget.session.reality == DashboardReality.destination
        ? widget.destination
        : widget.home;
    final fallback = preferred == widget.destination
        ? widget.home
        : widget.destination;
    final place = preferred ?? fallback;
    final city = place?.cityName.trim() ?? '';
    final countryCode = (place?.countryCode ?? _activeTipCountryCode())
        .trim()
        .toUpperCase();
    if (city.isEmpty) return countryCode;
    return '$city, $countryCode';
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

  double? _parseTaxRatePercent() {
    final raw = _taxRateController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || !parsed.isFinite) return null;
    if (parsed < 0) return null;
    return parsed;
  }

  void _handleUnitPriceUnitSelected({
    required bool forProductA,
    required String unit,
  }) {
    setState(() {
      if (forProductA) {
        _unitPriceUnitA = unit;
        if (_unitPriceCompareEnabled &&
            !unitPriceSameFamily(_unitPriceUnitA, _unitPriceUnitB)) {
          _unitPriceUnitB = unitPriceDefaultFamilyUnitFor(unit);
        }
      } else {
        _unitPriceUnitB = unit;
        if (_unitPriceCompareEnabled &&
            !unitPriceSameFamily(_unitPriceUnitA, _unitPriceUnitB)) {
          _unitPriceUnitA = unitPriceDefaultFamilyUnitFor(unit);
        }
      }
    });
  }

  double? _parsePositiveText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
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
    return null;
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

  String _formatWeightInputValue(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _convertDisplayedWeightInput(
    TextEditingController controller, {
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return;
    final raw = controller.text.trim();
    if (raw.isEmpty) return;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed <= 0) {
      return;
    }

    double converted = parsed;
    if (fromUnit == 'kg' && toUnit == 'lb') {
      converted = parsed / 0.45359237;
    } else if (fromUnit == 'lb' && toUnit == 'kg') {
      converted = parsed * 0.45359237;
    } else {
      return;
    }

    controller.text = _formatWeightInputValue(converted);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  int? _parseHydrationExerciseMinutes() {
    final raw = _hydrationExerciseController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  Widget _buildHydrationBody(BuildContext context, Color accent) {
    final estimate = computeHydrationEstimate(
      weightKg: _parseHydrationWeightKg(),
      exerciseMinutes: _parseHydrationExerciseMinutes(),
      climateBand: _hydrationClimateBand,
    );
    return ToolHydrationSurface(
      toolId: widget.tool.id,
      weightController: _controller,
      exerciseController: _hydrationExerciseController,
      weightUnit: _hydrationWeightUnit,
      climateBand: _hydrationClimateBand,
      climateHelpText: DashboardCopy.hydrationClimateHelp(
        context,
        climateBand: _hydrationClimateBand,
      ),
      invalidMessage: 'Enter valid weight and exercise minutes.',
      disclaimerText: DashboardCopy.disclaimerMedical(context),
      resultSummary: estimate == null
          ? null
          : 'Daily fluid estimate -> ${estimate.totalLiters.toStringAsFixed(1)} L (${estimate.totalFluidOunces.toStringAsFixed(0)} fl oz)',
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: _ToolModalThemePolicy.panelBg(context),
        panelBgSoft: _ToolModalThemePolicy.panelBgSoft(context),
        panelBorder: _ToolModalThemePolicy.panelBorder(context),
        textMuted: _ToolModalThemePolicy.textMuted(context),
        headingTone: _ToolModalThemePolicy.headingTone(context),
      ),
      onWeightChanged: (_) => setState(() {}),
      onExerciseChanged: (_) => setState(() {}),
      onSelectWeightUnit: (nextUnit) => setState(() {
        _convertDisplayedWeightInput(
          _controller,
          fromUnit: _hydrationWeightUnit,
          toUnit: nextUnit,
        );
        _hydrationWeightUnit = nextUnit;
      }),
      onSelectClimateBand: (band) => setState(() {
        _hydrationClimateBand = band;
      }),
    );
  }

  Widget _buildTipHelperBody(BuildContext context, Color accent) {
    final tip = computeTip(
      amount: _parseTipAmount(),
      tipPercent: _tipPercent,
      splitCount: _tipSplitCount,
      roundingMode: _tipRoundingMode,
    );

    return ToolTipHelperSurface(
      toolId: widget.tool.id,
      amountController: _controller,
      presetPercents: _tipPresetPercents,
      selectedPercent: _tipPercent,
      splitCount: _tipSplitCount,
      roundingMode: _tipRoundingMode,
      amountLabel: DashboardCopy.tipBillAmountLabel(
        context,
        _tipCurrencyCode(),
      ),
      amountHint: DashboardCopy.tipAmountHint(context),
      splitLabel: DashboardCopy.tipSplitLabel(context),
      roundingChoices: <(String, String)>[
        ('none', DashboardCopy.tipRoundingLabel(context, 'none')),
        ('nearest', DashboardCopy.tipRoundingLabel(context, 'nearest')),
        ('up', DashboardCopy.tipRoundingLabel(context, 'up')),
        ('down', DashboardCopy.tipRoundingLabel(context, 'down')),
      ],
      invalidAmountText: DashboardCopy.tipInvalidAmount(context),
      resultChild: tip == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TerminalLine(
                  prompt: '>',
                  input: DashboardCopy.tipLineLabel(context, _tipPercent),
                  output: _moneyWithCode(tip.tipAmount),
                  emphasize: true,
                  arrowColor: accent,
                ),
                const SizedBox(height: 6),
                _TerminalLine(
                  prompt: '>',
                  input: DashboardCopy.tipTotalLabel(context),
                  output: _moneyWithCode(tip.totalAmount),
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
                  output: _moneyWithCode(tip.perPersonAmount),
                  emphasize: false,
                  arrowColor: accent,
                ),
                if (tip.roundDelta.abs() >= 0.005) ...[
                  const SizedBox(height: 8),
                  Text(
                    DashboardCopy.tipRoundingAdjustment(
                      context,
                      sign: tip.roundDelta > 0 ? '+' : '',
                      deltaAmount: _moneyWithCode(
                        tip.roundDelta,
                      ).replaceFirst(_currencySymbol(_tipCurrencyCode()), ''),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ToolModalThemePolicy.textMuted(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: _ToolModalThemePolicy.panelBg(context),
        panelBgSoft: _ToolModalThemePolicy.panelBgSoft(context),
        panelBorder: _ToolModalThemePolicy.panelBorder(context),
        textMuted: _ToolModalThemePolicy.textMuted(context),
        headingTone: _ToolModalThemePolicy.headingTone(context),
      ),
      onAmountChanged: (_) => setState(() {}),
      onSelectPercent: (percent) => setState(() {
        _tipPercent = percent;
      }),
      onDecreaseSplit: _tipSplitCount <= 1
          ? null
          : () => setState(() {
              _tipSplitCount = math.max(1, _tipSplitCount - 1);
            }),
      onIncreaseSplit: () => setState(() {
        _tipSplitCount = math.min(12, _tipSplitCount + 1);
      }),
      onSelectRoundingMode: (mode) => setState(() {
        _tipRoundingMode = mode;
      }),
    );
  }

  Widget _buildTaxVatBody(BuildContext context, Color accent) {
    final isAddOn = _taxMode == 'add_on';
    final currencyCode = _tipCurrencyCode();
    final pricingContextLabel = _activePricingContextLabel();
    final taxPercent = _parseTaxRatePercent();
    final breakdown = computeTaxBreakdown(
      amount: _parseTaxVatAmount(),
      taxPercent: taxPercent ?? -1,
      isAddOn: isAddOn,
    );

    return ToolTaxVatSurface(
      toolId: widget.tool.id,
      amountController: _controller,
      rateController: _taxRateController,
      isAddOn: isAddOn,
      amountLabel: DashboardCopy.taxAmountLabel(
        context,
        isAddOn: isAddOn,
        currencyCode: currencyCode,
      ),
      amountHint: DashboardCopy.taxAmountHint(context),
      rateLabel: DashboardCopy.taxRateLabel(context),
      rateHint: DashboardCopy.taxRateHint(context),
      presetContextText: DashboardCopy.taxPresetContext(
        context,
        locationLabel: pricingContextLabel,
        currencyCode: currencyCode,
      ),
      addOnModeLabel: DashboardCopy.taxModeAddOn(context),
      inclusiveModeLabel: DashboardCopy.taxModeInclusive(context),
      invalidAmountText: DashboardCopy.taxInvalidAmount(context),
      modeHelpText: breakdown == null
          ? null
          : DashboardCopy.taxModeHelp(context, isAddOn: isAddOn),
      resultChild: breakdown == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TerminalLine(
                  prompt: '>',
                  input: DashboardCopy.taxSubtotalLine(context),
                  output: _moneyWithCode(breakdown.subtotal),
                  emphasize: true,
                  arrowColor: accent,
                ),
                const SizedBox(height: 6),
                _TerminalLine(
                  prompt: '>',
                  input: DashboardCopy.taxLineLabel(context, taxPercent),
                  output: _moneyWithCode(breakdown.taxAmount),
                  emphasize: false,
                  arrowColor: accent,
                ),
                const SizedBox(height: 6),
                _TerminalLine(
                  prompt: '>',
                  input: DashboardCopy.taxTotalLine(context),
                  output: _moneyWithCode(breakdown.totalAmount),
                  emphasize: true,
                  arrowColor: accent,
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardCopy.taxModeHelp(context, isAddOn: isAddOn),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ToolModalThemePolicy.textMuted(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: _ToolModalThemePolicy.panelBg(context),
        panelBgSoft: _ToolModalThemePolicy.panelBgSoft(context),
        panelBorder: _ToolModalThemePolicy.panelBorder(context),
        textMuted: _ToolModalThemePolicy.textMuted(context),
        headingTone: _ToolModalThemePolicy.headingTone(context),
      ),
      onAmountChanged: (_) => setState(() {}),
      onRateChanged: (_) => setState(() {}),
      onSelectMode: (nextIsAddOn) => setState(() {
        _taxMode = nextIsAddOn ? 'add_on' : 'inclusive';
      }),
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
    final metricsA = computeUnitPriceMetrics(
      price: priceA,
      quantity: qtyA,
      unit: _unitPriceUnitA,
    );
    final perBaseA = metricsA?.perBaseAmount;
    final per100A = metricsA?.per100Amount;
    final per1kA = metricsA?.per1000Amount;
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
    final metricsB = computeUnitPriceMetrics(
      price: priceB,
      quantity: qtyB,
      unit: _unitPriceUnitB,
    );
    final per100B = metricsB?.per100Amount;
    final per1kB = metricsB?.per1000Amount;
    final per100BSecondary = (per100B != null && secondaryCurrencyCode != null)
        ? _convertCurrencyAmount(
            amount: per100B,
            fromCode: primaryCurrencyCode,
            toCode: secondaryCurrencyCode,
          )
        : null;
    final per1kBSecondary = (per1kB != null && secondaryCurrencyCode != null)
        ? _convertCurrencyAmount(
            amount: per1kB,
            fromCode: primaryCurrencyCode,
            toCode: secondaryCurrencyCode,
          )
        : null;

    final comparison = computeUnitPriceComparison(
      compareEnabled: _unitPriceCompareEnabled,
      productA: metricsA,
      productB: metricsB,
    );
    final comparable = comparison?.comparable ?? false;

    String? compareText;
    if (_unitPriceCompareEnabled &&
        comparison != null &&
        !comparison.comparable) {
      compareText = DashboardCopy.unitPriceCompareInvalid(context);
    } else if (comparable && comparison != null) {
      final pct = comparison.percentDifference?.toStringAsFixed(1) ?? '0.0';
      if (comparison.equalPrice) {
        compareText = DashboardCopy.unitPriceCompareEqual(context);
      } else if (comparison.cheaperProduct == 'a') {
        compareText = DashboardCopy.unitPriceCompareA(context, pct);
      } else if (comparison.cheaperProduct == 'b') {
        compareText = DashboardCopy.unitPriceCompareB(context, pct);
      }
    }

    final normalizedTarget = metricsA?.normalizedTargetLabel ?? '1 base';
    final benchmarkShort = metricsA?.benchmarkShortLabel ?? 'base unit';
    final benchmarkLong = metricsA?.benchmarkLongLabel ?? '1 base unit';

    Widget productResultBlock({
      required String title,
      required double? per100Primary,
      required double? per1kPrimary,
      required double? per100Secondary,
      required double? per1kSecondary,
    }) {
      if (per100Primary == null || per1kPrimary == null) {
        return Text(
          '$title: add valid price and units',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textMuted,
            fontWeight: FontWeight.w700,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _ToolModalThemePolicy.headingTone(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          _TerminalLine(
            prompt: '>',
            input: activePlaceName,
            output:
                '$benchmarkShort: ${_moneyWithCurrency(per100Primary, primaryCurrencyCode)}\n$benchmarkLong: ${_moneyWithCurrency(per1kPrimary, primaryCurrencyCode)}',
            emphasize: true,
            arrowColor: accent,
            lineBreakBeforeOutput: true,
          ),
          if (secondaryCurrencyCode != null &&
              per100Secondary != null &&
              per1kSecondary != null) ...[
            const SizedBox(height: 4),
            _TerminalLine(
              prompt: '>',
              input: oppositePlaceName,
              output:
                  '$benchmarkShort: ${_moneyWithCurrency(per100Secondary, secondaryCurrencyCode)}\n$benchmarkLong: ${_moneyWithCurrency(per1kSecondary, secondaryCurrencyCode)}',
              emphasize: false,
              arrowColor: accent,
              lineBreakBeforeOutput: true,
            ),
          ],
        ],
      );
    }

    return ToolUnitPriceSurface(
      toolId: widget.tool.id,
      coachText: DashboardCopy.unitPriceCoach(
        context,
        primaryCurrency: primaryCurrencyCode,
        secondaryCurrency: secondaryCurrencyCode,
      ),
      currencyContextText: secondaryCurrencyCode == null
          ? null
          : '$activePlaceName ($primaryCurrencyCode) • $oppositePlaceName ($secondaryCurrencyCode)',
      quickSteps: const <(String, IconData)>[
        ('1 Price', Icons.local_offer_rounded),
        ('2 Units', Icons.straighten_rounded),
        ('3 Compare', Icons.compare_arrows_rounded),
      ],
      productA: ToolUnitPriceProductConfig(
        title: DashboardCopy.unitPriceProductTitle(context, isA: true),
        priceController: _unitPriceAController,
        qtyController: _unitQtyAController,
        selectedUnit: _unitPriceUnitA,
        keyPrefix: '${widget.tool.id}_a',
        isPrimaryCard: true,
      ),
      productB: !_unitPriceCompareEnabled
          ? null
          : ToolUnitPriceProductConfig(
              title: DashboardCopy.unitPriceProductTitle(context, isA: false),
              priceController: _unitPriceBController,
              qtyController: _unitQtyBController,
              selectedUnit: _unitPriceUnitB,
              keyPrefix: '${widget.tool.id}_b',
              isPrimaryCard: false,
            ),
      compareEnabled: _unitPriceCompareEnabled,
      compareToggleLabel: DashboardCopy.unitPriceCompareToggle(context),
      swapLabel: DashboardCopy.swapCta(context),
      invalidProductText: DashboardCopy.unitPriceInvalidProductA(context),
      resultChild: perBaseA == null
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
                productResultBlock(
                  title: DashboardCopy.unitPriceProductTitle(
                    context,
                    isA: true,
                  ),
                  per100Primary: per100A,
                  per1kPrimary: per1kA,
                  per100Secondary: per100ASecondary,
                  per1kSecondary: per1kASecondary,
                ),
                const SizedBox(height: 6),
                if (_unitPriceCompareEnabled)
                  productResultBlock(
                    title: DashboardCopy.unitPriceProductTitle(
                      context,
                      isA: false,
                    ),
                    per100Primary: per100B,
                    per1kPrimary: per1kB,
                    per100Secondary: per100BSecondary,
                    per1kSecondary: per1kBSecondary,
                  ),
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
                    'Cost for $normalizedTarget: '
                    '${_moneyWithCurrency(per1kA!, primaryCurrencyCode)} vs '
                    '${_moneyWithCurrency(per1kB!, primaryCurrencyCode)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: panelBg,
        panelBgSoft: panelBgSoft,
        panelBorder: panelBorder,
        textMuted: textMuted,
        headingTone: _ToolModalThemePolicy.headingTone(context),
      ),
      onPriceChanged: (_) => setState(() {}),
      onQtyChanged: (_) => setState(() {}),
      onPickUnit: (keyPrefix, selectedUnit) async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final unit in kUnitPriceUnits)
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
        _handleUnitPriceUnitSelected(
          forProductA: keyPrefix.endsWith('_a'),
          unit: picked,
        );
      },
      onCompareEnabledChanged: (value) {
        setState(() {
          _unitPriceCompareEnabled = value;
          if (_unitPriceCompareEnabled &&
              !unitPriceSameFamily(_unitPriceUnitA, _unitPriceUnitB)) {
            _unitPriceUnitB = unitPriceDefaultFamilyUnitFor(_unitPriceUnitA);
          }
        });
      },
      onSwapProducts: _swapUnitPriceProducts,
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
    final defaults = toolLookupDefaultsFor(widget.tool.canonicalToolId);
    return _lookupFromSystem != (defaults?.fromSystem ?? '') ||
        _lookupToSystem != (defaults?.toSystem ?? '') ||
        _lookupEntryKey != (defaults?.entryKey ?? '');
  }

  Future<void> _pickLookupSystem({required bool isFrom}) async {
    final choices = toolLookupSystemsFor(widget.tool.canonicalToolId);
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
      final row = _lookupEntriesForTool().cast<ToolLookupEntry?>().firstWhere(
        (entry) => entry?.keyId == selected,
        orElse: () => null,
      );
      if (row != null) {
        _lookupGroupKey = toolLookupGroupKeyForRow(
          canonicalToolId: widget.tool.canonicalToolId,
          row: row,
        );
      }
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
    if (_isCurrencyTool) {
      final selected = await _pickCurrencyUnit(isFrom: isFrom);
      if (selected == null || !mounted) return;

      setState(() {
        final oldFrom = _fromCurrencyCode;
        final oldTo = _toCurrencyCode;
        final nextFrom = isFrom ? selected : oldFrom;
        final nextTo = isFrom ? oldTo : selected;
        _currencyFromOverride = nextFrom;
        _currencyToOverride = nextTo;
        _forward = true;
        _seedCurrencySuggestedInput(force: true);
      });
      return;
    }

    final choices = _multiUnitChoices;
    if (choices.isEmpty) return;

    final current = isFrom ? _fromUnitOverride : _toUnitOverride;

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
                        subtitle: null,
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
      if (isFrom) {
        _fromUnitOverride = selected;
      } else {
        _toUnitOverride = selected;
      }
    });
  }

  List<String> _currencySuggestedValues({required bool isFrom}) {
    final current = isFrom ? _fromCurrencyCode : _toCurrencyCode;
    final other = isFrom ? _toCurrencyCode : _fromCurrencyCode;
    final ordered = <String>[
      other,
      _homeCurrencyCode,
      _destinationCurrencyCode,
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
    ];
    final seen = <String>{current};
    final out = <String>[];
    for (final code in ordered) {
      final normalized = code.trim().toUpperCase();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      out.add(normalized);
    }
    return out;
  }

  Future<String?> _pickCurrencyUnit({required bool isFrom}) async {
    final current = isFrom ? _fromCurrencyCode : _toCurrencyCode;
    final side = isFrom ? 'from' : 'to';
    final options = _currencyChoices
        .map(
          (code) => SearchableOptionPickerEntry<String>(
            value: code,
            title: code,
            subtitle: _currencySymbolOrNull(code),
            searchTokens: <String>[code, _currencySymbolOrNull(code) ?? ''],
            key: ValueKey('tool_unit_item_${widget.tool.id}_${side}_$code'),
          ),
        )
        .toList(growable: false);

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SearchableOptionPickerSheet<String>(
        title: DashboardCopy.unitPickerTitle(
          context,
          isCurrencyTool: true,
          isFrom: isFrom,
        ),
        closeTooltip: DashboardCopy.unitPickerCloseTooltip(context),
        searchHint: DashboardCopy.unitPickerSearchHint(
          context,
          isCurrencyTool: true,
        ),
        noMatchesText: DashboardCopy.unitPickerNoMatchesHint(context),
        selectedHeader: DashboardCopy.unitPickerSelectedHeader(context),
        suggestedHeader: DashboardCopy.unitPickerSuggestedHeader(context),
        allHeader: DashboardCopy.unitPickerAllHeader(
          context,
          isCurrencyTool: true,
        ),
        selectedValue: current,
        suggestedValues: _currencySuggestedValues(isFrom: isFrom),
        options: options,
        listKey: ValueKey('tool_unit_picker_currency_convert_$side'),
        searchFieldKey: ValueKey(
          'tool_unit_picker_search_currency_convert_$side',
        ),
      ),
    );
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

      final from = _fromCurrencyCode;
      final to = _toCurrencyCode;

      double out;
      if (from == to) {
        out = value;
      } else {
        final pairRate = widget.currencyRateForPair?.call(from, to);
        if (pairRate != null && pairRate > 0) {
          out = value * pairRate;
        } else {
          _showNotice(
            DashboardCopy.currencyRateUnavailableNotice(context),
            UnitanaNoticeKind.error,
          );
          return;
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

  double? _currentPaceMinutes() {
    final fromInput = parsePaceMinutesValue(_controller.text);
    if (fromInput != null) return fromInput;
    final latest = widget.session.latestFor(widget.tool.id);
    if (latest == null) return null;
    return parsePaceMinutesValue(_stripKnownUnitSuffix(latest.inputLabel));
  }

  double? _currentPacePerKmMinutes() {
    if (widget.tool.id != 'pace') return null;
    return normalizePaceToPerKmMinutes(
      inputMinutes: _currentPaceMinutes(),
      fromUnit: _fromUnit,
    );
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
    final goalResult = computePaceGoalResult(
      goalDurationMinutes: parseDurationMinutesValue(
        _paceGoalTimeController.text,
      ),
      goalDistanceKm: _paceGoalDistanceKm,
    );
    final raceTargets = paceProjectionTargetsForMode(_paceMode);
    final builderResult = computePaceBuilderResult(
      distance: parsePositiveDouble(_paceBuilderDistanceController.text),
      distanceUnit: _paceBuilderDistanceUnit,
      durationMinutes: parseDurationMinutesValue(
        _paceBuilderTimeController.text,
      ),
    );

    return ToolPaceInsightsSurface(
      paceMode: _paceMode,
      builderDistanceUnit: _paceBuilderDistanceUnit,
      builderDistanceController: _paceBuilderDistanceController,
      builderTimeController: _paceBuilderTimeController,
      goalTimeController: _paceGoalTimeController,
      currentPerKm: perKm,
      currentPerMi: perMi,
      currentKmh: kmh,
      currentMph: mph,
      raceTargets: raceTargets,
      builderResult: builderResult,
      goalTargets: paceGoalTargetsForMode(_paceMode),
      selectedGoalDistanceKm: _paceGoalDistanceKm,
      goalResult: goalResult,
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: panelBg,
        panelBgSoft: _ToolModalThemePolicy.panelBgSoft(context),
        panelBorder: panelBorder,
        textMuted: textMuted,
        headingTone: headingTone,
      ),
      emptyGoalText:
          'Enter a goal time to see required pace and split checkpoints.',
      onModeChanged: (next) {
        setState(() {
          _paceMode = next;
          if (_paceMode == PaceActivityMode.rowing &&
              _paceGoalDistanceKm > 10) {
            _paceGoalDistanceKm = defaultPaceGoalDistanceKmForMode(_paceMode);
          }
        });
      },
      onBuilderDistanceChanged: (_) => setState(() {}),
      onBuilderUnitChanged: (unit) => setState(() {
        _paceBuilderDistanceUnit = unit;
      }),
      onBuilderTimeChanged: (_) => setState(() {}),
      onApplyBuilderResult: () {
        if (builderResult == null) return;
        setState(() {
          _controller.text = formatPace(
            builderResult.minutesForInputUnit(_fromUnit),
          );
        });
      },
      onGoalDistanceChanged: (km) => setState(() {
        _paceGoalDistanceKm = km;
      }),
      onGoalTimeChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEnergyPlannerCard(BuildContext context, Color accent) {
    final energySnapshot = computeEnergySnapshot(
      weightRaw: parsePositiveDouble(_energyWeightController.text),
      weightUnit: _energyWeightUnit,
      activityLevel: _energyActivity,
    );

    return ToolEnergyPlannerSurface(
      weightController: _energyWeightController,
      weightUnit: _energyWeightUnit,
      activityLevel: _energyActivity,
      activityHelpText: DashboardCopy.energyActivityHelp(
        context,
        activityLevel: _energyActivity,
      ),
      estimateSummary: energySnapshot == null
          ? null
          : 'Estimated maintenance: ${energySnapshot.maintenanceCalories.round()} kcal (${energySnapshot.maintenanceKilojoules.round()} kJ)\n'
                'Cut target: ${energySnapshot.cutCalories.round()} kcal • Gain target: ${energySnapshot.gainCalories.round()} kcal',
      emptyPrompt: 'Enter body weight to estimate rough daily energy needs.',
      theme: ToolHelperSurfaceTheme(
        accent: accent,
        panelBg: _ToolModalThemePolicy.panelBg(context),
        panelBgSoft: _ToolModalThemePolicy.panelBgSoft(context),
        panelBorder: _ToolModalThemePolicy.panelBorder(context),
        textMuted: _ToolModalThemePolicy.textMuted(context),
        headingTone: _ToolModalThemePolicy.headingTone(context),
      ),
      onWeightChanged: (_) => setState(() {}),
      onSelectWeightUnit: (nextUnit) => setState(() {
        _convertDisplayedWeightInput(
          _energyWeightController,
          fromUnit: _energyWeightUnit,
          toUnit: nextUnit,
        );
        _energyWeightUnit = nextUnit;
      }),
      onSelectActivity: (activity) => setState(() {
        _energyActivity = activity;
      }),
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

  Widget _buildLookupBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    final row = _activeLookupEntry();
    final from = _lookupFromSystem;
    final to = _lookupToSystem;
    if (row == null || from == null || to == null) {
      return const SizedBox.shrink();
    }

    Future<void> copyLookupCell({
      required String value,
      required String label,
      ToolLookupEntry? row,
      String? system,
    }) async {
      final copiedLabel = DashboardCopy.copiedNotice(context, label);
      final normalized = value.trim();
      await Clipboard.setData(ClipboardData(text: normalized));
      if (row != null &&
          system != null &&
          toolLookupShouldPersistMatrixSelection(widget.tool.canonicalToolId)) {
        await widget.session.setMatrixWidgetSelection(
          toolId: widget.tool.id,
          rowKey: row.keyId,
          system: system,
          value: normalized,
          referenceLabel: toolLookupReferenceLabel(
            canonicalToolId: widget.tool.canonicalToolId,
            row: row,
          ),
          primaryLabel: normalized,
          secondaryLabel:
              '$system • ${toolLookupReferenceLabel(canonicalToolId: widget.tool.canonicalToolId, row: row)}',
        );
      }
      if (!mounted) return;
      _showNotice(copiedLabel, UnitanaNoticeKind.info);
    }

    return ToolLookupWorkspace(
      toolId: widget.tool.id,
      canonicalToolId: widget.tool.canonicalToolId,
      isFullMatrix: _isFullMatrixLookupTool,
      isClothingLookupTool: _isClothingLookupTool,
      hasCustomSelection: _hasCustomLookupSelection,
      selectedRow: row,
      rows: _visibleLookupEntriesForTool(),
      selectedClothingGroupKey: _lookupGroupKey,
      fromSystem: from,
      toSystem: to,
      matrixPageIndex: _lookupMatrixPageIndex,
      theme: ToolLookupSurfaceTheme(
        accent: accent,
        panelBg: panelBg,
        panelBorder: panelBorder,
        textPrimary: textPrimary,
        textMuted: textMuted,
        headingTone: headingTone,
        selectedTone: _ToolModalThemePolicy.dangerTone(context),
        successTone: _ToolModalThemePolicy.successTone(context),
      ),
      onPickFromSystem: () => _pickLookupSystem(isFrom: true),
      onPickToSystem: () => _pickLookupSystem(isFrom: false),
      onSwapSystems: _swapLookupSystems,
      onPickEntry: _pickLookupEntry,
      onResetSelection: _resetUnitSelectionToDefaults,
      onMatrixPageChanged: (pageIndex) {
        setState(() {
          _lookupMatrixPageIndex = pageIndex;
        });
      },
      onSelectClothingGroup: (groupKey) {
        setState(() {
          _lookupGroupKey = groupKey;
          final matchingRows = toolLookupEntriesForGroup(
            canonicalToolId: widget.tool.canonicalToolId,
            rows: _lookupEntriesForTool(),
            groupKey: groupKey,
          );
          final currentEntryKey = _lookupEntryKey;
          final stillVisible = matchingRows.any(
            (entry) => entry.keyId == currentEntryKey,
          );
          if (!stillVisible && matchingRows.isNotEmpty) {
            _lookupEntryKey = matchingRows.first.keyId;
          }
          _lookupMatrixPageIndex = 0;
        });
      },
      onSelectEntry: (entryKey) {
        setState(() {
          _lookupEntryKey = entryKey;
          final row = _lookupEntriesForTool()
              .cast<ToolLookupEntry?>()
              .firstWhere(
                (entry) => entry?.keyId == entryKey,
                orElse: () => null,
              );
          if (row != null) {
            _lookupGroupKey = toolLookupGroupKeyForRow(
              canonicalToolId: widget.tool.canonicalToolId,
              row: row,
            );
          }
        });
      },
      onCopyValue:
          ({
            required String value,
            required String label,
            required ToolLookupEntry row,
            required String system,
          }) {
            return copyLookupCell(
              value: value,
              label: label,
              row: row,
              system: system,
            );
          },
      lookupValue: (row, system) => _lookupValue(row: row, system: system),
      sanitizeUnitKey: _sanitizeUnitKey,
    );
  }

  List<TimeZoneOption> _timeZoneOptions() {
    return TimeZoneCatalog.options(
      home: widget.home,
      destination: widget.destination,
    );
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
    final out = searchTimeZoneCityOptions(
      rawQuery: rawQuery,
      featured: featured,
      allEntries: allEntries,
      featuredEntries: featuredEntries,
      home: widget.home,
      destination: widget.destination,
    );
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
    final out = searchTimeZoneOptions(
      rawQuery: query,
      entries: entries,
      home: widget.home,
      destination: widget.destination,
    );
    PickerPerfTrace.logElapsed(
      'time_zone_filter',
      sw,
      extra: 'query="$normalized" results=${out.length}',
      minMs: 6,
    );
    return out;
  }

  void _seedTimeToolDefaults() {
    final options = _timeZoneOptions();
    final defaults = resolveTimeToolDefaults(
      options: options,
      home: widget.home,
      destination: widget.destination,
      reality: widget.session.reality,
      savedSelection: widget.session.timeZoneSelectionFor(widget.tool.id),
      isJetLagTool: _isJetLagDeltaTool,
    );
    _timeFromZoneId = defaults.fromZoneId;
    _timeToZoneId = defaults.toZoneId;
    _timeFromDisplayLabel = defaults.fromDisplayLabel;
    _timeToDisplayLabel = defaults.toDisplayLabel;
  }

  void _persistTimeZoneSelection() {
    final fromId = _timeFromZoneId?.trim();
    final toId = _timeToZoneId?.trim();
    if (fromId == null || toId == null || fromId.isEmpty || toId.isEmpty) {
      return;
    }
    if (fromId == toId) return;
    unawaited(
      widget.session.setTimeZoneSelection(
        toolId: widget.tool.id,
        fromZoneId: fromId,
        toZoneId: toId,
      ),
    );
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
        final rebased = rebaseTimeConverterInput(
          rawInput: _timeConvertController.text,
          oldFromZoneId: oldFrom,
          newFromZoneId: _timeFromZoneId!,
        );
        if (rebased == null) {
          _seedTimeConverterInput();
        } else {
          _timeConvertController.text = rebased;
        }
      }
    });
    _persistTimeZoneSelection();
  }

  void _seedTimeConverterInput() {
    final fromId = _timeFromZoneId;
    if (fromId == null) return;
    final nowLocal = TimezoneUtils.nowInZone(fromId).local;
    _timeConvertController.text = formatLocalDateTime(nowLocal);
  }

  void _runTimeZoneConversion() {
    final fromId = _timeFromZoneId;
    final toId = _timeToZoneId;
    if (fromId == null || toId == null) return;

    final conversion = convertTimeZoneInput(
      rawInput: _timeConvertController.text,
      fromZoneId: fromId,
      toZoneId: toId,
      use24h: widget.prefer24h,
    );
    if (conversion == null) {
      _showNotice(
        DashboardCopy.timeConverterInputError(context),
        UnitanaNoticeKind.error,
      );
      return;
    }

    final record = ConversionRecord(
      toolId: widget.tool.id,
      lensId: widget.tool.lensId,
      fromUnit: fromId,
      toUnit: toId,
      inputLabel: '${conversion.inputLabel} ($fromId)',
      outputLabel: '${conversion.outputLabel} ($toId)',
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
    final featuredCityOptions = featuredTimeZoneCityOptions(
      cityOptions: allCityOptions,
      home: widget.home,
      destination: widget.destination,
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
                                displayLabel: displayLabelForZone(
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
                                displayLabel: displayLabelForZone(
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
                                displayLabel: displayLabelForZone(
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
                                displayLabel: displayLabelForZone(
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
                                          ? CityLabelUtils.cleanTimeZoneLabel(
                                              option.timeZoneId,
                                            )
                                          : '${option.subtitle} · ${CityLabelUtils.cleanTimeZoneLabel(option.timeZoneId)}',
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
                                        option.subtitle ??
                                            CityLabelUtils.cleanTimeZoneLabel(
                                              option.id,
                                            ),
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
          _timeToDisplayLabel = displayLabelForZone(alt, zoneOptions);
        } else {
          _timeFromZoneId = alt;
          _timeFromDisplayLabel = displayLabelForZone(alt, zoneOptions);
        }
      }
      _jetLagOverlapExpanded = false;
      if (_isTimeZoneConverterTool &&
          isFrom &&
          previousFrom != null &&
          _timeFromZoneId != null) {
        final rebased = rebaseTimeConverterInput(
          rawInput: _timeConvertController.text,
          oldFromZoneId: previousFrom,
          newFromZoneId: _timeFromZoneId!,
        );
        if (rebased == null) {
          _seedTimeConverterInput();
        } else {
          _timeConvertController.text = rebased;
        }
      }
    });
    _persistTimeZoneSelection();
  }

  Widget _buildTimeToolBody(BuildContext context, Color accent) {
    final panelBg = _ToolModalThemePolicy.panelBg(context);
    final panelBorder = _ToolModalThemePolicy.panelBorder(context);
    final textPrimary = _ToolModalThemePolicy.textPrimary(context);
    final textMuted = _ToolModalThemePolicy.textMuted(context);
    final headingTone = _ToolModalThemePolicy.headingTone(context);
    final infoTone = _ToolModalThemePolicy.infoTone(context);
    final warningTone = _ToolModalThemePolicy.warningTone(context);
    final theme = ToolTimeSurfaceTheme(
      accent: accent,
      panelBg: panelBg,
      panelBorder: panelBorder,
      textPrimary: textPrimary,
      textMuted: textMuted,
      headingTone: headingTone,
      infoTone: infoTone,
      warningTone: warningTone,
      successTone: _ToolModalThemePolicy.successTone(context),
      dangerTone: _ToolModalThemePolicy.dangerTone(context),
    );

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
    return ToolTimeWorkspace(
      toolId: widget.tool.id,
      home: widget.home,
      destination: widget.destination,
      prefer24h: widget.prefer24h,
      isJetLagDeltaTool: _isJetLagDeltaTool,
      isWorldClockMapTool: _isWorldClockMapTool,
      isTimeZoneConverterTool: _isTimeZoneConverterTool,
      showAddWidget: widget.canAddWidget && widget.onAddWidget != null,
      fromZoneId: _timeFromZoneId!,
      toZoneId: _timeToZoneId!,
      fromDisplayLabelOverride: _timeFromDisplayLabel,
      toDisplayLabelOverride: _timeToDisplayLabel,
      options: options,
      history: widget.session.historyFor(widget.tool.id),
      timeConvertController: _timeConvertController,
      resultLine: _resultLine,
      jetLagBedtimeMinutes: _jetLagBedtimeMinutes,
      jetLagWakeMinutes: _jetLagWakeMinutes,
      jetLagOverlapExpanded: _jetLagOverlapExpanded,
      jetLagTipsAutoRotateEnabled: _jetLagTipsAutoRotateEnabled,
      jetLagTipIndex: _jetLagTipIndex,
      theme: theme,
      onPickFromZone: () => _pickTimeZone(isFrom: true),
      onPickToZone: () => _pickTimeZone(isFrom: false),
      onSwapZones: _swapTimeZones,
      onAddWidget: _handleAddWidget,
      onRunConversion: _runTimeZoneConversion,
      onClearHistory: () async {
        final historyClearedLabel = DashboardCopy.historyClearedNotice(context);
        final confirmed = await _confirmClearHistory(context);
        if (!confirmed) return;
        widget.session.clearHistory(widget.tool.id);
        _showNotice(historyClearedLabel, UnitanaNoticeKind.success);
      },
      onPickBedtime: () => _pickJetLagTime(bedtime: true),
      onPickWakeTime: () => _pickJetLagTime(bedtime: false),
      onExpandOverlap: () {
        setState(() {
          _jetLagOverlapExpanded = true;
        });
      },
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
    final cadenceLabel = _currencyCadenceLabel(widget.currencyRefreshCadence);
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
        'Using saved rates from $lastSavedLabel. Auto-refresh target: every $cadenceLabel.',
        _ToolModalThemePolicy.textMuted(context),
        false,
      );
    }

    return (
      'Using saved rates. Auto-refresh target: every $cadenceLabel.',
      _ToolModalThemePolicy.textMuted(context),
      false,
    );
  }

  String _currencyCadenceLabel(Duration cadence) {
    final minutes = cadence.inMinutes;
    if (minutes <= 0) return 'few minutes';
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? 'hour' : '$hours hours';
    }
    return minutes == 1 ? 'minute' : '$minutes minutes';
  }

  Future<void> _handleAddWidget() async {
    if (widget.onAddWidget == null) return;
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

  Future<void> _copyHistoryResult(ConversionRecord record) async {
    final toCopy = _stripKnownUnitSuffix(record.outputLabel);
    await Clipboard.setData(ClipboardData(text: toCopy));
    if (!mounted) return;
    _showNotice(
      DashboardCopy.copiedResultNotice(context),
      UnitanaNoticeKind.success,
    );
  }

  Future<void> _copyHistoryInput(ConversionRecord record) async {
    final preservedText = _controller.text;
    final raw = _stripKnownUnitSuffix(record.inputLabel);
    final toCopy = _trimTrailingZerosForClipboard(raw);
    await Clipboard.setData(ClipboardData(text: toCopy));
    if (!mounted) return;

    if (_controller.text != preservedText) {
      _controller
        ..text = preservedText
        ..selection = TextSelection.collapsed(offset: preservedText.length);
    }
    _showNotice(
      DashboardCopy.copiedInputNotice(context),
      UnitanaNoticeKind.success,
    );
  }

  Future<void> _clearToolHistory() async {
    if (widget.session.historyFor(widget.tool.id).isEmpty) return;
    final historyClearedLabel = DashboardCopy.historyClearedNotice(context);
    final ok = await _confirmClearHistory(context);
    if (!ok || !mounted) return;

    widget.session.clearHistory(widget.tool.id);
    setState(() {
      _controller.clear();
      _resultLine = null;
    });
    _showNotice(historyClearedLabel, UnitanaNoticeKind.success);
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

  List<Widget> _defaultPostSections(Color accent) {
    final disclaimer = _toolDisclaimerCopy(context);
    return <Widget>[
      if (widget.tool.id == 'pace') _buildPaceInsightsCard(context, accent),
      if (widget.tool.id == 'energy') _buildEnergyPlannerCard(context, accent),
      if (disclaimer != null)
        _buildDisclaimerCard(
          context,
          key: ValueKey('tool_disclaimer_${widget.tool.id}'),
          text: disclaimer,
        ),
    ];
  }

  Widget _buildDefaultToolBody({
    required Color accent,
    required Color textMuted,
    required Color panelBg,
    required Color panelBorder,
  }) {
    final history = widget.session.historyFor(widget.tool.id);
    final numericPolicy = ToolNumericPolicies.forToolId(widget.tool.id);
    final theme = ToolDefaultSurfaceTheme(
      accent: accent,
      textPrimary: _ToolModalThemePolicy.textPrimary(context),
      textMuted: textMuted,
      panelBg: panelBg,
      panelBorder: panelBorder,
      headingTone: _ToolModalThemePolicy.headingTone(context),
      warningTone: _ToolModalThemePolicy.warningTone(context),
      successTone: _ToolModalThemePolicy.successTone(context),
    );
    return ToolDefaultWorkspace(
      toolId: widget.tool.id,
      controller: _controller,
      requiresFreeformInput: _requiresFreeformInput,
      numericPolicy: numericPolicy,
      inputHint: _toolInputHint(context),
      helperText: _toolInputCoachCopy(context),
      supportsUnitPicker: _supportsUnitPicker,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
      showBakingHint: widget.tool.id == 'baking',
      hasCustomUnitSelection: _hasCustomUnitSelection,
      canAddWidget: widget.canAddWidget && widget.onAddWidget != null,
      theme: theme,
      editValueLabel: DashboardCopy.editValueLabel(context),
      convertLabel: DashboardCopy.convertCta(context),
      addWidgetLabel: DashboardCopy.addWidgetCta(context),
      resetDefaultsLabel: DashboardCopy.lookupResetDefaults(context),
      resultLine: _resultLine,
      history: history,
      historyTitle: DashboardCopy.historyTitle(context),
      historyCopyHint: DashboardCopy.historyCopyHint(context),
      clearHistoryLabel: DashboardCopy.clearHistoryButtonLabel(context),
      emptyHistoryLabel: DashboardCopy.historyEmptyLabel(context),
      resultPlaceholderInput: DashboardCopy.resultPlaceholderInput(context),
      resultPlaceholderOutput: DashboardCopy.resultPlaceholderOutput(context),
      onRunConversion: _runConversion,
      onSwapUnits: _swapUnits,
      onPickFromUnit: () => _pickUnit(isFrom: true),
      onPickToUnit: () => _pickUnit(isFrom: false),
      onResetDefaults: _resetUnitSelectionToDefaults,
      onAddWidget: _handleAddWidget,
      onCopyResult: _copyHistoryResult,
      onCopyInput: _copyHistoryInput,
      onClearHistory: _clearToolHistory,
      extraSections: _defaultPostSections(accent),
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
