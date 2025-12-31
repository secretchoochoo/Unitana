import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../models/place.dart';
import '../models/dashboard_board_item.dart';
import '../models/dashboard_live_data.dart';
import '../models/dashboard_layout_controller.dart';
import '../models/dashboard_session_controller.dart';
import '../models/tool_definitions.dart';
import '../models/activity_lenses.dart';
import 'places_hero_v2.dart';
import 'tool_modal_bottom_sheet.dart';
import 'unitana_tile.dart';

// Layout constants for the dashboard grid.
// The board measures itself based on available width and derives tile geometry
// from these values.
const int _minRowsPhone = 6;
const int _minRowsTablet = 5;
const double _gap = 12.0;
const double _tileHeightRatio = 0.78;

String _lensNameForId(String? id) {
  // Avoid hard-coding a specific “default” lens constant; fall back to the
  // first available lens to keep this widget resilient to lens set changes.
  if (ActivityLenses.all.isEmpty) return 'Tools';

  final normalized = id?.trim();
  if (normalized == null || normalized.isEmpty) return 'Tools';

  return ActivityLenses.all
      .firstWhere(
        (l) => l.id == normalized,
        orElse: () => ActivityLenses.all.first,
      )
      .name;
}

class DashboardBoard extends StatefulWidget {
  final UnitanaAppState state;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;
  final DashboardLayoutController layout;
  final double availableWidth;
  final bool isEditing;
  final String? focusActionTileId;
  final ValueChanged<String?> onEnteredEditMode;
  final VoidCallback onConsumedFocusTileId;
  const DashboardBoard({
    super.key,
    required this.state,
    required this.session,
    required this.liveData,
    required this.layout,
    required this.availableWidth,
    required this.isEditing,
    required this.focusActionTileId,
    required this.onEnteredEditMode,
    required this.onConsumedFocusTileId,
  });

  @override
  State<DashboardBoard> createState() => _DashboardBoardState();
}

class _DashboardBoardState extends State<DashboardBoard> {
  String? _lastFocusId;
  bool _pendingShowActions = false;

  @override
  void initState() {
    super.initState();
    _syncFocus(widget.focusActionTileId);
  }

