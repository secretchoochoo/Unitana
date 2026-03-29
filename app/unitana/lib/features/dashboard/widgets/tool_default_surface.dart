import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dashboard_session_controller.dart';
import '../models/numeric_input_policy.dart';
import 'pulse_swap_icon.dart';

@immutable
class ToolDefaultSurfaceTheme {
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color panelBg;
  final Color panelBorder;
  final Color headingTone;
  final Color warningTone;
  final Color successTone;

  const ToolDefaultSurfaceTheme({
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.panelBg,
    required this.panelBorder,
    required this.headingTone,
    required this.warningTone,
    required this.successTone,
  });
}

class ToolDefaultSurface extends StatelessWidget {
  final String toolId;
  final TextEditingController controller;
  final bool requiresFreeformInput;
  final NumericInputPolicy numericPolicy;
  final String inputHint;
  final String? helperText;
  final bool supportsUnitPicker;
  final String fromUnit;
  final String toUnit;
  final bool showBakingHint;
  final bool hasCustomUnitSelection;
  final bool canAddWidget;
  final ToolDefaultSurfaceTheme theme;
  final String editValueLabel;
  final String convertLabel;
  final String addWidgetLabel;
  final String resetDefaultsLabel;
  final VoidCallback onRunConversion;
  final VoidCallback onSwapUnits;
  final VoidCallback? onPickFromUnit;
  final VoidCallback? onPickToUnit;
  final VoidCallback? onResetDefaults;
  final VoidCallback? onAddWidget;
  final Widget postContent;

  const ToolDefaultSurface({
    super.key,
    required this.toolId,
    required this.controller,
    required this.requiresFreeformInput,
    required this.numericPolicy,
    required this.inputHint,
    required this.helperText,
    required this.supportsUnitPicker,
    required this.fromUnit,
    required this.toUnit,
    required this.showBakingHint,
    required this.hasCustomUnitSelection,
    required this.canAddWidget,
    required this.theme,
    required this.editValueLabel,
    required this.convertLabel,
    required this.addWidgetLabel,
    required this.resetDefaultsLabel,
    required this.onRunConversion,
    required this.onSwapUnits,
    required this.onPickFromUnit,
    required this.onPickToUnit,
    required this.onResetDefaults,
    required this.onAddWidget,
    required this.postContent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('tool_scroll_$toolId'),
      cacheExtent: 1200,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _ToolDefaultCalculatorSection(
          toolId: toolId,
          controller: controller,
          requiresFreeformInput: requiresFreeformInput,
          numericPolicy: numericPolicy,
          inputHint: inputHint,
          helperText: helperText,
          supportsUnitPicker: supportsUnitPicker,
          fromUnit: fromUnit,
          toUnit: toUnit,
          showBakingHint: showBakingHint,
          hasCustomUnitSelection: hasCustomUnitSelection,
          canAddWidget: canAddWidget,
          theme: theme,
          editValueLabel: editValueLabel,
          convertLabel: convertLabel,
          addWidgetLabel: addWidgetLabel,
          resetDefaultsLabel: resetDefaultsLabel,
          onRunConversion: onRunConversion,
          onSwapUnits: onSwapUnits,
          onPickFromUnit: onPickFromUnit,
          onPickToUnit: onPickToUnit,
          onResetDefaults: onResetDefaults,
          onAddWidget: onAddWidget,
        ),
        postContent,
      ],
    );
  }
}

class ToolResultHistorySection extends StatelessWidget {
  final String toolId;
  final String? resultLine;
  final List<ConversionRecord> history;
  final ToolDefaultSurfaceTheme theme;
  final String historyTitle;
  final String historyCopyHint;
  final String clearHistoryLabel;
  final String emptyHistoryLabel;
  final String resultPlaceholderInput;
  final String resultPlaceholderOutput;
  final Future<void> Function(ConversionRecord record) onCopyResult;
  final Future<void> Function(ConversionRecord record) onCopyInput;
  final Future<void> Function()? onClearHistory;
  final List<Widget> extraSections;

