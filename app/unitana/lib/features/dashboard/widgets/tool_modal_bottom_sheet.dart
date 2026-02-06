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
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_exceptions.dart';
import '../models/lens_accents.dart';
import '../models/numeric_input_policy.dart';
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

class _ToolModalBottomSheetState extends State<ToolModalBottomSheet> {
  // MVP: Currency tool supports EUR ↔ USD, using a live/demo EUR→USD rate.
  // We infer a default direction from home vs destination when context is
  // provided by the dashboard.
  //
  // NOTE: This is intentionally small-scope and does not attempt a full
  // multi-currency system.

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _timeConvertController = TextEditingController();
  Timer? _noticeTimer;
  Timer? _timeTicker;
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
  String? _lookupFromSystem;
  String? _lookupToSystem;
  String? _lookupEntryKey;
  String? _timeFromZoneId;
  String? _timeToZoneId;
  List<int> _tipPresetPercents = const <int>[10, 15, 20];
  int _tipPercent = 15;
  int _tipSplitCount = 1;
  String _tipRoundingMode = 'none';

  bool get _isMultiUnitTool =>
      widget.tool.canonicalToolId == CanonicalToolId.volume ||
      widget.tool.canonicalToolId == CanonicalToolId.pressure ||
      widget.tool.canonicalToolId == CanonicalToolId.weight ||
      widget.tool.canonicalToolId == CanonicalToolId.dataStorage;
  bool get _isLookupTool =>
      widget.tool.canonicalToolId == CanonicalToolId.shoeSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.paperSizes ||
      widget.tool.canonicalToolId == CanonicalToolId.mattressSizes;
  bool get _isTipHelperTool => widget.tool.id == 'tip_helper';
  bool get _isTimeTool =>
      widget.tool.canonicalToolId == CanonicalToolId.time ||
      widget.tool.id == 'time';
  bool get _isTimeZoneConverterTool => widget.tool.id == 'time_zone_converter';
  bool get _supportsUnitPicker => _isMultiUnitTool || _isCurrencyTool;

