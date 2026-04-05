import 'package:flutter/material.dart';

import '../models/tool_lookup_catalog.dart';
import 'tool_lookup_surface.dart';

class ToolLookupWorkspace extends StatelessWidget {
  final String toolId;
  final String canonicalToolId;
  final bool isFullMatrix;
  final bool isClothingLookupTool;
  final bool hasCustomSelection;
  final ToolLookupEntry selectedRow;
  final List<ToolLookupEntry> rows;
  final String? selectedClothingGroupKey;
  final String fromSystem;
  final String toSystem;
  final int matrixPageIndex;
  final ToolLookupSurfaceTheme theme;
  final VoidCallback onPickFromSystem;
  final VoidCallback onPickToSystem;
  final VoidCallback onSwapSystems;
  final VoidCallback onPickEntry;
  final VoidCallback onResetSelection;
  final ValueChanged<int> onMatrixPageChanged;
  final ValueChanged<String> onSelectClothingGroup;
  final ValueChanged<String> onSelectEntry;
  final ToolLookupValueCopyCallback onCopyValue;
  final String Function(ToolLookupEntry row, String system) lookupValue;
  final String Function(String unit) sanitizeUnitKey;

  const ToolLookupWorkspace({
    super.key,
    required this.toolId,
    required this.canonicalToolId,
    required this.isFullMatrix,
    required this.isClothingLookupTool,
    required this.hasCustomSelection,
    required this.selectedRow,
    required this.rows,
    required this.selectedClothingGroupKey,
    required this.fromSystem,
    required this.toSystem,
    required this.matrixPageIndex,
    required this.theme,
    required this.onPickFromSystem,
    required this.onPickToSystem,
    required this.onSwapSystems,
    required this.onPickEntry,
    required this.onResetSelection,
    required this.onMatrixPageChanged,
    required this.onSelectClothingGroup,
    required this.onSelectEntry,
    required this.onCopyValue,
    required this.lookupValue,
    required this.sanitizeUnitKey,
  });

  @override
  Widget build(BuildContext context) {
    final fromValue = lookupValue(selectedRow, fromSystem);
    final toValue = lookupValue(selectedRow, toSystem);

    return ToolLookupSurface(
      toolId: toolId,
      canonicalToolId: canonicalToolId,
      isFullMatrix: isFullMatrix,
      isClothingLookupTool: isClothingLookupTool,
      hasCustomSelection: hasCustomSelection,
      selectedRow: selectedRow,
      rows: rows,
      clothingGroups: toolLookupGroupsFor(canonicalToolId),
      selectedClothingGroupKey: selectedClothingGroupKey,
      fromSystem: fromSystem,
      toSystem: toSystem,
      matrixPageIndex: matrixPageIndex,
      theme: theme,
      resultWidget: _LookupResultCard(
        toolId: toolId,
        fromSystem: fromSystem,
        fromValue: fromValue,
        toSystem: toSystem,
        toValue: toValue,
        theme: theme,
      ),
      onPickFromSystem: onPickFromSystem,
      onPickToSystem: onPickToSystem,
      onSwapSystems: onSwapSystems,
      onPickEntry: onPickEntry,
      onResetSelection: onResetSelection,
      onMatrixPageChanged: onMatrixPageChanged,
      onSelectClothingGroup: onSelectClothingGroup,
      onSelectEntry: onSelectEntry,
      onCopyValue: onCopyValue,
      lookupValue: lookupValue,
      sanitizeUnitKey: sanitizeUnitKey,
    );
  }
}

class _LookupResultCard extends StatelessWidget {
  final String toolId;
  final String fromSystem;
  final String fromValue;
  final String toSystem;
  final String toValue;
  final ToolLookupSurfaceTheme theme;

  const _LookupResultCard({
    required this.toolId,
    required this.fromSystem,
    required this.fromValue,
    required this.toSystem,
    required this.toValue,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('tool_lookup_result_$toolId'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            color: theme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: '>',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.successTone,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: ' $fromSystem: $fromValue '),
            TextSpan(
              text: '→',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: ' $toSystem: $toValue'),
          ],
        ),
      ),
    );
  }
}
