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
}

enum DashboardItemKind {
  destinationSummary,
  homeSummary,
  quickTemp,
  quickDistance,
  quickCurrency,
  addTile,
}

@immutable
class DashboardBoardItem {
  final String id;
  final DashboardItemKind kind;
  final DashboardTileSpan span;

  const DashboardBoardItem({
    required this.id,
    required this.kind,
    required this.span,
  });
}