  const ToolResultHistorySection({
    super.key,
    required this.toolId,
    required this.resultLine,
    required this.history,
    required this.theme,
    required this.historyTitle,
    required this.historyCopyHint,
    required this.clearHistoryLabel,
    required this.emptyHistoryLabel,
    required this.resultPlaceholderInput,
    required this.resultPlaceholderOutput,
    required this.onCopyResult,
    required this.onCopyInput,
    required this.onClearHistory,
    this.extraSections = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _ToolResultCard(
          toolId: toolId,
          line: resultLine,
          theme: theme,
          placeholderInput: resultPlaceholderInput,
          placeholderOutput: resultPlaceholderOutput,
        ),
        for (final section in extraSections) ...[
          const SizedBox(height: 10),
          section,
        ],
        _ToolHistorySection(
          toolId: toolId,
          history: history,
          theme: theme,
          historyTitle: historyTitle,
          historyCopyHint: historyCopyHint,
          clearHistoryLabel: clearHistoryLabel,
          emptyHistoryLabel: emptyHistoryLabel,
          onCopyResult: onCopyResult,
          onCopyInput: onCopyInput,
          onClearHistory: onClearHistory,
        ),
      ],
    );
  }
}

class _ToolDefaultCalculatorSection extends StatelessWidget {
  final String toolId;
  final TextEditingController controller;
  final bool requiresFreeformInput;
  final NumericInputPolicy numericPolicy;
  final String inputHint;
  final String? helperText;
  final bool supportsUnitPicker;
  final String fromUnit;
  final String toUnit;
  final bool showBakingHint;
  final bool hasCustomUnitSelection;
  final bool canAddWidget;
  final ToolDefaultSurfaceTheme theme;
  final String editValueLabel;
  final String convertLabel;
  final String addWidgetLabel;
  final String resetDefaultsLabel;
  final VoidCallback onRunConversion;
  final VoidCallback onSwapUnits;
  final VoidCallback? onPickFromUnit;
  final VoidCallback? onPickToUnit;
  final VoidCallback? onResetDefaults;
  final VoidCallback? onAddWidget;

