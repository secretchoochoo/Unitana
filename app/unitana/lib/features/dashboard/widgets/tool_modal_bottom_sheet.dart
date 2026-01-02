import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/widgets/unitana_notice_card.dart';

import '../models/dashboard_session_controller.dart';
import '../models/dashboard_exceptions.dart';
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
  final bool canAddWidget;
  final Future<void> Function()? onAddWidget;

  const ToolModalBottomSheet({
    super.key,
    required this.tool,
    required this.session,
    required this.preferMetric,
    this.canAddWidget = false,
    this.onAddWidget,
  });

  static Future<void> show(
    BuildContext context, {
    required ToolDefinition tool,
    required DashboardSessionController session,
    required bool preferMetric,
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
        canAddWidget: canAddWidget,
        onAddWidget: onAddWidget,
      ),
    );
  }

  @override
  State<ToolModalBottomSheet> createState() => _ToolModalBottomSheetState();
}

class _ToolModalBottomSheetState extends State<ToolModalBottomSheet> {
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
      default:
        return true;
    }
  }

  String get _fromUnit {
    switch (widget.tool.id) {
      case 'distance':
        return _forward ? 'km' : 'mi';
      case 'speed':
        return _forward ? 'km/h' : 'mph';
      case 'temperature':
        return _forward ? '°C' : '°F';
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
      case 'distance':
        return _forward ? 'mi' : 'km';
      case 'speed':
        return _forward ? 'mph' : 'km/h';
      case 'temperature':
        return _forward ? '°F' : '°C';
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
    return widget.tool.id == 'height' && !_forward;
  }

  String _stripKnownUnitSuffix(String label) {
    const suffixes = <String>[
      'cm',
      'ft/in',
      'km',
      'mi',
      'km/h',
      'mph',
      '°c',
      '°f',
      'ml',
      'cup',
      'oz',
      'm²',
      'm2',
      'ft²',
      'ft2',
    ];

    for (final s in suffixes) {
      final withSpace = ' $s';
      if (label.endsWith(withSpace)) {
        return label.substring(0, label.length - withSpace.length).trim();
      }
    }
    return label.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
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
                        Icon(widget.tool.icon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.tool.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (widget.canAddWidget && widget.onAddWidget != null)
                          TextButton.icon(
                            key: ValueKey('tool_add_widget_${widget.tool.id}'),
                            onPressed: () async {
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
                        IconButton(
                          tooltip: 'Swap',
                          onPressed: () => setState(() => _forward = !_forward),
                          icon: const Icon(Icons.swap_horiz_rounded),
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
                      children: [
                        Expanded(
                          child: TextField(
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
                            decoration: InputDecoration(
                              labelText: 'Enter value',
                              helperText: '$_fromUnit → $_toUnit',
                            ),
                            onSubmitted: (_) => _runConversion(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          key: ValueKey('tool_run_${widget.tool.id}'),
                          onPressed: _runConversion,
                          child: const Text('Convert'),
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
                    child: history.isEmpty
                        ? const _EmptyHistory()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: history.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final r = history[index];
                              final isMostRecent = index == 0;

                              return ListTile(
                                key: ValueKey(
                                  'tool_history_${widget.tool.id}_$index',
                                ),
                                title: Text(
                                  '${r.inputLabel}  →  ${r.outputLabel}',
                                  style: isMostRecent
                                      ? Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        )
                                      : Theme.of(context).textTheme.bodyMedium,
                                ),
                                subtitle: isMostRecent
                                    ? null
                                    : Text(
                                        r.timestamp
                                            .toLocal()
                                            .toIso8601String()
                                            .substring(11, 19),
                                      ),
                                onTap: () {
                                  _controller.text = _stripKnownUnitSuffix(
                                    r.inputLabel,
                                  );
                                  setState(() {});
                                },
                              );
                            },
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calculate_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Result', style: text.labelLarge),
                const SizedBox(height: 6),
                Text(
                  line ?? 'Run a conversion to see the result here.',
                  key: ValueKey('tool_result_$toolId'),
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'No history yet',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
