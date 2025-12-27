import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../models/place.dart';
import '../../../theme/theme_extensions.dart';
import '../models/dashboard_board_item.dart';
import 'unitana_tile.dart';

class DashboardBoard extends StatelessWidget {
  final UnitanaAppState state;
  final double availableWidth;

  const DashboardBoard({
    super.key,
    required this.state,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cols = _columnsForWidth(availableWidth);
    final items = _defaultItems();

    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final gap = layout?.gridGap ?? 12.0;

    final cell = _cellSize(availableWidth, cols, gap);

    final placements = _place(items, cols);
    final rows = placements.isEmpty
        ? 1
        : (placements.map((p) => p.row + p.span.rowSpan).reduce(math.max));

    final height = rows * cell + (rows - 1) * gap;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          for (final p in placements)
            Positioned(
              left: p.col * (cell + gap),
              top: p.row * (cell + gap),
              width: p.span.colSpan * cell + (p.span.colSpan - 1) * gap,
              height: p.span.rowSpan * cell + (p.span.rowSpan - 1) * gap,
              child: _buildTile(context, p.item),
            ),
        ],
      ),
    );
  }

  static int _columnsForWidth(double w) {
    if (w >= 840) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  static double _cellSize(double width, int cols, double gap) {
    final totalGap = gap * (cols - 1);
    return (width - totalGap) / cols;
  }

  List<DashboardBoardItem> _defaultItems() {
    return const [
      DashboardBoardItem(
        id: 'dest',
        kind: DashboardItemKind.destinationSummary,
        span: DashboardTileSpan.twoByOne,
      ),
      DashboardBoardItem(
        id: 'home',
        kind: DashboardItemKind.homeSummary,
        span: DashboardTileSpan.twoByOne,
      ),
      DashboardBoardItem(
        id: 'temp',
        kind: DashboardItemKind.quickTemp,
        span: DashboardTileSpan.oneByOne,
      ),
      DashboardBoardItem(
        id: 'dist',
        kind: DashboardItemKind.quickDistance,
        span: DashboardTileSpan.oneByOne,
      ),
      DashboardBoardItem(
        id: 'currency',
        kind: DashboardItemKind.quickCurrency,
        span: DashboardTileSpan.twoByTwo,
      ),
      DashboardBoardItem(
        id: 'add',
        kind: DashboardItemKind.addTile,
        span: DashboardTileSpan.oneByOne,
      ),
    ];
  }

  Widget _buildTile(BuildContext context, DashboardBoardItem item) {
    final home = _pickHome(state.places);
    final dest = _pickDestination(state.places);

    switch (item.kind) {
      case DashboardItemKind.destinationSummary:
        return _placeTile(
          context,
          label: 'Destination',
          place: dest,
          otherPlace: home,
          footer: 'Saved',
          icon: Icons.place_rounded,
          onTap: () => _snack(context, 'Destination tile (coming soon).'),
        );

      case DashboardItemKind.homeSummary:
        return _placeTile(
          context,
          label: 'Home',
          place: home,
          otherPlace: dest,
          footer: 'Saved',
          icon: Icons.home_rounded,
          onTap: () => _snack(context, 'Home tile (coming soon).'),
        );

      case DashboardItemKind.quickTemp:
        return _converterTile(
          context,
          title: 'Temperature',
          icon: Icons.device_thermostat_rounded,
          primary: _formatTempForDestination(dest),
          secondary: _formatTempForHome(home),
          footer: 'Tap to convert',
          onTap: () => _snack(context, 'Temp converter (coming soon).'),
        );

      case DashboardItemKind.quickDistance:
        return _converterTile(
          context,
          title: 'Distance',
          icon: Icons.straighten_rounded,
          primary: _formatDistanceForDestination(dest),
          secondary: _formatDistanceForHome(home),
          footer: 'Tap to convert',
          onTap: () => _snack(context, 'Distance converter (coming soon).'),
        );

      case DashboardItemKind.quickCurrency:
        final pair = _currencyPair(home, dest);
        return _converterTile(
          context,
          title: 'Currency',
          icon: Icons.currency_exchange_rounded,
          primary: pair.primary,
          secondary: pair.secondary,
          footer: 'Tap to convert',
          hint: '${pair.fromCode} to ${pair.toCode}',
          onTap: () => _snack(context, 'Currency converter (coming soon).'),
        );

      case DashboardItemKind.addTile:
        final brand = Theme.of(context).extension<UnitanaBrandTokens>();
        return UnitanaTile(
          // Keep this tile intentionally minimal for now. We'll flesh out
          // customization UX once the feature flow is finalized.
          title: 'Custom',
          primary: 'Custom',
          secondary: '',
          footer: '',
          leadingIcon: Icons.add_rounded,
          backgroundGradient: brand?.brandGradient,
          onTap: () => _snack(context, 'Add tile (coming soon).'),
        );
    }
  }

  Widget _converterTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String primary,
    required String secondary,
    required String footer,
    String? hint,
    VoidCallback? onTap,
  }) {
    return UnitanaTile(
      title: title,
      primary: primary,
      secondary: secondary,
      footer: footer,
      hint: hint,
      leadingIcon: icon,
      onTap: onTap,
    );
  }

  Widget _placeTile(
    BuildContext context, {
    required String label,
    required Place? place,
    required Place? otherPlace,
    required String footer,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    if (place == null) {
      return UnitanaTile(
        title: label,
        primary: 'Not set',
        secondary: 'Run setup to add a place',
        footer: 'Setup',
        leadingIcon: icon,
        onTap: onTap,
      );
    }

    final diff = _timeZoneDiffLabel(otherPlace, place);
    final secondary = diff == null
        ? place.timeZoneId
        : '${place.timeZoneId} $diff';

    final units = place.unitSystem == 'metric' ? 'Metric' : 'Imperial';
    final clock = place.use24h ? '24h' : '12h';

    return UnitanaTile(
      title: label,
      primary: place.cityName,
      secondary: secondary,
      hint: 'Units: $units | Clock: $clock',
      footer: footer,
      leadingIcon: icon,
      onTap: onTap,
    );
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  static String? _timeZoneDiffLabel(Place? reference, Place? place) {
    if (reference == null || place == null) return null;

    final ref = _tzOffsetHours(reference.timeZoneId);
    final cur = _tzOffsetHours(place.timeZoneId);
    if (ref == null || cur == null) return null;

    final delta = cur - ref;
    if (delta == 0) return '(same as Home)';

    final sign = delta > 0 ? '+' : '';
    return '($sign${delta}h vs Home)';
  }

  static int? _tzOffsetHours(String tzId) {
    // Minimal starter map; replace with timezone math later.
    switch (tzId) {
      case 'America/Denver':
        return -7;
      case 'America/Los_Angeles':
        return -8;
      case 'America/New_York':
        return -5;
      case 'Europe/Lisbon':
        return 0;
      case 'Europe/London':
        return 0;
      case 'Europe/Paris':
        return 1;
      default:
        return null;
    }
  }

  static String _formatTempForDestination(Place? dest) {
    final metric = dest?.unitSystem == 'metric';
    final degree = String.fromCharCode(0x00B0);
    return metric ? '20${degree}C' : '68${degree}F';
  }

  static String _formatTempForHome(Place? home) {
    final metric = home?.unitSystem == 'metric';
    final degree = String.fromCharCode(0x00B0);
    return metric ? 'Home: 20${degree}C' : 'Home: 68${degree}F';
  }

  static String _formatDistanceForDestination(Place? dest) {
    final metric = dest?.unitSystem == 'metric';
    return metric ? '16 km' : '10 mi';
  }

  static String _formatDistanceForHome(Place? home) {
    final metric = home?.unitSystem == 'metric';
    return metric ? 'Home: 16 km' : 'Home: 10 mi';
  }

  static _CurrencyPair _currencyPair(Place? home, Place? dest) {
    final fromCode = _currencyForCountry(home?.countryCode);
    final toCode = _currencyForCountry(dest?.countryCode);

    // Placeholder example: show destination amount as the primary line.
    final primary = _formatMoney(toCode, 10);
    final secondary = 'Approx: ${_formatMoney(fromCode, 11)}';

    return _CurrencyPair(
      fromCode: fromCode,
      toCode: toCode,
      primary: primary,
      secondary: secondary,
    );
  }

  static String _currencyForCountry(String? countryCode) {
    switch (countryCode) {
      case 'US':
        return 'USD';
      case 'CA':
        return 'CAD';
      case 'GB':
        return 'GBP';
      case 'PT':
      case 'DE':
      case 'FR':
      case 'ES':
      case 'IT':
        return 'EUR';
      default:
        return 'EUR';
    }
  }

  static String _formatMoney(String code, num amount) {
    final symbol = switch (code) {
      'USD' => r'$',
      'CAD' => r'CA$',
      'EUR' => String.fromCharCode(0x20AC),
      'GBP' => String.fromCharCode(0x00A3),
      _ => '',
    };

    if (symbol.isEmpty) return '$amount $code';
    return '$symbol$amount';
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

    for (final item in items) {
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

    return placed;
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

class _CurrencyPair {
  final String fromCode;
  final String toCode;
  final String primary;
  final String secondary;

  const _CurrencyPair({
    required this.fromCode,
    required this.toCode,
    required this.primary,
    required this.secondary,
  });
}
