import 'package:flutter/foundation.dart';

@immutable
class DashboardTileSpan {
  final int colSpan;
  final int rowSpan;

  const DashboardTileSpan({required this.colSpan, required this.rowSpan});

  static const DashboardTileSpan oneByOne = DashboardTileSpan(
    colSpan: 1,
    rowSpan: 1,
  );

  static const DashboardTileSpan twoByOne = DashboardTileSpan(
    colSpan: 2,
    rowSpan: 1,
  );

  static const DashboardTileSpan twoByTwo = DashboardTileSpan(
    colSpan: 2,
    rowSpan: 2,
  );

  /// A hero tile that spans the full row across typical breakpoints.
  ///
  /// The board clamps spans to the available column count, so using a larger
  /// colSpan here allows the tile to become full-width on 2, 3, and 4-column
  /// layouts without special-case logic.
  static const DashboardTileSpan fullWidthTwoTall = DashboardTileSpan(
    colSpan: 4,
    rowSpan: 2,
  );
}

/// Optional anchor that pins an item to a specific logical slot.
///
/// We store a 1D row-major [index] (row * cols + col) based on the column
/// count at the time the user tapped a "+" tile. When the column count changes
/// (phone vs tablet), the board maps the same index into the new grid.
@immutable
class DashboardAnchor {
  final int index;

  const DashboardAnchor({required this.index});
}

enum DashboardItemKind {
  placesHero,

  /// Generic tool tile keyed by [DashboardBoardItem.toolId].
  tool,

  // Legacy tool kinds kept for backward-compatible persistence.
  toolHeight,
  toolBaking,
  toolLiquids,
  toolArea,
  emptySlot,
}

@immutable
class DashboardBoardItem {
  final String id;
  final DashboardItemKind kind;
  final DashboardTileSpan span;

  /// Tool identifier for [DashboardItemKind.tool] tiles.
  ///
  /// This value is persisted and used for Keys, lookup, and future engine
  /// routing. Legacy tool kinds are migrated to this field on load.
  final String? toolId;

  /// If present, the board will attempt to place this item at the anchored slot
  /// before running the dense packing algorithm.
  final DashboardAnchor? anchor;

  /// True if this tile was created by the user (not part of the default set).
  ///
  /// This enables edit affordances like long-press actions.
  final bool userAdded;

  const DashboardBoardItem({
    required this.id,
    required this.kind,
    required this.span,
    this.toolId,
    this.anchor,
    this.userAdded = false,
  });
}
