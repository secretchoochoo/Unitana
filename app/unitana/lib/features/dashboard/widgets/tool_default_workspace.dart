import 'package:flutter/material.dart';

import '../models/dashboard_session_controller.dart';
import '../models/numeric_input_policy.dart';
import 'tool_default_surface.dart';

class ToolDefaultWorkspace extends StatelessWidget {
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
  final String? resultLine;
  final List<ConversionRecord> history;
  final String historyTitle;
  final String historyCopyHint;
  final String clearHistoryLabel;
  final String emptyHistoryLabel;
  final String resultPlaceholderInput;
  final String resultPlaceholderOutput;
  final VoidCallback onRunConversion;
  final VoidCallback onSwapUnits;
  final VoidCallback? onPickFromUnit;
  final VoidCallback? onPickToUnit;
  final VoidCallback? onResetDefaults;
  final VoidCallback? onAddWidget;
  final Future<void> Function(ConversionRecord record) onCopyResult;
  final Future<void> Function(ConversionRecord record) onCopyInput;
  final Future<void> Function()? onClearHistory;
  final List<Widget> extraSections;

  const ToolDefaultWorkspace({
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
    required this.resultLine,
    required this.history,
    required this.historyTitle,
    required this.historyCopyHint,
    required this.clearHistoryLabel,
    required this.emptyHistoryLabel,
    required this.resultPlaceholderInput,
    required this.resultPlaceholderOutput,
    required this.onRunConversion,
    required this.onSwapUnits,
    required this.onPickFromUnit,
    required this.onPickToUnit,
    required this.onResetDefaults,
    required this.onAddWidget,
    required this.onCopyResult,
    required this.onCopyInput,
    required this.onClearHistory,
    this.extraSections = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return ToolDefaultSurface(
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
      postContent: ToolResultHistorySection(
        toolId: toolId,
        resultLine: resultLine,
        history: history,
        theme: theme,
        historyTitle: historyTitle,
        historyCopyHint: historyCopyHint,
        clearHistoryLabel: clearHistoryLabel,
        emptyHistoryLabel: emptyHistoryLabel,
        resultPlaceholderInput: resultPlaceholderInput,
        resultPlaceholderOutput: resultPlaceholderOutput,
        onCopyResult: onCopyResult,
        onCopyInput: onCopyInput,
        onClearHistory: onClearHistory,
        extraSections: extraSections,
      ),
    );
  }
}