  List<String> get _multiUnitChoices {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.volume:
        return const <String>['mL', 'L', 'pt', 'qt', 'gal'];
      case CanonicalToolId.pressure:
        return const <String>['kPa', 'psi', 'bar', 'atm'];
      case CanonicalToolId.weight:
        return const <String>['g', 'kg', 'oz', 'lb', 'st'];
      case CanonicalToolId.dataStorage:
        return const <String>['B', 'KB', 'MB', 'GB', 'TB'];
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

    if (_isTimeTool) {
      _seedTimeToolDefaults();
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
  void dispose() {
    _timeTicker?.cancel();
    _noticeTimer?.cancel();
    _timeConvertController.dispose();
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
      default:
        _fromUnitOverride = null;
        _toUnitOverride = null;
        return;
    }
  }

  List<String> _lookupSystemsForTool() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.shoeSizes:
        return const <String>['US Men', 'US Women', 'EU', 'UK', 'JP (cm)'];
      case CanonicalToolId.paperSizes:
        return const <String>['ISO', 'US'];
      case CanonicalToolId.mattressSizes:
        return const <String>['US', 'EU'];
      default:
        return const <String>[];
    }
  }

  List<_LookupEntry> _lookupEntriesForTool() {
    switch (widget.tool.canonicalToolId) {
      case CanonicalToolId.shoeSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'shoe_7',
            label: 'US Men 7',
            valuesBySystem: <String, String>{
              'US Men': '7',
              'US Women': '8.5',
              'EU': '40',
              'UK': '6',
              'JP (cm)': '25',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_8',
            label: 'US Men 8',
            valuesBySystem: <String, String>{
              'US Men': '8',
              'US Women': '9.5',
              'EU': '41',
              'UK': '7',
              'JP (cm)': '26',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_9',
            label: 'US Men 9',
            valuesBySystem: <String, String>{
              'US Men': '9',
              'US Women': '10.5',
              'EU': '42',
              'UK': '8',
              'JP (cm)': '27',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_10',
            label: 'US Men 10',
            valuesBySystem: <String, String>{
              'US Men': '10',
              'US Women': '11.5',
              'EU': '43',
              'UK': '9',
              'JP (cm)': '28',
            },
          ),
          _LookupEntry(
            keyId: 'shoe_11',
            label: 'US Men 11',
            valuesBySystem: <String, String>{
              'US Men': '11',
              'US Women': '12.5',
              'EU': '44.5',
              'UK': '10',
              'JP (cm)': '29',
            },
          ),
        ];
      case CanonicalToolId.paperSizes:
        return const <_LookupEntry>[
          _LookupEntry(
            keyId: 'paper_a4',
            label: 'A4',
            valuesBySystem: <String, String>{
              'ISO': 'A4 (210 x 297 mm)',
              'US': 'Letter (8.5 x 11 in)',
            },
            note: 'Nearest US equivalent.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_a3',
            label: 'A3',
            valuesBySystem: <String, String>{
              'ISO': 'A3 (297 x 420 mm)',
              'US': 'Tabloid (11 x 17 in)',
            },
            note: 'Nearest US equivalent.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_letter',
            label: 'Letter',
            valuesBySystem: <String, String>{
              'ISO': 'A4 (210 x 297 mm)',
              'US': 'Letter (8.5 x 11 in)',
            },
            note: 'Nearest ISO equivalent.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'paper_legal',
            label: 'Legal',
            valuesBySystem: <String, String>{
              'ISO': 'B4 (250 x 353 mm)',
              'US': 'Legal (8.5 x 14 in)',
            },
            note: 'Nearest ISO equivalent.',
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
            },
            note: 'Regional naming varies by vendor.',
            approximate: true,
          ),
          _LookupEntry(
            keyId: 'matt_full',
            label: 'Full / Double',
            valuesBySystem: <String, String>{
              'US': 'Full (54 x 75 in)',
              'EU': 'Double (140 x 200 cm)',
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
            },
            note: 'Approximate cross-region equivalent.',
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
      case CanonicalToolId.mattressSizes:
        _lookupFromSystem = 'US';
        _lookupToSystem = 'EU';
        _lookupEntryKey = 'matt_queen';
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

  Widget _buildTipHelperBody(BuildContext context, Color accent) {
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
            labelText: 'Bill Amount (${_tipCurrencyCode()})',
            hintText: '100.00',
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
              'Split',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DraculaPalette.purple,
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
                ('none', 'No round'),
                ('nearest', 'Nearest'),
                ('up', 'Round up'),
                ('down', 'Round down'),
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
            color: DraculaPalette.currentLine,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
          ),
          child: amount == null
              ? Text(
                  'Enter a valid amount to calculate tip.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DraculaPalette.comment.withAlpha(230),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLine(
                      prompt: '>',
                      input: 'Tip ($_tipPercent%)',
                      output: _moneyWithCode(tipRaw!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: 'Total',
                      output: _moneyWithCode(totalRounded!),
                      emphasize: true,
                      arrowColor: accent,
                    ),
                    const SizedBox(height: 6),
                    _TerminalLine(
                      prompt: '>',
                      input: 'Per person ($_tipSplitCount)',
                      output: _moneyWithCode(perPerson!),
                      emphasize: false,
                      arrowColor: accent,
                    ),
                    if (roundDelta != null && roundDelta.abs() >= 0.005) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rounding adjustment: ${roundDelta > 0 ? '+' : ''}${_moneyWithCode(roundDelta).replaceFirst(_currencySymbol(_tipCurrencyCode()), '')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DraculaPalette.comment.withAlpha(220),
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

  bool get _hasCustomLookupSelection {
    final defaults = () {
      switch (widget.tool.canonicalToolId) {
        case CanonicalToolId.shoeSizes:
          return ('US Men', 'EU', 'shoe_9');
        case CanonicalToolId.paperSizes:
          return ('ISO', 'US', 'paper_a4');
        case CanonicalToolId.mattressSizes:
          return ('US', 'EU', 'matt_queen');
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
                    ? Icon(Icons.check_rounded, color: DraculaPalette.purple)
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
                    ? Icon(Icons.check_rounded, color: DraculaPalette.purple)
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
    return showDestructiveConfirmationSheet(
      context,
      title: 'Clear history?',
      message: 'This removes the last 10 conversions for this tool.',
      confirmLabel: 'Clear',
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
      case 'oven_temperature':
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
      case 'data_storage':
        return _fromUnitOverride ?? (_forward ? 'GB' : 'MB');
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
      case 'oven_temperature':
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
      case 'data_storage':
        return _toUnitOverride ?? (_forward ? 'MB' : 'GB');
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
      'b',
      'kb',
      'mb',
      'gb',
      'tb',
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
    final row = _activeLookupEntry();
    final from = _lookupFromSystem;
    final to = _lookupToSystem;
    if (row == null || from == null || to == null) {
      return const SizedBox.shrink();
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

    Future<void> copyLookupCell({
      required String value,
      required String label,
    }) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      _showNotice('Copied $label', UnitanaNoticeKind.info);
    }

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
                color: DraculaPalette.comment.withAlpha(230),
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
      Alignment alignment = Alignment.center,
    }) {
      return Expanded(
        child: InkWell(
          key: ValueKey('tool_lookup_matrix_cell_${widget.tool.id}_$keySuffix'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => copyLookupCell(value: text, label: copyLabel),
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
                  color: DraculaPalette.foreground,
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
                child: Text('From: $from'),
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
                child: Text('To: $to'),
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
            child: Text('Size: ${row.label}'),
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
            label: const Text('Reset Defaults'),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: ValueKey('tool_lookup_result_${widget.tool.id}'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: DraculaPalette.currentLine,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
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
            row.approximate ? 'Approximate: ${row.note}' : row.note!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DraculaPalette.comment.withAlpha(230),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (proximityRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Size Matrix',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: DraculaPalette.purple,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Selected row centered when possible. Tap a value cell to copy.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DraculaPalette.comment.withAlpha(230),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: ValueKey('tool_lookup_matrix_${widget.tool.id}'),
            decoration: BoxDecoration(
              color: DraculaPalette.currentLine,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    matrixHeaderCell('Size', alignment: Alignment.centerLeft),
                    matrixHeaderCell(from, alignment: Alignment.center),
                    matrixHeaderCell(to, alignment: Alignment.center),
                  ],
                ),
                Divider(height: 1, color: DraculaPalette.comment.withAlpha(90)),
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
                                      n.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? DraculaPalette.pink
                                                : DraculaPalette.foreground,
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
                            ),
                            matrixValueCell(
                              keySuffix: '${n.keyId}_to',
                              text: _lookupValue(row: n, system: to),
                              isSelected: isSelected,
                              copyLabel: '$to value',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (i != proximityRows.length - 1)
                    Divider(
                      height: 1,
                      color: DraculaPalette.comment.withAlpha(70),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<({String id, String label})> _timeZoneOptions() {
    final out = <({String id, String label})>[];
    final seen = <String>{};
    void add(String id, String label) {
      final norm = id.trim();
      if (norm.isEmpty || !seen.add(norm)) return;
      out.add((id: norm, label: label));
    }

    final home = widget.home;
    final destination = widget.destination;
    if (home != null) {
      add(home.timeZoneId, 'Home (${home.cityName})');
    }
    if (destination != null) {
      add(destination.timeZoneId, 'Destination (${destination.cityName})');
    }
    add('UTC', 'UTC');
    return out;
  }

  void _seedTimeToolDefaults() {
    final home = widget.home;
    final destination = widget.destination;
    final options = _timeZoneOptions();
    final fallback = options.isEmpty ? 'UTC' : options.first.id;

    if (widget.session.reality == DashboardReality.destination) {
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
  }

  void _swapTimeZones() {
    setState(() {
      final oldFrom = _timeFromZoneId;
      final tmp = _timeFromZoneId;
      _timeFromZoneId = _timeToZoneId;
      _timeToZoneId = tmp;
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
        'Enter date/time as YYYY-MM-DD HH:MM',
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
    final options = _timeZoneOptions();
    if (options.isEmpty) return;
    final current = isFrom ? _timeFromZoneId : _timeToZoneId;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in options)
              ListTile(
                key: ValueKey(
                  'tool_time_zone_item_${isFrom ? 'from' : 'to'}_${_sanitizeUnitKey(option.id)}',
                ),
                title: Text(option.label),
                subtitle: Text(option.id),
                trailing: option.id == current
                    ? Icon(Icons.check_rounded, color: DraculaPalette.purple)
                    : null,
                onTap: () => Navigator.of(context).pop(option.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final previousFrom = _timeFromZoneId;
    setState(() {
      if (isFrom) {
        _timeFromZoneId = selected;
      } else {
        _timeToZoneId = selected;
      }
      if (_timeFromZoneId == _timeToZoneId) {
        final alt = options
            .firstWhere((o) => o.id != selected, orElse: () => options.first)
            .id;
        if (isFrom) {
          _timeToZoneId = alt;
        } else {
          _timeFromZoneId = alt;
        }
      }
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
        .firstWhere((o) => o.id == id, orElse: () => (id: id, label: id))
        .label;

    final nowUtc = DateTime.now().toUtc();
    final fromNow = TimezoneUtils.nowInZone(fromId, nowUtc: nowUtc);
    final toNow = TimezoneUtils.nowInZone(toId, nowUtc: nowUtc);
    final delta = TimezoneUtils.deltaHours(toNow, fromNow);
    final deltaLabel = TimezoneUtils.formatDeltaLabel(delta);

    String clock(ZoneTime zt, {required bool use24h}) {
      return TimezoneUtils.formatClock(zt, use24h: use24h);
    }

    String zoneMeta(ZoneTime zt) {
      final sign = zt.offsetHours >= 0 ? '+' : '';
      return 'UTC$sign${zt.offsetHours} ${zt.abbreviation}';
    }

    Future<void> addWidgetIfRequested() async {
      if (!widget.canAddWidget || widget.onAddWidget == null) return;
      try {
        await widget.onAddWidget!.call();
        if (!mounted) return;
        _showNotice(
          'Added ${widget.tool.title} to dashboard',
          UnitanaNoticeKind.success,
        );
      } on DuplicateDashboardWidgetException catch (_) {
        if (!mounted) return;
        _showNotice(
          '${widget.tool.title} is already on your dashboard',
          UnitanaNoticeKind.info,
        );
      } catch (_) {
        if (!mounted) return;
        _showNotice('Could not add widget', UnitanaNoticeKind.error);
      }
    }

    final timeConverterHistory = widget.session.historyFor(widget.tool.id);

    return ListView(
      key: const ValueKey('tool_time_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: DraculaPalette.currentLine,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
          ),
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('tool_time_from_zone'),
                dense: true,
                title: const Text('From Time Zone'),
                subtitle: Text(labelFor(fromId)),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () => _pickTimeZone(isFrom: true),
              ),
              Divider(color: DraculaPalette.comment.withAlpha(120), height: 1),
              ListTile(
                key: const ValueKey('tool_time_to_zone'),
                dense: true,
                title: const Text('To Time Zone'),
                subtitle: Text(labelFor(toId)),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () => _pickTimeZone(isFrom: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey('tool_time_swap_zones'),
            onPressed: _swapTimeZones,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Swap'),
          ),
        ),
        if (widget.canAddWidget && widget.onAddWidget != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const ValueKey('tool_add_widget_time'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: DraculaPalette.comment.withAlpha(160)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: addWidgetIfRequested,
              icon: Icon(Icons.add_circle_outline, size: 18, color: accent),
              label: Text(
                '+ Add Widget',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          key: const ValueKey('tool_time_now_card'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: DraculaPalette.currentLine,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Clocks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DraculaPalette.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${labelFor(fromId)}: ${clock(fromNow, use24h: widget.prefer24h)} (${zoneMeta(fromNow)})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${labelFor(toId)}: ${clock(toNow, use24h: widget.prefer24h)} (${zoneMeta(toNow)})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Delta (${labelFor(toId)} vs ${labelFor(fromId)}): $deltaLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DraculaPalette.comment.withAlpha(230),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_isTimeZoneConverterTool) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('tool_time_converter_card'),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: DraculaPalette.currentLine,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convert Local Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DraculaPalette.purple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter as YYYY-MM-DD HH:MM in ${labelFor(fromId)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DraculaPalette.comment.withAlpha(220),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('tool_time_convert_input'),
                  controller: _timeConvertController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    hintText: '2026-02-06 18:30',
                  ),
                  onSubmitted: (_) => _runTimeZoneConversion(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const ValueKey('tool_time_convert_run'),
                    onPressed: _runTimeZoneConversion,
                    child: const Text('Convert Time'),
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
                  'History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DraculaPalette.purple,
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('tool_time_history_clear'),
                  onPressed: timeConverterHistory.isEmpty
                      ? null
                      : () async {
                          final confirmed = await _confirmClearHistory(context);
                          if (!confirmed) return;
                          widget.session.clearHistory(widget.tool.id);
                          _showNotice(
                            'History cleared',
                            UnitanaNoticeKind.success,
                          );
                        },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('tool_time_history_container'),
            decoration: BoxDecoration(
              color: DraculaPalette.currentLine,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
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
                              ?.copyWith(
                                color: DraculaPalette.comment.withAlpha(200),
                              ),
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
    final errorAt = widget.currencyLastErrorAt;
    if (!widget.currencyIsStale && errorAt == null) return null;

    if (errorAt != null) {
      final age = DateTime.now().difference(errorAt);
      final minutes = age.inMinutes;
      final ageLabel = minutes <= 1 ? '1m ago' : '${minutes}m ago';
      if (widget.currencyShouldRetryNow) {
        return (
          'Rates stale (last error $ageLabel). Retry available now.',
          DraculaPalette.orange,
          true,
        );
      }
      return (
        'Rates stale (last error $ageLabel). Auto-retry is backing off.',
        DraculaPalette.comment,
        false,
      );
    }

    return (
      'Rates may be stale. Showing latest cached values.',
      DraculaPalette.orange,
      false,
    );
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
        final currencyStatus = _currencyStatusBanner();

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
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
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

                  if (currencyStatus != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: DecoratedBox(
                        key: ValueKey('tool_currency_status_${widget.tool.id}'),
                        decoration: BoxDecoration(
                          color: DraculaPalette.currentLine,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currencyStatus.$2.withAlpha(170),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyStatus.$1,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: currencyStatus.$2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (currencyStatus.$3 &&
                                  widget.onRetryCurrencyNow != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    key: ValueKey(
                                      'tool_currency_retry_${widget.tool.id}',
                                    ),
                                    onPressed: () async {
                                      try {
                                        await widget.onRetryCurrencyNow!.call();
                                        if (!mounted) return;
                                        _showNotice(
                                          'Refreshing rates…',
                                          UnitanaNoticeKind.info,
                                        );
                                      } catch (_) {
                                        if (!mounted) return;
                                        _showNotice(
                                          'Could not refresh rates',
                                          UnitanaNoticeKind.error,
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Retry rates'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Body (scrollable to prevent overflow on smallest sizes)
                  Expanded(
                    child: _isTimeTool
                        ? _buildTimeToolBody(context, accent)
                        : _isLookupTool
                        ? _buildLookupBody(context, accent)
                        : _isTipHelperTool
                        ? _buildTipHelperBody(context, accent)
                        : ListView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edit Value',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: DraculaPalette.comment,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        key: ValueKey(
                                          'tool_input_${widget.tool.id}',
                                        ),
                                        controller: _controller,
                                        keyboardType: _requiresFreeformInput
                                            ? TextInputType.text
                                            : TextInputType.numberWithOptions(
                                                decimal:
                                                    numericPolicy.allowDecimal,
                                                signed:
                                                    numericPolicy.allowNegative,
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
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      OutlinedButton(
                                                        key: ValueKey(
                                                          'tool_unit_from_${widget.tool.id}',
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize:
                                                              const Size(0, 34),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 0,
                                                              ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          side: BorderSide(
                                                            color:
                                                                DraculaPalette
                                                                    .comment
                                                                    .withAlpha(
                                                                      160,
                                                                    ),
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _pickUnit(
                                                              isFrom: true,
                                                            ),
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
                                                                    color:
                                                                        accent,
                                                                  ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_drop_down_rounded,
                                                              color: accent
                                                                  .withAlpha(
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
                                                                    FontWeight
                                                                        .w900,
                                                                color: accent,
                                                              ),
                                                        ),
                                                      ),
                                                      OutlinedButton(
                                                        key: ValueKey(
                                                          'tool_unit_to_${widget.tool.id}',
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize:
                                                              const Size(0, 34),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 0,
                                                              ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          side: BorderSide(
                                                            color:
                                                                DraculaPalette
                                                                    .comment
                                                                    .withAlpha(
                                                                      160,
                                                                    ),
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _pickUnit(
                                                              isFrom: false,
                                                            ),
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
                                                                    color:
                                                                        accent,
                                                                  ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_drop_down_rounded,
                                                              color: accent
                                                                  .withAlpha(
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
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: accent,
                                                        ),
                                                    overflow:
                                                        TextOverflow.visible,
                                                    softWrap: false,
                                                  );

                                            final swapButton = OutlinedButton(
                                              key: ValueKey(
                                                'tool_swap_${widget.tool.id}',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(34, 34),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 0,
                                                    ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                side: BorderSide(
                                                  color: DraculaPalette.comment
                                                      .withAlpha(160),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                side: BorderSide(
                                                  color: DraculaPalette.comment
                                                      .withAlpha(160),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () async {
                                                try {
                                                  await widget.onAddWidget!
                                                      .call();
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                ),
                                                onPressed:
                                                    _hasCustomUnitSelection
                                                    ? _resetUnitSelectionToDefaults
                                                    : null,
                                                icon: const Icon(
                                                  Icons.restart_alt_rounded,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Reset Defaults',
                                                ),
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
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child:
                                                            buildAddWidgetButton(),
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
                                                  alignment:
                                                      Alignment.centerRight,
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
                                      key: ValueKey(
                                        'tool_run_${widget.tool.id}',
                                      ),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 52),
                                      ),
                                      onPressed: _runConversion,
                                      child: const Text('Convert'),
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: DraculaPalette.purple,
                                          ),
                                    ),
                                    Text(
                                      'tap copies result; long-press copies input',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: DraculaPalette.comment
                                                .withAlpha(220),
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
                                      color: DraculaPalette.comment.withAlpha(
                                        160,
                                      ),
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
                                                final toCopy =
                                                    _stripKnownUnitSuffix(
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

                                                final raw =
                                                    _stripKnownUnitSuffix(
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
                                                          offset: preservedText
                                                              .length,
                                                        );
                                                }
                                                _showNotice(
                                                  'Copied input',
                                                  UnitanaNoticeKind.success,
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _TerminalLine(
                                                            prompt: '>',
                                                            input: inputLabel,
                                                            output: outputLabel,
                                                            emphasize:
                                                                isMostRecent,
                                                            arrowColor:
                                                                isMostRecent
                                                                ? DraculaPalette
                                                                      .purple
                                                                : DraculaPalette
                                                                      .comment,
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            timestamp,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  color: DraculaPalette
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
                                                      color: DraculaPalette
                                                          .comment
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

                                          widget.session.clearHistory(
                                            widget.tool.id,
                                          );
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
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: const Color(0xFFFBBF24),
                                  ),
                                  child: Text(
                                    'Clear History',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: const Color(0xFFFBBF24),
                                        ),
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