  const _ToolDefaultCalculatorSection({
    required this.toolId,
    required this.controller,
    required this.requiresFreeformInput,
    required this.numericPolicy,
    required this.inputHint,
    required this.helperText,
    required this.supportsUnitPicker,
    required this.fromUnit,
    required this.toUnit,
    required this.showBakingHint,
    required this.hasCustomUnitSelection,
    required this.canAddWidget,
    required this.theme,
    required this.editValueLabel,
    required this.convertLabel,
    required this.addWidgetLabel,
    required this.resetDefaultsLabel,
    required this.onRunConversion,
    required this.onSwapUnits,
    required this.onPickFromUnit,
    required this.onPickToUnit,
    required this.onResetDefaults,
    required this.onAddWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth <= 340;

        final inputBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editValueLabel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: theme.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              key: ValueKey('tool_input_$toolId'),
              controller: controller,
              keyboardType: requiresFreeformInput
                  ? TextInputType.text
                  : TextInputType.numberWithOptions(
                      decimal: numericPolicy.allowDecimal,
                      signed: numericPolicy.allowNegative,
                    ),
              inputFormatters: requiresFreeformInput
                  ? const <TextInputFormatter>[]
                  : <TextInputFormatter>[
                      NumericTextInputFormatter(policy: numericPolicy),
                    ],
              decoration: InputDecoration(hintText: inputHint),
              onSubmitted: (_) => onRunConversion(),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 6),
              Text(
                helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canAddWidget && onAddWidget != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: ValueKey('tool_add_widget_$toolId'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: theme.panelBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onAddWidget,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: theme.accent,
                      ),
                      label: Text(
                        addWidgetLabel,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _ToolUnitsRow(
                  toolId: toolId,
                  supportsUnitPicker: supportsUnitPicker,
                  fromUnit: fromUnit,
                  toUnit: toUnit,
                  showBakingHint: showBakingHint,
                  theme: theme,
                  onPickFromUnit: onPickFromUnit,
                  onPickToUnit: onPickToUnit,
                  onSwapUnits: onSwapUnits,
                ),
                if (supportsUnitPicker) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey('tool_units_reset_$toolId'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: hasCustomUnitSelection
                          ? onResetDefaults
                          : null,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(resetDefaultsLabel),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

        final convertButton = SizedBox(
          height: 52,
          child: FilledButton(
            key: ValueKey('tool_run_$toolId'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: onRunConversion,
            child: Text(convertLabel),
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
}

class _ToolUnitsRow extends StatelessWidget {
  final String toolId;
  final bool supportsUnitPicker;
  final String fromUnit;
  final String toUnit;
  final bool showBakingHint;
  final ToolDefaultSurfaceTheme theme;
  final VoidCallback? onPickFromUnit;
  final VoidCallback? onPickToUnit;
  final VoidCallback onSwapUnits;

  const _ToolUnitsRow({
    required this.toolId,
    required this.supportsUnitPicker,
    required this.fromUnit,
    required this.toUnit,
    required this.showBakingHint,
    required this.theme,
    required this.onPickFromUnit,
    required this.onPickToUnit,
    required this.onSwapUnits,
  });

  @override
  Widget build(BuildContext context) {
    final Widget unitsWidget = supportsUnitPicker
        ? Column(
            key: ValueKey('tool_units_$toolId'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    key: ValueKey('tool_unit_from_$toolId'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: theme.panelBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: onPickFromUnit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fromUnit,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.accent,
                              ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: theme.accent.withAlpha(220),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '→',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.accent,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    key: ValueKey('tool_unit_to_$toolId'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: theme.panelBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: onPickToUnit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          toUnit,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.accent,
                              ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: theme.accent.withAlpha(220),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showBakingHint)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    '$fromUnit → $toUnit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.accent.withAlpha(230),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          )
        : Text(
            '$fromUnit → $toUnit',
            key: ValueKey('tool_units_$toolId'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.accent,
            ),
            overflow: TextOverflow.visible,
            softWrap: false,
          );

    final swapButton = OutlinedButton(
      key: ValueKey('tool_swap_$toolId'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: theme.panelBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onSwapUnits,
      child: PulseSwapIcon(color: theme.accent.withAlpha(220), size: 18),
    );

    return Row(
      key: ValueKey('tool_units_row_$toolId'),
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
}

class _ToolHistorySection extends StatelessWidget {
  final String toolId;
  final List<ConversionRecord> history;
  final ToolDefaultSurfaceTheme theme;
  final String historyTitle;
  final String historyCopyHint;
  final String clearHistoryLabel;
  final String emptyHistoryLabel;
  final Future<void> Function(ConversionRecord record) onCopyResult;
  final Future<void> Function(ConversionRecord record) onCopyInput;
  final Future<void> Function()? onClearHistory;

  const _ToolHistorySection({
    required this.toolId,
    required this.history,
    required this.theme,
    required this.historyTitle,
    required this.historyCopyHint,
    required this.clearHistoryLabel,
    required this.emptyHistoryLabel,
    required this.onCopyResult,
    required this.onCopyInput,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
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
                historyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.headingTone,
                ),
              ),
              Text(
                historyCopyHint,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.textMuted,
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
              color: theme.panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.panelBorder),
            ),
            child: history.isEmpty
                ? _EmptyHistory(
                    label: emptyHistoryLabel,
                    textMuted: theme.textMuted,
                  )
                : ListView.builder(
                    key: ValueKey('tool_history_list_$toolId'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final record = history[index];
                      final isMostRecent = index == 0;
                      final timestamp = record.timestamp
                          .toLocal()
                          .toIso8601String()
                          .substring(11, 19);

                      return InkWell(
                        key: ValueKey('tool_history_${toolId}_$index'),
                        onTap: () => onCopyResult(record),
                        onLongPress: () => onCopyInput(record),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ToolTerminalLine(
                                      prompt: '>',
                                      input: record.inputLabel,
                                      output: record.outputLabel,
                                      emphasize: isMostRecent,
                                      arrowColor: isMostRecent
                                          ? theme.headingTone
                                          : theme.textMuted,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timestamp,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: theme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: theme.textMuted.withAlpha(200),
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
            onPressed: history.isEmpty ? null : onClearHistory,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: theme.warningTone,
            ),
            child: Text(
              clearHistoryLabel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: theme.warningTone),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolResultCard extends StatelessWidget {
  final String toolId;
  final String? line;
  final ToolDefaultSurfaceTheme theme;
  final String placeholderInput;
  final String placeholderOutput;

  const _ToolResultCard({
    required this.toolId,
    required this.line,
    required this.theme,
    required this.placeholderInput,
    required this.placeholderOutput,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = line;
    String input;
    String output;
    if (resolved == null || resolved.trim().isEmpty) {
      input = placeholderInput;
      output = placeholderOutput;
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
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: _ToolTerminalLine(
        prompt: '>',
        input: input,
        output: output,
        emphasize: true,
        arrowColor: theme.accent,
      ),
    );
  }
}

class _ToolTerminalLine extends StatelessWidget {
  final String prompt;
  final String input;
  final String output;
  final bool emphasize;
  final Color arrowColor;

  const _ToolTerminalLine({
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
      color: Theme.of(context).colorScheme.onSurface.withAlpha(238),
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
    );

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(
            text: prompt,
            style: base?.copyWith(
              color: themeSuccess(context),
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

  Color themeSuccess(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF2E7D32)
      : const Color(0xFF50FA7B);
}

class _EmptyHistory extends StatelessWidget {
  final String label;
  final Color textMuted;

  const _EmptyHistory({required this.label, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
