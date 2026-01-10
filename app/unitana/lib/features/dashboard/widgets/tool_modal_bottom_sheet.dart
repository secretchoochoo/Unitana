import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/unitana_notice_card.dart';
import '../../../theme/dracula_palette.dart';
import '../../../models/place.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_exceptions.dart';
import '../models/lens_accents.dart';
import '../models/numeric_input_policy.dart';
import '../models/tool_definitions.dart';

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

  /// Optional live exchange rate used by Currency (EUR -> USD).
  ///
  /// This is passed from the dashboard so we can keep the tool surface
  /// frontend-complete while Weather and full FX wiring remain deferred.
  final double? eurToUsd;

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
    this.eurToUsd,
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
    double? eurToUsd,
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
        eurToUsd: eurToUsd,
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

// MVP currency support: EUR ↔ USD.
enum _Currency { eur, usd }

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

  /// Inline result display line (separate from the History list).
  String? _resultLine;

  @override
  void initState() {
    super.initState();
    _forward = _defaultForwardFor(
      toolId: widget.tool.canonicalToolId,
      preferMetric: widget.preferMetric,
    );

    if (_isCurrencyTool) {
      _forward = _defaultCurrencyForward();
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

  bool _defaultForwardFor({
    required String toolId,
    required bool preferMetric,
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
      case 'temperature':
        // °C <-> °F
        return preferMetric;
      case 'weight':
        // kg <-> lb
        return preferMetric;
      case 'time':
        // 24h <-> 12h
        return preferMetric;
      default:
        return true;
    }
  }

  bool get _isCurrencyTool =>
      widget.tool.canonicalToolId == 'currency' ||
      widget.tool.id == 'currency_convert';

  _Currency _currencyForPlace(Place? place) {
    final cc = (place?.countryCode ?? '').trim().toUpperCase();
    if (cc == 'US') return _Currency.usd;
    // MVP assumption: non-US defaults to EUR.
    return _Currency.eur;
  }

  _Currency get _homeCurrency {
    final home = _currencyForPlace(widget.home);
    final dest = _currencyForPlace(widget.destination);
    // If inference collapses to a single currency (US -> US, or unknown -> unknown),
    // fall back to a stable EUR ↔ USD pair.
    if (home == dest) return _Currency.usd;
    return home;
  }

  _Currency get _destinationCurrency {
    final home = _currencyForPlace(widget.home);
    final dest = _currencyForPlace(widget.destination);
    if (home == dest) return _Currency.eur;
    return dest;
  }

  _Currency get _fromCurrency =>
      _forward ? _homeCurrency : _destinationCurrency;
  _Currency get _toCurrency => _forward ? _destinationCurrency : _homeCurrency;

  String _currencyCode(_Currency c) => c == _Currency.usd ? 'USD' : 'EUR';
  String _currencySymbol(_Currency c) => c == _Currency.usd ? r'$' : '€';

  bool _defaultCurrencyForward() {
    // When the active reality is Destination, default to converting Destination
    // currency back into Home currency.
    return widget.session.reality != DashboardReality.destination;
  }

  String get _fromUnit {
    switch (widget.tool.id) {
      case 'currency_convert':
        return _currencyCode(_fromCurrency);
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
      case 'weight':
      case 'body_weight':
        return _forward ? 'kg' : 'lb';
      default:
        return '';
    }
  }

  String get _toUnit {
    switch (widget.tool.id) {
      case 'currency_convert':
        return _currencyCode(_toCurrency);
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
      case 'weight':
      case 'body_weight':
        return _forward ? 'lb' : 'kg';
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

      final from = _fromCurrency;
      final to = _toCurrency;

      double out;
      if (from == to) {
        out = value;
      } else if (from == _Currency.eur && to == _Currency.usd) {
        out = value * rate;
      } else if (from == _Currency.usd && to == _Currency.eur) {
        out = value / rate;
      } else {
        // Future currency expansion; for now, fall back to a no-op.
        out = value;
      }

      final record = ConversionRecord(
        toolId: widget.tool.id,
        lensId: widget.tool.lensId,
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

    final result = ToolConverters.convert(
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
      'cm',
      'ft/in',
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
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.tool.icon, color: accent, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                widget.tool.title,
                                style: GoogleFonts.robotoSlab(
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                  fontWeight: FontWeight.w800,
                                  color: DraculaPalette.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.canAddWidget &&
                                  widget.onAddWidget != null)
                                TextButton.icon(
                                  key: ValueKey(
                                    'tool_add_widget_${widget.tool.id}',
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
                                        '${widget.tool.title} is already on your dashboard.',
                                        UnitanaNoticeKind.error,
                                      );
                                    } catch (_) {
                                      if (!mounted) return;
                                      _showNotice(
                                        'Could not add ${widget.tool.title} to dashboard.',
                                        UnitanaNoticeKind.error,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Widget'),
                                ),
                            ],
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

                  // Calculator (top half)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_fromUnit → $_toUnit',
                                      key: ValueKey(
                                        'tool_units_${widget.tool.id}',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Swap units',
                                    child: InkWell(
                                      key: ValueKey(
                                        'tool_swap_${widget.tool.id}',
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () =>
                                          setState(() => _forward = !_forward),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 20,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 26),
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              key: ValueKey('tool_run_${widget.tool.id}'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: _runConversion,
                              child: const Text('Convert'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ResultCard(
                      toolId: widget.tool.id,
                      lensId: widget.tool.lensId,
                      line: _resultLine,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),

                  // History (bottom section)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                        'Copied $toCopy',
                                        UnitanaNoticeKind.success,
                                      );
                                    },
                                    onLongPress: () {
                                      _controller.text = _stripKnownUnitSuffix(
                                        r.inputLabel,
                                      );
                                      setState(() {});
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
                                                  arrowColor:
                                                      DraculaPalette.pink,
                                                ),
                                                const SizedBox(height: 4),
                                                RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          fontFamily:
                                                              'monospace',
                                                          color: DraculaPalette
                                                              .comment,
                                                        ),
                                                    children: [
                                                      const TextSpan(
                                                        text:
                                                            'tap to copy output · long-press to edit · ',
                                                      ),
                                                      TextSpan(
                                                        text: timestamp,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                              fontFamily:
                                                                  'monospace',
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color:
                                                                  DraculaPalette
                                                                      .comment
                                                                      .withAlpha(
                                                                        200,
                                                                      ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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
}

class _ResultCard extends StatelessWidget {
  final String toolId;
  final String? lensId;
  final String? line;

  const _ResultCard({required this.toolId, this.lensId, required this.line});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = LensAccents.iconTintFor(lensId ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DraculaPalette.currentLine,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DraculaPalette.comment.withAlpha(160)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calculate_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Result',
                  style: text.labelLarge?.copyWith(
                    color: DraculaPalette.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                if (line == null)
                  Text(
                    'Run a conversion to see the result here.',
                    key: ValueKey('tool_result_$toolId'),
                    style: text.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: DraculaPalette.foreground,
                    ),
                  )
                else
                  Builder(
                    builder: (context) {
                      // Expected shape: "<input> → <output>".
                      final parts = line!.split('→');
                      final input = parts.isNotEmpty
                          ? parts.first.trim()
                          : line!;
                      final output = parts.length > 1
                          ? parts.sublist(1).join('→').trim()
                          : '';
                      return KeyedSubtree(
                        key: ValueKey('tool_result_$toolId'),
                        child: Semantics(
                          label: 'Result',
                          child: DefaultTextStyle(
                            style: text.bodyLarge ?? const TextStyle(),
                            child: _TerminalLine(
                              prompt: '>',
                              input: input,
                              output: output,
                              emphasize: true,
                              arrowColor: DraculaPalette.purple,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
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
