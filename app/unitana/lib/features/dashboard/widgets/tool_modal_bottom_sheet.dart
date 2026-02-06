import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/unitana_notice_card.dart';
import '../../../data/cities.dart' show kCurrencySymbols;
import '../../../data/country_currency_map.dart';
import '../../../theme/dracula_palette.dart';
import '../../../models/place.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_exceptions.dart';
import '../models/lens_accents.dart';
import '../models/numeric_input_policy.dart';
import '../models/tool_definitions.dart';
import '../models/canonical_tools.dart';

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
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: DraculaPalette.foreground,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
    );

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(
            text: prompt,
            style: base?.copyWith(
              color: DraculaPalette.green,
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

class _ToolModalBottomSheetState extends State<ToolModalBottomSheet> {
  // MVP: Currency tool supports EUR ↔ USD, using a live/demo EUR→USD rate.
  // We infer a default direction from home vs destination when context is
  // provided by the dashboard.
  //
  // NOTE: This is intentionally small-scope and does not attempt a full
  // multi-currency system.

  final TextEditingController _controller = TextEditingController();
  Timer? _noticeTimer;
  String? _noticeText;
  UnitanaNoticeKind _noticeKind = UnitanaNoticeKind.success;

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

  bool get _isMultiUnitTool =>
      widget.tool.canonicalToolId == CanonicalToolId.volume ||
      widget.tool.canonicalToolId == CanonicalToolId.pressure ||
      widget.tool.canonicalToolId == CanonicalToolId.weight;
  bool get _supportsUnitPicker => _isMultiUnitTool || _isCurrencyTool;

  List<String> get _multiUnitChoices {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.volume:
        return const <String>['mL', 'L', 'pt', 'qt', 'gal'];
      case CanonicalToolId.pressure:
        return const <String>['kPa', 'psi', 'bar', 'atm'];
      case CanonicalToolId.weight:
        return const <String>['g', 'kg', 'oz', 'lb', 'st'];
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

    if (_isMultiUnitTool) {
      _seedMultiUnitOverrides();
    }

    final latest = widget.session.latestFor(widget.tool.id);
    if (latest != null) {
      _resultLine = '${latest.inputLabel}  →  ${latest.outputLabel}';
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _swapUnits() {
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
      default:
        _fromUnitOverride = null;
        _toUnitOverride = null;
        return;
    }
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
      default:
        return ('', '');
    }
  }

  void _resetUnitSelectionToDefaults() {
    setState(() {
      if (_isCurrencyTool) {
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
                        _isCurrencyTool
                            ? (isFrom ? 'From Currency' : 'To Currency')
                            : (isFrom ? 'From Unit' : 'To Unit'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DraculaPalette.foreground,
                            ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey(
                        'tool_unit_picker_close_${widget.tool.id}_${isFrom ? 'from' : 'to'}',
                      ),
                      tooltip: 'Close',
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
                                color: DraculaPalette.foreground,
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
                                          color: DraculaPalette.comment,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  );
                                },
                              )
                            : null,
                        trailing: (u == current)
                            ? Icon(
                                Icons.check_rounded,
                                color: DraculaPalette.purple,
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
    final decision = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear history?',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'This removes the last 10 conversions for this tool.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return decision ?? false;
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
      case 'temperature':
        return _forward ? '°C' : '°F';
      case 'time':
        return _forward ? '24h' : '12h';
      case 'height':
        return _forward ? 'cm' : 'ft/in';
      case 'baking':
        return _forward ? 'cup' : 'ml';
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
      case 'temperature':
        return _forward ? '°F' : '°C';
      case 'time':
        return _forward ? '12h' : '24h';
      case 'height':
        return _forward ? 'ft/in' : 'cm';
      case 'baking':
        return _forward ? 'ml' : 'cup';
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

    final result = _isMultiUnitTool
        ? ToolConverters.convertWithUnits(
            toolId: widget.tool.canonicalToolId,
            fromUnit: _fromUnit,
            toUnit: _toUnit,
            input: input,
          )
        : ToolConverters.convert(
            toolId: widget.tool.canonicalToolId,
            lensId: widget.tool.lensId,
            forward: _forward,
            input: input,
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
        widget.tool.id == 'time';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        // Some tools may not have a lensId (legacy or internal tools). Fall back
        // to the default accent mapping rather than failing compilation.
        final accent = LensAccents.iconTintFor(widget.tool.lensId ?? '');
        final viewInsets = MediaQuery.of(context).viewInsets;
        final history = widget.session.historyFor(widget.tool.id);
        final numericPolicy = ToolNumericPolicies.forToolId(widget.tool.id);

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.85,
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  Padding(
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
                                    widget.tool.title,
                                    key: ValueKey(
                                      'tool_title_${widget.tool.id}',
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.fade,
                                    style:
                                        (Theme.of(
                                                  context,
                                                ).textTheme.headlineSmall ??
                                                const TextStyle())
                                            .merge(
                                              GoogleFonts.robotoSlab(
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    DraculaPalette.foreground,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Close',
                          child: OutlinedButton(
                            key: ValueKey('tool_close_${widget.tool.id}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: DraculaPalette.comment.withAlpha(160),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DraculaPalette.foreground.withAlpha(220),
                            ),
                          ),
                        ),
                      ],
                    ),
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

                  // Body (scrollable to prevent overflow on smallest sizes)
                  Expanded(
                    child: ListView(
                      key: ValueKey('tool_scroll_${widget.tool.id}'),
                      // Cache more offscreen content so widget tests can locate
                      // history items reliably on small surfaces.
                      cacheExtent: 1200,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        // Calculator (top half)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // The smallest supported test surface (320px wide) can
                            // overflow if we force the Convert button to live on
                            // the same row as the input. When tight, stack Convert
                            // below the editor to keep the layout green.
                            final isNarrow = constraints.maxWidth <= 340;

                            final inputBlock = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Value',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: DraculaPalette.comment),
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
                                          NumericTextInputFormatter(
                                            policy: numericPolicy,
                                          ),
                                        ],
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Value',
                                  ),
                                  onSubmitted: (_) => _runConversion(),
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final canAdd =
                                        widget.canAddWidget &&
                                        widget.onAddWidget != null;

                                    // Keep units + swap on the first row and move Add Widget
                                    // onto its own line when space is tight.
                                    final isNarrow =
                                        constraints.maxWidth <= 320;

                                    Widget buildUnitsAndSwap() {
                                      final Widget unitsWidget =
                                          _supportsUnitPicker
                                          ? Row(
                                              key: ValueKey(
                                                'tool_units_${widget.tool.id}',
                                              ),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                OutlinedButton(
                                                  key: ValueKey(
                                                    'tool_unit_from_${widget.tool.id}',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size(
                                                      0,
                                                      34,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 0,
                                                        ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    side: BorderSide(
                                                      color: DraculaPalette
                                                          .comment
                                                          .withAlpha(160),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _pickUnit(isFrom: true),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _fromUnit,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: accent,
                                                            ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .arrow_drop_down_rounded,
                                                        color: accent.withAlpha(
                                                          220,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    '→',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: accent,
                                                        ),
                                                  ),
                                                ),
                                                OutlinedButton(
                                                  key: ValueKey(
                                                    'tool_unit_to_${widget.tool.id}',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size(
                                                      0,
                                                      34,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 0,
                                                        ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    side: BorderSide(
                                                      color: DraculaPalette
                                                          .comment
                                                          .withAlpha(160),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _pickUnit(isFrom: false),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _toUnit,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: accent,
                                                            ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .arrow_drop_down_rounded,
                                                        color: accent.withAlpha(
                                                          220,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '$_fromUnit → $_toUnit',
                                              key: ValueKey(
                                                'tool_units_${widget.tool.id}',
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: accent,
                                                  ),
                                              overflow: TextOverflow.visible,
                                              softWrap: false,
                                            );

                                      final swapButton = OutlinedButton(
                                        key: ValueKey(
                                          'tool_swap_${widget.tool.id}',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(34, 34),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(
                                            color: DraculaPalette.comment
                                                .withAlpha(160),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: _swapUnits,
                                        child: PulseSwapIcon(
                                          color: accent.withAlpha(220),
                                          size: 18,
                                        ),
                                      );

                                      return Row(
                                        key: ValueKey(
                                          'tool_units_row_${widget.tool.id}',
                                        ),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: unitsWidget,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          swapButton,
                                        ],
                                      );
                                    }

                                    Widget buildAddWidgetButton() {
                                      return OutlinedButton.icon(
                                        key: ValueKey(
                                          'tool_add_widget_${widget.tool.id}',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 34),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(
                                            color: DraculaPalette.comment
                                                .withAlpha(160),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          try {
                                            await widget.onAddWidget!.call();
                                            if (!mounted) return;
                                            _showNotice(
                                              'Added ${widget.tool.title} to dashboard',
                                              UnitanaNoticeKind.success,
                                            );
                                          } on DuplicateDashboardWidgetException catch (
                                            _
                                          ) {
                                            if (!mounted) return;
                                            _showNotice(
                                              '${widget.tool.title} is already on your dashboard',
                                              UnitanaNoticeKind.info,
                                            );
                                          } catch (_) {
                                            if (!mounted) return;
                                            _showNotice(
                                              'Could not add widget',
                                              UnitanaNoticeKind.error,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          size: 18,
                                          color: accent,
                                        ),
                                        label: Text(
                                          '+ Add Widget',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
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
                                          key: ValueKey(
                                            'tool_units_reset_${widget.tool.id}',
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                          ),
                                          onPressed: _hasCustomUnitSelection
                                              ? _resetUnitSelectionToDefaults
                                              : null,
                                          icon: const Icon(
                                            Icons.restart_alt_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Reset Defaults'),
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: buildUnitsAndSwap(),
                                            ),
                                            if (canAdd && !isNarrow) ...[
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: buildAddWidgetButton(),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (_supportsUnitPicker) ...[
                                          const SizedBox(height: 4),
                                          buildResetDefaultsButton(),
                                        ],
                                        if (canAdd && isNarrow) ...[
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: buildAddWidgetButton(),
                                          ),
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
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                                onPressed: _runConversion,
                                child: const Text('Convert'),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  inputBlock,
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: convertButton,
                                  ),
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
                        ),

                        const SizedBox(height: 12),

                        _ResultCard(
                          toolId: widget.tool.id,
                          lensId: widget.tool.lensId,
                          line: _resultLine,
                        ),

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
                                'History',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: DraculaPalette.purple,
                                    ),
                              ),
                              Text(
                                'tap copies result; long-press copies input',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: DraculaPalette.comment.withAlpha(
                                        220,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: math.min(
                            MediaQuery.sizeOf(context).height * 0.28,
                            280.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: DraculaPalette.currentLine,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: DraculaPalette.comment.withAlpha(160),
                              ),
                            ),
                            child: history.isEmpty
                                ? const _EmptyHistory()
                                : ListView.builder(
                                    key: ValueKey(
                                      'tool_history_list_${widget.tool.id}',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
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
                                        key: ValueKey(
                                          'tool_history_${widget.tool.id}_$index',
                                        ),
                                        onTap: () async {
                                          final toCopy = _stripKnownUnitSuffix(
                                            r.outputLabel,
                                          );
                                          await Clipboard.setData(
                                            ClipboardData(text: toCopy),
                                          );
                                          if (!mounted) return;
                                          _showNotice(
                                            'Copied result',
                                            UnitanaNoticeKind.success,
                                          );
                                        },
                                        onLongPress: () async {
                                          final preservedText =
                                              _controller.text;

                                          final raw = _stripKnownUnitSuffix(
                                            r.inputLabel,
                                          );
                                          final toCopy =
                                              _trimTrailingZerosForClipboard(
                                                raw,
                                              );
                                          await Clipboard.setData(
                                            ClipboardData(text: toCopy),
                                          );
                                          if (!mounted) return;

                                          // Guard against accidental "restore/edit" regressions.
                                          if (_controller.text !=
                                              preservedText) {
                                            _controller
                                              ..text = preservedText
                                              ..selection =
                                                  TextSelection.collapsed(
                                                    offset:
                                                        preservedText.length,
                                                  );
                                          }
                                          _showNotice(
                                            'Copied input',
                                            UnitanaNoticeKind.success,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            10,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _TerminalLine(
                                                      prompt: '>',
                                                      input: inputLabel,
                                                      output: outputLabel,
                                                      emphasize: isMostRecent,
                                                      arrowColor: isMostRecent
                                                          ? DraculaPalette
                                                                .purple
                                                          : DraculaPalette
                                                                .comment,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      timestamp,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color:
                                                                DraculaPalette
                                                                    .comment,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.copy_rounded,
                                                size: 16,
                                                color: DraculaPalette.comment
                                                    .withAlpha(200),
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
                                    final ok = await _confirmClearHistory(
                                      context,
                                    );
                                    if (!ok || !mounted) return;

                                    widget.session.clearHistory(widget.tool.id);
                                    setState(() {
                                      _controller.clear();
                                      _resultLine = null;
                                    });
                                    _showNotice(
                                      'History cleared',
                                      UnitanaNoticeKind.success,
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFFFBBF24),
                            ),
                            child: Text(
                              'Clear History',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: const Color(0xFFFBBF24)),
                            ),
                          ),
                        ),
                      ],
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
    final accent = LensAccents.iconTintFor(lensId ?? '');

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
        color: DraculaPalette.currentLine,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No history yet',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: DraculaPalette.comment,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
