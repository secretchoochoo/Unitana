import 'package:flutter/material.dart';

import '../models/dashboard_copy.dart';
import '../models/tool_lookup_catalog.dart';

typedef ToolLookupValueCopyCallback =
    Future<void> Function({
      required String value,
      required String label,
      required ToolLookupEntry row,
      required String system,
    });

@immutable
class ToolLookupSurfaceTheme {
  final Color accent;
  final Color panelBg;
  final Color panelBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color headingTone;
  final Color selectedTone;

  const ToolLookupSurfaceTheme({
    required this.accent,
    required this.panelBg,
    required this.panelBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.headingTone,
    required this.selectedTone,
  });
}

class ToolLookupSurface extends StatelessWidget {
  final String toolId;
  final String canonicalToolId;
  final bool isFullMatrix;
  final bool isClothingLookupTool;
  final bool hasCustomSelection;
  final ToolLookupEntry selectedRow;
  final List<ToolLookupEntry> rows;
  final String fromSystem;
  final String toSystem;
  final int matrixPageIndex;
  final ToolLookupSurfaceTheme theme;
  final Widget resultWidget;
  final VoidCallback onPickFromSystem;
  final VoidCallback onPickToSystem;
  final VoidCallback onSwapSystems;
  final VoidCallback onPickEntry;
  final VoidCallback onResetSelection;
  final ValueChanged<int> onMatrixPageChanged;
  final ValueChanged<String> onSelectEntry;
  final ToolLookupValueCopyCallback onCopyValue;
  final String Function(ToolLookupEntry row, String system) lookupValue;
  final String Function(String unit) sanitizeUnitKey;

  const ToolLookupSurface({
    super.key,
    required this.toolId,
    required this.canonicalToolId,
    required this.isFullMatrix,
    required this.isClothingLookupTool,
    required this.hasCustomSelection,
    required this.selectedRow,
    required this.rows,
    required this.fromSystem,
    required this.toSystem,
    required this.matrixPageIndex,
    required this.theme,
    required this.resultWidget,
    required this.onPickFromSystem,
    required this.onPickToSystem,
    required this.onSwapSystems,
    required this.onPickEntry,
    required this.onResetSelection,
    required this.onMatrixPageChanged,
    required this.onSelectEntry,
    required this.onCopyValue,
    required this.lookupValue,
    required this.sanitizeUnitKey,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullMatrix) {
      return _ToolLookupFullMatrixView(
        toolId: toolId,
        canonicalToolId: canonicalToolId,
        isClothingLookupTool: isClothingLookupTool,
        rows: rows,
        selectedEntryKey: selectedRow.keyId,
        matrixPageIndex: matrixPageIndex,
        theme: theme,
        onMatrixPageChanged: onMatrixPageChanged,
        onSelectEntry: onSelectEntry,
        onCopyValue: onCopyValue,
        lookupValue: lookupValue,
        sanitizeUnitKey: sanitizeUnitKey,
      );
    }

    return _ToolLookupCompactView(
      toolId: toolId,
      canonicalToolId: canonicalToolId,
      selectedRow: selectedRow,
      rows: rows,
      fromSystem: fromSystem,
      toSystem: toSystem,
      hasCustomSelection: hasCustomSelection,
      theme: theme,
      resultWidget: resultWidget,
      onPickFromSystem: onPickFromSystem,
      onPickToSystem: onPickToSystem,
      onSwapSystems: onSwapSystems,
      onPickEntry: onPickEntry,
      onResetSelection: onResetSelection,
      onSelectEntry: onSelectEntry,
      onCopyValue: onCopyValue,
      lookupValue: lookupValue,
    );
  }
}

class _ToolLookupFullMatrixView extends StatelessWidget {
  final String toolId;
  final String canonicalToolId;
  final bool isClothingLookupTool;
  final List<ToolLookupEntry> rows;
  final String selectedEntryKey;
  final int matrixPageIndex;
  final ToolLookupSurfaceTheme theme;
  final ValueChanged<int> onMatrixPageChanged;
  final ValueChanged<String> onSelectEntry;
  final ToolLookupValueCopyCallback onCopyValue;
  final String Function(ToolLookupEntry row, String system) lookupValue;
  final String Function(String unit) sanitizeUnitKey;

  const _ToolLookupFullMatrixView({
    required this.toolId,
    required this.canonicalToolId,
    required this.isClothingLookupTool,
    required this.rows,
    required this.selectedEntryKey,
    required this.matrixPageIndex,
    required this.theme,
    required this.onMatrixPageChanged,
    required this.onSelectEntry,
    required this.onCopyValue,
    required this.lookupValue,
    required this.sanitizeUnitKey,
  });