  @override
  void didUpdateWidget(covariant DashboardBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusActionTileId != widget.focusActionTileId) {
      _syncFocus(widget.focusActionTileId);
    }
  }

  void _syncFocus(String? id) {
    _lastFocusId = id;
    _pendingShowActions = id != null && id.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && _pendingShowActions && _lastFocusId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final id = _lastFocusId;
        if (id == null) return;

        _pendingShowActions = false;
        widget.onConsumedFocusTileId();

        final item = widget.layout.items.firstWhere(
          (i) => i.id == id,
          orElse: () => const DashboardBoardItem(
            id: '',
            kind: DashboardItemKind.emptySlot,
            span: DashboardTileSpan.oneByOne,
          ),
        );
        if (item.id.isEmpty) return;
        await _showTileActions(context, item);
      });
    }

    final places = widget.state.places;
    final home = _pickHome(places);
    final dest = _pickDestination(places);

    final cols = widget.availableWidth >= 520 ? 3 : 2;

    final toolItems = ToolDefinitions.all
        .map(
          (t) => DashboardBoardItem(
            id: t.id,
            kind: _kindForToolId(t.id),
            span: DashboardTileSpan.oneByOne,
          ),
        )
        .toList();

    final items = <DashboardBoardItem>[
      const DashboardBoardItem(
        id: 'places_hero_v2',
        kind: DashboardItemKind.placesHero,
        span: DashboardTileSpan.fullWidthTwoTall,
      ),
      ...toolItems,
      ...widget.layout.items,
    ];

    final placed = _place(items, cols);
    final rowsUsed = placed.isEmpty
        ? 0
        : placed.map((p) => p.row + p.span.rowSpan).reduce(math.max);

    // Give the grid some breathing room so users see open slots without
    // entering edit mode. This also makes the “+” affordance discoverable.
    final minRows = cols <= 2 ? _minRowsPhone : _minRowsTablet;
    final targetRows = math.max(rowsUsed, minRows);

    final tileW = (widget.availableWidth - (cols - 1) * _gap) / cols;
    final tileH = tileW * _tileHeightRatio;
    final boardH = targetRows == 0
        ? 0.0
        : targetRows * tileH + (targetRows - 1) * _gap;

    final occupied = _occupiedCells(placed);
    final placeholders = _placeholderCells(occupied, cols, targetRows);

    return SizedBox(
      height: boardH,
      child: Stack(
        children: [
          // “Empty cell” affordances.
          for (final cell in placeholders)
            Positioned(
              left: cell.col * (tileW + _gap),
              top: cell.row * (tileH + _gap),
              width: tileW,
              height: tileH,
              child: _AddToolTile(
                key: ValueKey('dashboard_add_slot_${cell.row}_${cell.col}'),
                onTap: () => _showToolPicker(
                  context,
                  anchor: DashboardAnchor(index: cell.row * cols + cell.col),
                ),
              ),
            ),
          for (final p in placed)
            Positioned(
              left: p.col * (tileW + _gap),
              top: p.row * (tileH + _gap),
              width: p.span.colSpan * tileW + (p.span.colSpan - 1) * _gap,
              height: p.span.rowSpan * tileH + (p.span.rowSpan - 1) * _gap,
              child: _buildTile(context, p.item, home, dest),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    DashboardBoardItem item,
    Place? home,
    Place? dest,
  ) {
    switch (item.kind) {
      case DashboardItemKind.placesHero:
        return PlacesHeroV2(
          key: const Key('places_hero_v2'),
          home: home,
          destination: dest,
          session: widget.session,
          liveData: widget.liveData,
        );
      case DashboardItemKind.toolHeight:
        return _toolTile(
          context,
          item,
          ToolDefinitions.height,
          activePlace: widget.session.reality == DashboardReality.home
              ? home
              : dest,
        );
      case DashboardItemKind.toolBaking:
        return _toolTile(
          context,
          item,
          ToolDefinitions.baking,
          activePlace: widget.session.reality == DashboardReality.home
              ? home
              : dest,
        );
      case DashboardItemKind.toolLiquids:
        return _toolTile(
          context,
          item,
          ToolDefinitions.liquids,
          activePlace: widget.session.reality == DashboardReality.home
              ? home
              : dest,
        );
      case DashboardItemKind.toolArea:
        return _toolTile(
          context,
          item,
          ToolDefinitions.area,
          activePlace: widget.session.reality == DashboardReality.home
              ? home
              : dest,
        );
      case DashboardItemKind.emptySlot:
        // Empty slots are rendered separately as “+” placeholders.
        return const SizedBox.shrink();
    }
  }

  Widget _toolTile(
    BuildContext context,
    DashboardBoardItem item,
    ToolDefinition tool, {
    required Place? activePlace,
  }) {
    final latest = widget.session.latestFor(tool.canonicalToolId);
    final labels = _pickToolLabels(
      tool: tool,
      latest: latest,
      activePlace: activePlace,
    );
    final preferMetric = (activePlace?.unitSystem ?? 'metric') == 'metric';
    final primary = labels.$1;
    final secondary = labels.$2;

    final tile = UnitanaTile(
      title: tool.title,
      // UnitanaTile expects an IconData, not an Icon widget.
      leadingIcon: tool.icon,
      primary: primary,
      secondary: secondary,
      footer: widget.isEditing ? 'Edit mode' : 'Tap to convert',
      onLongPress: item.userAdded
          ? () {
              if (!widget.isEditing) {
                // Enter edit mode without triggering a second actions sheet.
                widget.onEnteredEditMode(null);
              }
              _showTileActions(context, item);
            }
          : null,
      onTap: widget.isEditing
          ? null
          : () {
              ToolModalBottomSheet.show(
                context,
                tool: tool,
                session: widget.session,
                preferMetric: preferMetric,
              );
            },
    );

    if (!widget.isEditing || !item.userAdded) {
      return KeyedSubtree(
        key: ValueKey('dashboard_item_${item.id}'),
        child: tile,
      );
    }

    return Stack(
      key: ValueKey('dashboard_item_${item.id}'),
      children: [
        tile,
        Positioned(
          top: 8,
          right: 8,
          child: _EditRemoveBadge(
            onTap: () async {
              final ok = await _confirmRemoveTile(context, tool.title);
              if (!ok) return;
              if (!context.mounted) return;
              await widget.layout.removeItem(item.id);
            },
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmRemoveTile(BuildContext context, String label) async {
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
                'Remove $label?',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'This tile will be removed from your dashboard.',
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
                      child: const Text('Remove'),
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

  Future<void> _showTileActions(
    BuildContext context,
    DashboardBoardItem item,
  ) async {
    final action = await showModalBottomSheet<_TileEditAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          top: false,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Replace tile'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_TileEditAction.replace),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  'Remove tile',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_TileEditAction.remove),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null) return;
    if (!context.mounted) return;

    switch (action) {
      case _TileEditAction.replace:
        final picked = await showModalBottomSheet<ToolDefinition>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => const ToolPickerSheet(),
        );
        if (picked == null) return;
        if (!context.mounted) return;
        await widget.layout.replaceItem(item.id, picked);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tile replaced with ${picked.title}.')),
        );
        return;
      case _TileEditAction.remove:
        final ok = await _confirmRemoveTile(context, _titleForItem(item));
        if (!ok) return;
        if (!context.mounted) return;
        await widget.layout.removeItem(item.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tile removed from dashboard.')),
        );
        return;
    }
  }

  String _titleForItem(DashboardBoardItem item) {
    switch (item.kind) {
      case DashboardItemKind.placesHero:
        return 'Hero';
      case DashboardItemKind.toolHeight:
        return ToolDefinitions.height.title;
      case DashboardItemKind.toolBaking:
        return ToolDefinitions.baking.title;
      case DashboardItemKind.toolLiquids:
        return ToolDefinitions.liquids.title;
      case DashboardItemKind.toolArea:
        return ToolDefinitions.area.title;
      case DashboardItemKind.emptySlot:
        return 'Tile';
    }
  }

  Iterable<_Cell> _cellsForPlaced(_Placed p) sync* {
    // Span is carried on the placement.
    for (var r = 0; r < p.span.rowSpan; r += 1) {
      for (var c = 0; c < p.span.colSpan; c += 1) {
        yield _Cell(p.col + c, p.row + r);
      }
    }
  }

  Set<_Cell> _occupiedCells(List<_Placed> placed) {
    final out = <_Cell>{};
    for (final p in placed) {
      out.addAll(_cellsForPlaced(p));
    }
    return out;
  }

  List<_Cell> _placeholderCells(Set<_Cell> occupied, int cols, int rows) {
    final out = <_Cell>[];
    for (var r = 0; r < rows; r += 1) {
      for (var c = 0; c < cols; c += 1) {
        final cell = _Cell(c, r);
        if (!occupied.contains(cell)) {
          out.add(cell);
        }
      }
    }
    return out;
  }

  Future<void> _showToolPicker(
    BuildContext context, {
    DashboardAnchor? anchor,
  }) async {
    final picked = await showModalBottomSheet<ToolDefinition>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => const ToolPickerSheet(),
    );
    if (picked == null) return;

    if (!context.mounted) return;

    await widget.layout.addTool(picked, anchor: anchor);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${picked.title}')));
  }

  (String, String) _pickToolLabels({
    required ToolDefinition tool,
    required ConversionRecord? latest,
    required Place? activePlace,
  }) {
    // Default to tool defaults, then prefer the most recent run.
    var a = latest?.inputLabel ?? tool.defaultPrimary;
    var b = latest?.outputLabel ?? tool.defaultSecondary;

    final preferMetric = (activePlace?.unitSystem ?? 'metric') == 'metric';
    final aIsMetric = _isMetricLabel(tool.id, a);
    final bIsMetric = _isMetricLabel(tool.id, b);

    if (preferMetric) {
      if (!aIsMetric && bIsMetric) return (b, a);
      return (a, b);
    }
    // Prefer imperial.
    final aIsImperial = !aIsMetric;
    final bIsImperial = !bIsMetric;
    if (!aIsImperial && bIsImperial) return (b, a);
    return (a, b);
  }

  bool _isMetricLabel(String toolId, String label) {
    final l = label.toLowerCase();
    return switch (toolId) {
      'height' => l.contains('cm'),
      'baking' => l.contains('ml'),
      'liquids' => l.contains('ml'),
      'area' => l.contains('m²') || l.contains('m2'),
      _ => false,
    };
  }

  static DashboardItemKind _kindForToolId(String id) {
    switch (id) {
      case 'height':
        return DashboardItemKind.toolHeight;
      case 'baking':
        return DashboardItemKind.toolBaking;
      case 'liquids':
        return DashboardItemKind.toolLiquids;
      case 'area':
        return DashboardItemKind.toolArea;
      default:
        return DashboardItemKind.toolHeight;
    }
  }

  static Place? _pickHome(List<Place> places) {
    for (final p in places) {
      if (p.type == PlaceType.living) return p;
    }
    return places.isEmpty ? null : places.first;
  }

  static Place? _pickDestination(List<Place> places) {
    for (final p in places) {
      if (p.type == PlaceType.visiting) return p;
    }
    if (places.length >= 2) return places[1];
    return places.isEmpty ? null : places.first;
  }

  List<_Placed> _place(List<DashboardBoardItem> items, int cols) {
    final occupancy = <List<bool>>[];

    bool canFit(int col, int row, DashboardTileSpan span) {
      if (col + span.colSpan > cols) return false;
      for (var r = row; r < row + span.rowSpan; r++) {
        while (occupancy.length <= r) {
          occupancy.add(List<bool>.filled(cols, false));
        }
        for (var c = col; c < col + span.colSpan; c++) {
          if (occupancy[r][c]) return false;
        }
      }
      return true;
    }

    void occupy(int col, int row, DashboardTileSpan span) {
      for (var r = row; r < row + span.rowSpan; r++) {
        for (var c = col; c < col + span.colSpan; c++) {
          occupancy[r][c] = true;
        }
      }
    }

    final placed = <_Placed>[];
    final unanchored = <DashboardBoardItem>[];

    // First pass: attempt to place anchored items exactly where the user tapped.
    for (final item in items) {
      if (item.anchor == null) {
        unanchored.add(item);
        continue;
      }

      final clampedSpan = DashboardTileSpan(
        colSpan: math.min(item.span.colSpan, cols),
        rowSpan: item.span.rowSpan,
      );

      final index = item.anchor!.index;
      final targetRow = index ~/ cols;
      final targetCol = index % cols;

      if (canFit(targetCol, targetRow, clampedSpan)) {
        occupy(targetCol, targetRow, clampedSpan);
        placed.add(
          _Placed(
            item: item,
            col: targetCol,
            row: targetRow,
            span: clampedSpan,
          ),
        );
      } else {
        // If the anchor can no longer be honored (different columns, overlaps,
        // or span changes), fall back to dense placement.
        unanchored.add(item);
      }
    }

    // Second pass: dense placement for everything else.
    for (final item in unanchored) {
      final clampedSpan = DashboardTileSpan(
        colSpan: math.min(item.span.colSpan, cols),
        rowSpan: item.span.rowSpan,
      );

      var row = 0;
      var didPlace = false;

      while (!didPlace) {
        for (var col = 0; col < cols; col++) {
          if (canFit(col, row, clampedSpan)) {
            occupy(col, row, clampedSpan);
            placed.add(
              _Placed(item: item, col: col, row: row, span: clampedSpan),
            );
            didPlace = true;
            break;
          }
        }
        if (!didPlace) row++;
      }
    }

    // Keep stacking order deterministic.
    placed.sort((a, b) {
      final byRow = a.row.compareTo(b.row);
      if (byRow != 0) return byRow;
      return a.col.compareTo(b.col);
    });

    return placed;
  }
}

class _Cell {
  final int col;
  final int row;

  const _Cell(this.col, this.row);

  @override
  bool operator ==(Object other) {
    return other is _Cell && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}

class _AddToolTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddToolTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fg = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final border = theme.dividerColor.withValues(alpha: 0.35);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Center(child: Icon(Icons.add, size: 40, color: fg)),
        ),
      ),
    );
  }
}

class ToolPickerSheet extends StatelessWidget {
  const ToolPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = ToolDefinitions.all;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text('Choose a tool', style: theme.textTheme.titleMedium),
        ),
        for (final tool in tools)
          ListTile(
            leading: Icon(tool.icon),
            title: Text(tool.title),
            subtitle: Text(_lensNameForId(tool.lensId)),
            onTap: () => Navigator.of(context).pop(tool),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EditRemoveBadge extends StatelessWidget {
  final VoidCallback onTap;

  const _EditRemoveBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.close, size: 18, color: scheme.error),
        ),
      ),
    );
  }
}

class _Placed {
  final DashboardBoardItem item;
  final int col;
  final int row;
  final DashboardTileSpan span;

  const _Placed({
    required this.item,
    required this.col,
    required this.row,
    required this.span,
  });
}

enum _TileEditAction { replace, remove }