  @override
  Widget build(BuildContext context) {
    final systems = toolLookupMatrixValueSystems(canonicalToolId);
    const pageSize = 2;
    final pageCount = (systems.length / pageSize).ceil().clamp(1, 999);
    final pageIndex = matrixPageIndex.clamp(0, pageCount - 1);
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
                color: theme.textMuted,
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
      required ToolLookupEntry row,
      required String system,
      required double width,
      required bool selected,
      Alignment alignment = Alignment.center,
    }) {
      return SizedBox(
        width: width,
        child: InkWell(
          key: ValueKey('tool_lookup_matrix_cell_${toolId}_$keySuffix'),
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            onSelectEntry(row.keyId);
            await onCopyValue(
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
                  color: theme.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      key: ValueKey('tool_lookup_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DashboardCopy.lookupSizeMatrix(context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.headingTone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DashboardCopy.lookupMatrixHelp(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isClothingLookupTool) ...[
            const SizedBox(height: 8),
            Container(
              key: const ValueKey('tool_lookup_disclaimer_clothing_sizes'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.panelBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.panelBorder),
              ),
              child: Text(
                'Sizes vary by brand and cut. Use this as a reference and check retailer size charts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                key: ValueKey('tool_lookup_matrix_prev_$toolId'),
                onPressed: pageIndex > 0
                    ? () => onMatrixPageChanged(pageIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  'Page ${pageIndex + 1} / $pageCount • $visibleLabel',
                  key: ValueKey('tool_lookup_matrix_page_label_$toolId'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('tool_lookup_matrix_next_$toolId'),
                onPressed: pageIndex < pageCount - 1
                    ? () => onMatrixPageChanged(pageIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Text(
            'Swipe left/right to change table pages.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              key: ValueKey('tool_lookup_matrix_$toolId'),
              decoration: BoxDecoration(
                color: theme.panelBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.panelBorder),
              ),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity <= -200 && pageIndex < pageCount - 1) {
                    onMatrixPageChanged(pageIndex + 1);
                  } else if (velocity >= 200 && pageIndex > 0) {
                    onMatrixPageChanged(pageIndex - 1);
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sizeColWidth = isClothingLookupTool ? 150.0 : 94.0;
                    final valueColWidth =
                        ((constraints.maxWidth - sizeColWidth) /
                                visibleSystems.length)
                            .clamp(98.0, 170.0);
                    final fullWidth =
                        sizeColWidth + (visibleSystems.length * valueColWidth);

                    return SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              headerCell(
                                toolLookupReferenceHeader(canonicalToolId),
                                width: sizeColWidth,
                                alignment: Alignment.centerLeft,
                              ),
                              for (final system in visibleSystems)
                                headerCell(
                                  toolLookupMatrixHeaderLabel(
                                    canonicalToolId: canonicalToolId,
                                    system: system,
                                  ),
                                  width: valueColWidth,
                                  alignment: Alignment.center,
                                ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            color: theme.textMuted.withAlpha(90),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: rows.length,
                              itemBuilder: (context, i) {
                                final entry = rows[i];
                                final selected =
                                    entry.keyId == selectedEntryKey;
                                return Column(
                                  children: [
                                    Container(
                                      key: ValueKey(
                                        'tool_lookup_matrix_row_${toolId}_${entry.keyId}',
                                      ),
                                      width: fullWidth,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? theme.accent.withAlpha(36)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: sizeColWidth,
                                            child: InkWell(
                                              key: ValueKey(
                                                'tool_lookup_matrix_size_${toolId}_${entry.keyId}',
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () =>
                                                  onSelectEntry(entry.keyId),
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
                                                    toolLookupReferenceLabel(
                                                      canonicalToolId:
                                                          canonicalToolId,
                                                      row: entry,
                                                    ),
                                                    maxLines:
                                                        isClothingLookupTool
                                                        ? 2
                                                        : 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: selected
                                                              ? theme
                                                                    .selectedTone
                                                              : theme
                                                                    .textPrimary,
                                                          fontWeight: selected
                                                              ? FontWeight.w800
                                                              : FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          for (final system in visibleSystems)
                                            valueCell(
                                              keySuffix:
                                                  '${entry.keyId}_${sanitizeUnitKey(system)}',
                                              text: lookupValue(entry, system),
                                              copyLabel: '$system value',
                                              row: entry,
                                              system: system,
                                              width: valueColWidth,
                                              selected: selected,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isClothingLookupTool &&
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
                                                  color: theme.textMuted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    if (i != rows.length - 1)
                                      Divider(
                                        height: 1,
                                        color: theme.textMuted.withAlpha(70),
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
}

class _ToolLookupCompactView extends StatelessWidget {
  final String toolId;
  final String canonicalToolId;
  final ToolLookupEntry selectedRow;
  final List<ToolLookupEntry> rows;
  final String fromSystem;
  final String toSystem;
  final bool hasCustomSelection;
  final ToolLookupSurfaceTheme theme;
  final Widget resultWidget;
  final VoidCallback onPickFromSystem;
  final VoidCallback onPickToSystem;
  final VoidCallback onSwapSystems;
  final VoidCallback onPickEntry;
  final VoidCallback onResetSelection;
  final ValueChanged<String> onSelectEntry;
  final ToolLookupValueCopyCallback onCopyValue;
  final String Function(ToolLookupEntry row, String system) lookupValue;

  const _ToolLookupCompactView({
    required this.toolId,
    required this.canonicalToolId,
    required this.selectedRow,
    required this.rows,
    required this.fromSystem,
    required this.toSystem,
    required this.hasCustomSelection,
    required this.theme,
    required this.resultWidget,
    required this.onPickFromSystem,
    required this.onPickToSystem,
    required this.onSwapSystems,
    required this.onPickEntry,
    required this.onResetSelection,
    required this.onSelectEntry,
    required this.onCopyValue,
    required this.lookupValue,
  });

  @override
  Widget build(BuildContext context) {
    final idx = rows.indexWhere((r) => r.keyId == selectedRow.keyId);
    final proximityRows = <ToolLookupEntry>[
      if (idx > 0) rows[idx - 1],
      selectedRow,
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
                color: theme.textMuted,
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
      required ToolLookupEntry rowEntry,
      Alignment alignment = Alignment.center,
    }) {
      return Expanded(
        child: InkWell(
          key: ValueKey('tool_lookup_matrix_cell_${toolId}_$keySuffix'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onCopyValue(
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
                  color: theme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      key: ValueKey('tool_lookup_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: ValueKey('tool_lookup_from_$toolId'),
                onPressed: onPickFromSystem,
                child: Text(DashboardCopy.lookupFromLabel(context, fromSystem)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: ValueKey('tool_lookup_swap_$toolId'),
              onPressed: onSwapSystems,
              child: const Icon(Icons.swap_horiz_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: ValueKey('tool_lookup_to_$toolId'),
                onPressed: onPickToSystem,
                child: Text(DashboardCopy.lookupToLabel(context, toSystem)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: ValueKey('tool_lookup_size_$toolId'),
          onPressed: onPickEntry,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DashboardCopy.lookupSizeLabel(context, selectedRow.label),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: ValueKey('tool_units_reset_$toolId'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: hasCustomSelection ? onResetSelection : null,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(DashboardCopy.lookupResetDefaults(context)),
          ),
        ),
        const SizedBox(height: 8),
        resultWidget,
        if (selectedRow.note != null) ...[
          const SizedBox(height: 8),
          Text(
            selectedRow.approximate
                ? DashboardCopy.lookupApproximate(context, selectedRow.note!)
                : selectedRow.note!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
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
              color: theme.headingTone,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DashboardCopy.lookupMatrixHelp(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: ValueKey('tool_lookup_matrix_$toolId'),
            decoration: BoxDecoration(
              color: theme.panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.panelBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    matrixHeaderCell(
                      toolLookupReferenceHeader(canonicalToolId),
                      alignment: Alignment.centerLeft,
                    ),
                    matrixHeaderCell(fromSystem, alignment: Alignment.center),
                    matrixHeaderCell(toSystem, alignment: Alignment.center),
                  ],
                ),
                Divider(height: 1, color: theme.textMuted.withAlpha(90)),
                for (var i = 0; i < proximityRows.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final row = proximityRows[i];
                      final isSelected = row.keyId == selectedRow.keyId;
                      return Container(
                        key: ValueKey(
                          'tool_lookup_matrix_row_${toolId}_${row.keyId}',
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accent.withAlpha(36)
                              : Colors.transparent,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: theme.accent.withAlpha(220),
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
                                  'tool_lookup_matrix_size_${toolId}_${row.keyId}',
                                ),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => onSelectEntry(row.keyId),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 9,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      toolLookupReferenceLabel(
                                        canonicalToolId: canonicalToolId,
                                        row: row,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? theme.selectedTone
                                                : theme.textPrimary,
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
                              keySuffix: '${row.keyId}_from',
                              text: lookupValue(row, fromSystem),
                              isSelected: isSelected,
                              copyLabel: '$fromSystem value',
                              system: fromSystem,
                              rowEntry: row,
                            ),
                            matrixValueCell(
                              keySuffix: '${row.keyId}_to',
                              text: lookupValue(row, toSystem),
                              isSelected: isSelected,
                              copyLabel: '$toSystem value',
                              system: toSystem,
                              rowEntry: row,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (i != proximityRows.length - 1)
                    Divider(height: 1, color: theme.textMuted.withAlpha(70)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
