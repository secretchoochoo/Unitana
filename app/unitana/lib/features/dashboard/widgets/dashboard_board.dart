import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../data/cities.dart' show kCurrencySymbols;
import '../../../data/country_currency_map.dart';
import '../../../models/place.dart';
import '../../../common/feedback/unitana_toast.dart';
import '../../../utils/timezone_utils.dart';
import '../models/dashboard_board_item.dart';
import '../models/dashboard_copy.dart';
import '../models/dashboard_live_data.dart';
import '../models/dashboard_layout_controller.dart';
import '../models/dashboard_session_controller.dart';
import '../models/flight_time_estimator.dart';
import '../models/jet_lag_planner.dart';
import '../models/place_geo_lookup.dart';
import '../models/time_zone_catalog.dart';
import '../models/tool_definitions.dart';
import '../models/activity_lenses.dart';
import '../models/tool_registry.dart';
import '../models/lens_accents.dart';
import 'destructive_confirmation_sheet.dart';
import 'places_hero_v2.dart';
import 'tool_modal_bottom_sheet.dart';
import 'unitana_tile.dart';
import 'weather_summary_bottom_sheet.dart';

// Layout constants for the dashboard grid.
//
// Baseline row counts intentionally leave visible empty slots so add-widget
// targets remain discoverable in non-edit mode.
// - Phone (2 cols): 9 rows.
// - Tablet (3 cols): 8 rows.
const int _minRowsPhone = 9;
const int _minRowsTablet = 8;
const double _gap = 12.0;
const double _tileHeightRatio = 0.78;

class _DragTilePayload {
  final bool isDefault;
  final String toolIdOrItemId;
  final int currentIndex;

  const _DragTilePayload({
    required this.isDefault,
    required this.toolIdOrItemId,
    required this.currentIndex,
  });
}

class DashboardBoard extends StatefulWidget {
  final UnitanaAppState state;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;
  final DashboardLayoutController layout;
  final double availableWidth;
  final bool isEditing;

  /// When true, the grid can render the Places Hero as a normal tile.
  ///
  /// The dashboard now also supports a pinned/collapsing Places Hero header.
  /// In that configuration we must not render a second hero inside the grid,
  /// otherwise tests (and users) will see duplicate hero widgets.
  final bool includePlacesHero;
  final String? focusActionTileId;
  final String? focusToolTileId;
  final ValueChanged<String?> onEnteredEditMode;
  final VoidCallback onConsumedFocusTileId;
  final VoidCallback onConsumedFocusToolTileId;
  const DashboardBoard({
    super.key,
    required this.state,
    required this.session,
    required this.liveData,
    required this.layout,
    required this.availableWidth,
    required this.isEditing,
    this.includePlacesHero = true,
    required this.focusActionTileId,
    required this.focusToolTileId,
    required this.onEnteredEditMode,
    required this.onConsumedFocusTileId,
    required this.onConsumedFocusToolTileId,
  });

  @override
  State<DashboardBoard> createState() => _DashboardBoardState();
}

class _DashboardBoardState extends State<DashboardBoard>
    with SingleTickerProviderStateMixin {
  String? _lastFocusId;
  bool _pendingShowActions = false;
  String? _lastFocusToolId;
  bool _pendingFocusTool = false;
  final Map<String, GlobalKey> _toolTileKeysByItemId = <String, GlobalKey>{};
  final Map<String, String> _firstVisibleItemIdForTool = <String, String>{};
  final Set<String> _pulsingToolIds = <String>{};
  final Map<String, Timer> _pulseTimers = <String, Timer>{};
  String? _lastSeedSignature;

  late final AnimationController _wiggle;

  bool _dashboardHasToolId(String toolId, {String? ignoreItemId}) {
    // Includes visible default tiles and user-added tiles.
    if (ToolDefinitions.defaultTiles.any(
      (t) => t.id == toolId && !widget.layout.isDefaultToolHidden(t.id),
    )) {
      return true;
    }
    return widget.layout.items.any(
      (i) =>
          i.toolId == toolId && (ignoreItemId == null || i.id != ignoreItemId),
    );
  }

  bool _isDefaultToolTile(DashboardBoardItem item) {
    final toolId = item.toolId;
    if (item.kind != DashboardItemKind.tool || toolId == null) return false;
    if (item.userAdded) return false;
    return ToolDefinitions.defaultTiles.any((t) => t.id == toolId);
  }

  double _wiggleAngleFor(String id) {
    // Gentle, phase-shifted jiggle while in edit mode (home-screen style).
    final phase = (id.hashCode % 360) * (math.pi / 180.0);

    // 0 → 1 repeating. Keep it subtle to avoid nausea and preserve readability.
    final v = _wiggle.value;
    final carrier = math.sin(
      (v * 2 * math.pi * 2) + phase,
    ); // ~2 wiggles per cycle

    return carrier * 0.014;
  }

  Widget _maybeWiggle(String id, Widget child) {
    if (!widget.isEditing) return child;
    return AnimatedBuilder(
      animation: _wiggle,
      builder: (context, _) {
        return Transform.rotate(angle: _wiggleAngleFor(id), child: child);
      },
    );
  }

  _DragTilePayload _payloadForToolTile({
    required DashboardBoardItem item,
    required int currentIndex,
  }) {
    final toolId = item.toolId ?? item.id;
    final isDefault = _isDefaultToolTile(item);
    return _DragTilePayload(
      isDefault: isDefault,
      toolIdOrItemId: isDefault ? toolId : item.id,
      currentIndex: currentIndex,
    );
  }

  Future<void> _setAnchorIndex(_DragTilePayload payload, int? index) async {
    if (payload.isDefault) {
      await widget.layout.setDefaultToolAnchorIndex(
        payload.toolIdOrItemId,
        index,
      );
    } else {
      await widget.layout.setUserItemAnchorIndex(payload.toolIdOrItemId, index);
    }
  }

  Future<void> _handleDrop({
    required _DragTilePayload dragged,
    required int targetIndex,
    _DragTilePayload? target,
  }) async {
    if (dragged.currentIndex == targetIndex) {
      return;
    }
    if (target != null && target.toolIdOrItemId == dragged.toolIdOrItemId) {
      return;
    }
    await _setAnchorIndex(dragged, targetIndex);
    if (target != null) {
      await _setAnchorIndex(target, dragged.currentIndex);
    }

    // The layout controller persists anchor indices, but the dashboard needs an
    // immediate rebuild so the user (and widget tests) see the updated order
    // without waiting for an unrelated state change.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _freezeVisibleAnchorsForEdit() async {
    final cols = widget.availableWidth >= 520 ? 3 : 2;
    final heroAnchorOffset = _heroAnchorOffsetForCols(cols);
    int adjustAnchor(int raw) =>
        heroAnchorOffset == 0 ? raw : math.max(0, raw - heroAnchorOffset);

    final toolItems = ToolDefinitions.defaultTiles
        .where((t) => !widget.layout.isDefaultToolHidden(t.id))
        .map(
          (t) => DashboardBoardItem(
            id: t.id,
            kind: DashboardItemKind.tool,
            span: DashboardTileSpan.oneByOne,
            toolId: t.id,
            anchor: widget.layout.defaultToolAnchorIndex(t.id) == null
                ? null
                : DashboardAnchor(
                    index: adjustAnchor(
                      widget.layout.defaultToolAnchorIndex(t.id)!,
                    ),
                  ),
          ),
        )
        .toList();

    final adjustedUserItems = widget.layout.items.map((i) {
      final a = i.anchor;
      if (a == null) return i;
      if (heroAnchorOffset == 0) return i;
      return DashboardBoardItem(
        id: i.id,
        kind: i.kind,
        span: i.span,
        toolId: i.toolId,
        userAdded: i.userAdded,
        anchor: DashboardAnchor(index: adjustAnchor(a.index)),
      );
    }).toList();

    final items = <DashboardBoardItem>[
      if (widget.includePlacesHero)
        const DashboardBoardItem(
          id: 'places_hero_v2',
          kind: DashboardItemKind.placesHero,
          span: DashboardTileSpan.fullWidthTwoTall,
        ),
      ...toolItems,
      ...adjustedUserItems,
    ];

    final placed = _place(items, cols);
    for (final p in placed) {
      final item = p.item;
      if (item.kind == DashboardItemKind.placesHero) continue;
      if (item.toolId == null) continue;
      final index = p.row * cols + p.col;
      final payload = _payloadForToolTile(item: item, currentIndex: index);
      await _setAnchorIndex(payload, index);
    }

    if (mounted) {
      setState(() {});
    }
  }

  List<int> _legacyAnchors() {
    if (widget.includePlacesHero) return const <int>[];
    final legacyAnchors = <int>[];
    for (final t in ToolDefinitions.defaultTiles) {
      final idx = widget.layout.defaultToolAnchorIndex(t.id);
      if (idx != null) legacyAnchors.add(idx);
    }
    return legacyAnchors;
  }

  int _heroAnchorOffsetForCols(int cols) {
    const heroRows = 2;
    final legacyAnchors = _legacyAnchors();
    if (legacyAnchors.isEmpty) return 0;
    final minRow = legacyAnchors.map((a) => a ~/ cols).reduce(math.min);
    final needsLegacyHeroOffset = minRow >= heroRows;
    return needsLegacyHeroOffset ? cols * heroRows : 0;
  }

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isEditing) {
      _wiggle.repeat();
    }
    _syncFocus(widget.focusActionTileId);
    _syncToolFocus(widget.focusToolTileId);
  }

  @override
  void didUpdateWidget(covariant DashboardBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusActionTileId != widget.focusActionTileId) {
      _syncFocus(widget.focusActionTileId);
    }
    if (oldWidget.focusToolTileId != widget.focusToolTileId) {
      _syncToolFocus(widget.focusToolTileId);
    }

    if (oldWidget.isEditing != widget.isEditing) {
      if (widget.isEditing) {
        _wiggle.repeat();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !widget.isEditing) return;
          unawaited(_freezeVisibleAnchorsForEdit());
        });
      } else {
        _wiggle.stop();
        _wiggle.value = 0.0;
      }
    }
  }

  void _syncFocus(String? id) {
    _lastFocusId = id;
    _pendingShowActions = id != null && id.trim().isNotEmpty;
  }

  void _syncToolFocus(String? toolId) {
    _lastFocusToolId = toolId;
    _pendingFocusTool = toolId != null && toolId.trim().isNotEmpty;
  }

  GlobalKey _toolTileKeyForItem(String itemId) {
    return _toolTileKeysByItemId.putIfAbsent(itemId, GlobalKey.new);
  }

  Future<void> _pulseToolTile(String toolId) async {
    if (!mounted) return;
    _pulseTimers.remove(toolId)?.cancel();
    setState(() {
      _pulsingToolIds.add(toolId);
    });
    _pulseTimers[toolId] = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _pulsingToolIds.remove(toolId);
      });
      _pulseTimers.remove(toolId);
    });
  }

  Future<void> _focusExistingToolTile(String toolId) async {
    final targetItemId = _firstVisibleItemIdForTool[toolId];
    if (targetItemId == null || targetItemId.trim().isEmpty) return;
    final targetContext = _toolTileKeyForItem(targetItemId).currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
    if (!mounted) return;
    unawaited(_pulseToolTile(toolId));
  }

  Widget _wrapToolFocusFrame({
    required String itemId,
    required String toolId,
    required Widget child,
  }) {
    final pulsing = _pulsingToolIds.contains(toolId);
    final pulseColor = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      key: _toolTileKeyForItem(itemId),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pulsing ? pulseColor.withAlpha(225) : Colors.transparent,
          width: pulsing ? 2.6 : 0,
        ),
        boxShadow: pulsing
            ? <BoxShadow>[
                BoxShadow(
                  color: pulseColor.withAlpha(80),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }

  void _showTransientBanner(String text, {String? bannerKey}) {
    UnitanaToast.showSuccess(
      context,
      text,
      key: bannerKey == null ? null : ValueKey(bannerKey),
    );
  }

  void _maybeEnsureSeeded(Place? home, Place? dest) {
    final signature = '${home?.id ?? 'none'}|${dest?.id ?? 'none'}';
    if (_lastSeedSignature == signature) return;
    _lastSeedSignature = signature;
    widget.liveData.ensureSeeded([
      if (home != null) home,
      if (dest != null) dest,
    ]);
  }

  @override
  void dispose() {
    for (final timer in _pulseTimers.values) {
      timer.cancel();
    }
    _pulseTimers.clear();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingFocusTool && _lastFocusToolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final toolId = _lastFocusToolId;
        if (toolId == null) return;
        _pendingFocusTool = false;
        widget.onConsumedFocusToolTileId();
        unawaited(_focusExistingToolTile(toolId));
      });
    }

    if (widget.isEditing && _pendingShowActions && _lastFocusId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        final id = _lastFocusId;
        if (id == null) {
          return;
        }
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
        if (item.id.isEmpty) {
          return;
        }
        await _showTileActions(context, item);
      });
    }

    final places = widget.state.places;
    final home = _pickHome(places);
    final dest = _pickDestination(places);

    // Seed per-place snapshots when place context changes.
    _maybeEnsureSeeded(home, dest);

    final cols = widget.availableWidth >= 520 ? 3 : 2;

    // Some persisted anchors still encode the old in-grid hero offset.
    // Remove it only when anchors clearly match that legacy shape.
    final heroAnchorOffset = _heroAnchorOffsetForCols(cols);

    int adjustAnchor(int raw) =>
        heroAnchorOffset == 0 ? raw : math.max(0, raw - heroAnchorOffset);

    final toolItems = ToolDefinitions.defaultTiles
        .where((t) => !widget.layout.isDefaultToolHidden(t.id))
        .map(
          (t) => DashboardBoardItem(
            id: t.id,
            kind: DashboardItemKind.tool,
            span: DashboardTileSpan.oneByOne,
            toolId: t.id,
            anchor: widget.layout.defaultToolAnchorIndex(t.id) == null
                ? null
                : DashboardAnchor(
                    index: adjustAnchor(
                      widget.layout.defaultToolAnchorIndex(t.id)!,
                    ),
                  ),
          ),
        )
        .toList();

    final adjustedUserItems = widget.layout.items.map((i) {
      final a = i.anchor;
      if (a == null) return i;
      if (heroAnchorOffset == 0) return i;
      return DashboardBoardItem(
        id: i.id,
        kind: i.kind,
        span: i.span,
        toolId: i.toolId,
        userAdded: i.userAdded,
        anchor: DashboardAnchor(index: adjustAnchor(a.index)),
      );
    }).toList();

    final items = <DashboardBoardItem>[
      if (widget.includePlacesHero)
        const DashboardBoardItem(
          id: 'places_hero_v2',
          kind: DashboardItemKind.placesHero,
          span: DashboardTileSpan.fullWidthTwoTall,
        ),
      ...toolItems,
      ...adjustedUserItems,
    ];

    final placed = _place(items, cols);
    _firstVisibleItemIdForTool.clear();
    for (final placedItem in placed) {
      final toolId = placedItem.item.toolId;
      if (toolId == null) continue;
      _firstVisibleItemIdForTool.putIfAbsent(toolId, () => placedItem.item.id);
    }
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
              child: widget.isEditing
                  ? DragTarget<_DragTilePayload>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) => _handleDrop(
                        dragged: details.data,
                        targetIndex: cell.row * cols + cell.col,
                      ),
                      builder: (context, candidates, rejects) {
                        return _AddToolTile(
                          key: ValueKey(
                            'dashboard_add_slot_${cell.row}_${cell.col}',
                          ),
                          onTap: () => _showToolPicker(
                            context,
                            anchor: DashboardAnchor(
                              index: cell.row * cols + cell.col,
                            ),
                          ),
                        );
                      },
                    )
                  : _AddToolTile(
                      key: ValueKey(
                        'dashboard_add_slot_${cell.row}_${cell.col}',
                      ),
                      onTap: () => _showToolPicker(
                        context,
                        anchor: DashboardAnchor(
                          index: cell.row * cols + cell.col,
                        ),
                      ),
                    ),
            ),
          for (final p in placed)
            Positioned(
              left: p.col * (tileW + _gap),
              top: p.row * (tileH + _gap),
              width: p.span.colSpan * tileW + (p.span.colSpan - 1) * _gap,
              height: p.span.rowSpan * tileH + (p.span.rowSpan - 1) * _gap,
              child: _buildTile(
                context,
                p.item,
                home,
                dest,
                currentIndex: p.row * cols + p.col,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    DashboardBoardItem item,
    Place? home,
    Place? dest, {
    required int currentIndex,
  }) {
    final activePlace = widget.session.reality == DashboardReality.home
        ? home
        : dest;

    switch (item.kind) {
      case DashboardItemKind.placesHero:
        if (!widget.includePlacesHero) {
          return const SizedBox.shrink();
        }
        return PlacesHeroV2(
          key: const Key('places_hero_v2'),
          home: home,
          destination: dest,
          session: widget.session,
          liveData: widget.liveData,
        );
      case DashboardItemKind.tool ||
          DashboardItemKind.toolHeight ||
          DashboardItemKind.toolBaking ||
          DashboardItemKind.toolLiquids ||
          DashboardItemKind.toolArea:
        final toolId = item.toolId ?? _legacyToolIdForKind(item.kind);
        final tool = toolId == null ? null : ToolDefinitions.byId(toolId);
        if (tool == null) {
          return _missingToolTile(context, item, toolId ?? 'unknown');
        }
        final secondaryPlace = widget.session.reality == DashboardReality.home
            ? dest
            : home;
        return _toolTile(
          context,
          item,
          tool,
          currentIndex: currentIndex,
          activePlace: activePlace,
          secondaryPlace: secondaryPlace,
          home: home,
          destination: dest,
        );
      case DashboardItemKind.emptySlot:
        // Empty slots are rendered separately as “+” placeholders.
        return const SizedBox.shrink();
    }
  }

  String? _legacyToolIdForKind(DashboardItemKind kind) {
    return switch (kind) {
      DashboardItemKind.toolHeight => 'height',
      DashboardItemKind.toolBaking => 'baking',
      DashboardItemKind.toolLiquids => 'liquids',
      DashboardItemKind.toolArea => 'area',
      _ => null,
    };
  }

  Widget _missingToolTile(
    BuildContext context,
    DashboardBoardItem item,
    String toolId,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('dashboard_item_${item.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          'Missing tool: $toolId',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _toolTile(
    BuildContext context,
    DashboardBoardItem item,
    ToolDefinition tool, {
    required int currentIndex,
    required Place? activePlace,
    required Place? secondaryPlace,
    required Place? home,
    required Place? destination,
  }) {
    final latest = widget.session.latestFor(tool.id);

    final isWeatherSummary = tool.id == 'weather_summary';

    // Dashboard tiles should always reflect the currently selected reality.
    // Currency is special: even before a user runs the tool, the preview should
    // show a real (or demo) conversion for the active place vs the other place.
    (String, String) currencyPreviewLabels({
      required Place? from,
      required Place? to,
    }) {
      String currencyFor(Place? p) =>
          currencyCodeForCountryCode(p?.countryCode);

      String symbolFor(String c) => kCurrencySymbols[c.toUpperCase()] ?? c;

      final fromCur = currencyFor(from);
      final toCur = currencyFor(to);
      final rate = widget.liveData.currencyRate(
        fromCode: fromCur,
        toCode: toCur,
      );

      double baseFor(double? r) {
        if (r == null || r <= 0) return 1;
        if (r < 0.0002) return 10000;
        if (r < 0.002) return 1000;
        if (r < 0.02) return 100;
        if (r < 0.2) return 10;
        return 1;
      }

      String fmt(double value) {
        if (value >= 100) return value.toStringAsFixed(0);
        if (value >= 10) return value.toStringAsFixed(1);
        if (value >= 1) return value.toStringAsFixed(2);
        if (value >= 0.1) return value.toStringAsFixed(2);
        return value.toStringAsFixed(3);
      }

      final base = baseFor(rate);
      final out = fromCur == toCur ? base : (rate == null ? null : base * rate);
      final primary = '${symbolFor(fromCur)}${fmt(base)}';
      final secondary = out == null
          ? '${symbolFor(toCur)}—'
          : '${symbolFor(toCur)}${fmt(out)}';
      return (primary, secondary);
    }

    (String, String) jetLagPreviewLabels({
      required Place? homePlace,
      required Place? destinationPlace,
    }) {
      if (homePlace == null || destinationPlace == null) {
        return (tool.defaultPrimary, tool.defaultSecondary);
      }

      final nowUtc = DateTime.now().toUtc();
      final homeNow = TimezoneUtils.nowInZone(
        homePlace.timeZoneId,
        nowUtc: nowUtc,
      );
      final destinationNow = TimezoneUtils.nowInZone(
        destinationPlace.timeZoneId,
        nowUtc: nowUtc,
      );
      final plan = JetLagPlanner.planFromZoneTimes(
        fromNow: homeNow,
        toNow: destinationNow,
      );

      final homeGeo = PlaceGeoLookup.forPlace(homePlace);
      final destinationGeo = PlaceGeoLookup.forPlace(destinationPlace);
      final flightEstimate = FlightTimeEstimator.estimate(
        fromLat: homeGeo?.lat,
        fromLon: homeGeo?.lon,
        toLat: destinationGeo?.lat,
        toLon: destinationGeo?.lon,
      );

      final secondary = plan.isNoShift
          ? plan.tileSecondaryLabel
          : (flightEstimate == null
                ? plan.tileSecondaryLabel
                : '${flightEstimate.compactLabel} • ~${plan.adjustmentDays}d adapt');

      return (plan.tilePrimaryLabel, secondary);
    }

    String compactHoursLabel(double value) {
      final rounded = value.roundToDouble();
      final sign = value >= 0 ? '+' : '';
      if ((value - rounded).abs() < 0.01) {
        return '$sign${rounded.toInt()}';
      }
      return '$sign${value.toStringAsFixed(1)}';
    }

    String offsetLabel(double hours) => 'UTC${compactHoursLabel(hours)}';

    String cityLabelFromZone(String zoneId) {
      final parts = zoneId.split('/');
      final leaf = parts.isEmpty ? zoneId : parts.last;
      return leaf.replaceAll('_', ' ').trim();
    }

    String cityLabelFromDisplay(String raw, String fallback) {
      final cleaned = raw
          .replaceFirst(RegExp(r'^\s*(Home|Destination)\s*·\s*'), '')
          .trim();
      final comma = cleaned.indexOf(',');
      if (comma <= 0) return cleaned.isEmpty ? fallback : cleaned;
      final city = cleaned.substring(0, comma).trim();
      return city.isEmpty ? fallback : city;
    }

    ({
      String fromZoneId,
      String toZoneId,
      String fromCity,
      String toCity,
      DateTime fromLocal,
      DateTime toLocal,
      double fromOffsetHours,
      double toOffsetHours,
    })
    resolvedTimePairForTool({required String toolId}) {
      final options = TimeZoneCatalog.options(
        home: home,
        destination: destination,
      );
      final validZoneIds = options.map((o) => o.id).toSet();
      String alternateZoneFor(String zoneId) {
        for (final option in options) {
          if (option.id != zoneId) return option.id;
        }
        return zoneId == 'UTC' ? 'Europe/London' : 'UTC';
      }

      String labelFor(String zoneId) {
        for (final option in options) {
          if (option.id == zoneId) return option.label;
        }
        return zoneId;
      }

      final fallbackFrom =
          activePlace?.timeZoneId ??
          home?.timeZoneId ??
          destination?.timeZoneId ??
          (options.isEmpty ? 'UTC' : options.first.id);
      String fallbackTo =
          secondaryPlace?.timeZoneId ??
          destination?.timeZoneId ??
          home?.timeZoneId ??
          (options.length > 1 ? options[1].id : 'UTC');
      if (fallbackFrom == fallbackTo) {
        fallbackTo = alternateZoneFor(fallbackFrom);
      }

      final saved = widget.session.timeZoneSelectionFor(toolId);
      final fromZoneId =
          saved != null && validZoneIds.contains(saved.fromZoneId)
          ? saved.fromZoneId
          : fallbackFrom;
      String toZoneId = saved != null && validZoneIds.contains(saved.toZoneId)
          ? saved.toZoneId
          : fallbackTo;
      if (fromZoneId == toZoneId) {
        toZoneId = alternateZoneFor(fromZoneId);
      }

      final nowUtc = DateTime.now().toUtc();
      final fromNow = TimezoneUtils.nowInZone(fromZoneId, nowUtc: nowUtc);
      final toNow = TimezoneUtils.nowInZone(toZoneId, nowUtc: nowUtc);
      final fromFallback = cityLabelFromZone(fromZoneId);
      final toFallback = cityLabelFromZone(toZoneId);
      final fromCity = cityLabelFromDisplay(labelFor(fromZoneId), fromFallback);
      final toCity = cityLabelFromDisplay(labelFor(toZoneId), toFallback);
      return (
        fromZoneId: fromZoneId,
        toZoneId: toZoneId,
        fromCity: fromCity,
        toCity: toCity,
        fromLocal: fromNow.local,
        toLocal: toNow.local,
        fromOffsetHours: fromNow.offsetMinutes / 60.0,
        toOffsetHours: toNow.offsetMinutes / 60.0,
      );
    }

    (String, String) worldTimeMapPreviewLabels({
      required String fromCity,
      required String toCity,
      required double fromOffsetHours,
      required double toOffsetHours,
    }) {
      if (fromCity.trim().isEmpty || toCity.trim().isEmpty) {
        return (tool.defaultPrimary, tool.defaultSecondary);
      }
      final deltaHours = toOffsetHours - fromOffsetHours;
      final primary = 'Δ ${compactHoursLabel(deltaHours)}h';
      final secondary =
          '$fromCity ${offsetLabel(fromOffsetHours)} • $toCity ${offsetLabel(toOffsetHours)}';
      return (primary, secondary);
    }

    final worldClockPair = resolvedTimePairForTool(toolId: 'world_clock_delta');
    final timeToolPair = resolvedTimePairForTool(toolId: 'time');

    final isCurrency = tool.id == 'currency_convert';
    final bool currencyLabelsLookBroken =
        isCurrency &&
        latest != null &&
        (latest.outputLabel.contains('{') ||
            latest.outputLabel.contains('eurToUsd') ||
            latest.outputLabel.contains('toStringAsFixed'));
    final currentFromCur = currencyCodeForCountryCode(activePlace?.countryCode);
    final currentToCur = currencyCodeForCountryCode(
      secondaryPlace?.countryCode,
    );
    final latestMatchesCurrentCurrencyPair =
        latest != null &&
        (latest.fromUnit ?? '').trim().toUpperCase() == currentFromCur &&
        (latest.toUnit ?? '').trim().toUpperCase() == currentToCur;

    final labels = isWeatherSummary
        ? _weatherSummaryLabels(activePlace: activePlace)
        : tool.id == 'jet_lag_delta'
        ? jetLagPreviewLabels(homePlace: home, destinationPlace: destination)
        : tool.id == 'world_clock_delta'
        ? worldTimeMapPreviewLabels(
            fromCity: worldClockPair.fromCity,
            toCity: worldClockPair.toCity,
            fromOffsetHours: worldClockPair.fromOffsetHours,
            toOffsetHours: worldClockPair.toOffsetHours,
          )
        : (isCurrency &&
              (latest == null ||
                  currencyLabelsLookBroken ||
                  !latestMatchesCurrentCurrencyPair))
        ? currencyPreviewLabels(from: activePlace, to: secondaryPlace)
        : _pickToolLabels(tool: tool, latest: latest, activePlace: activePlace);
    final preferMetric = (activePlace?.unitSystem ?? 'metric') == 'metric';
    final prefer24h = activePlace?.use24h ?? false;
    final primary = labels.$1;
    final secondary = labels.$2;
    final brightness = Theme.of(context).brightness;
    final localizedWidgetTitle = DashboardCopy.toolWidgetDisplayName(
      context,
      toolId: tool.id,
      fallback: ToolDefinitions.widgetTitleFor(tool),
    );
    final localizedToolTitle = DashboardCopy.toolDisplayName(
      context,
      toolId: tool.id,
      fallback: tool.title,
    );
    final footerLabel = widget.isEditing
        ? ''
        : (isCurrency && widget.liveData.isCurrencyStale)
        ? DashboardCopy.ratesStaleShort(context)
        : DashboardCopy.convertCta(context);

    final isDefaultTile = _isDefaultToolTile(item);
    final canEdit = item.userAdded || isDefaultTile;
    final customBody = !widget.isEditing && tool.id == 'world_clock_delta'
        ? _DashboardWorldTimeMiniMap(
            fromOffsetHours: worldClockPair.fromOffsetHours,
            toOffsetHours: worldClockPair.toOffsetHours,
            fromCity: worldClockPair.fromCity,
            toCity: worldClockPair.toCity,
          )
        : (!widget.isEditing && tool.id == 'time')
        ? _DashboardTimeMiniClocks(
            fromCity: timeToolPair.fromCity,
            toCity: timeToolPair.toCity,
            fromLocal: timeToolPair.fromLocal,
            toLocal: timeToolPair.toLocal,
            fromOffsetHours: timeToolPair.fromOffsetHours,
            toOffsetHours: timeToolPair.toOffsetHours,
            use24h: prefer24h,
          )
        : null;

    final tile = UnitanaTile(
      interactionKey: ValueKey('dashboard_item_${item.id}'),
      title: localizedWidgetTitle,
      // UnitanaTile expects an IconData, not an Icon widget.
      leadingIcon: tool.icon,
      accentColor: tool.lensId == null
          ? null
          : LensAccents.toolIconTintForBrightness(
              toolId: tool.id,
              lensId: tool.lensId,
              brightness: brightness,
            ),
      primary: primary,
      secondary: secondary,
      footer: footerLabel,
      body: customBody,
      primaryDeemphasizedPrefix: null,
      compactValues: widget.isEditing,
      valuesTopInset: widget.isEditing ? 22 : 0,
      onLongPress: canEdit && !widget.isEditing
          ? () {
              if (!widget.isEditing) {
                // Enter edit mode without triggering a second actions sheet.
                widget.onEnteredEditMode(null);
              }
              _showTileActions(context, item, currentIndex: currentIndex);
            }
          : null,
      onTap: widget.isEditing
          ? null
          : () {
              if (isWeatherSummary) {
                WeatherSummaryBottomSheet.show(
                  context,
                  liveData: widget.liveData,
                  home: home,
                  destination: destination,
                );
                return;
              }

              ToolModalBottomSheet.show(
                context,
                tool: tool,
                session: widget.session,
                preferMetric: preferMetric,
                prefer24h: prefer24h,
                eurToUsd: widget.liveData.eurToUsd,
                currencyRateForPair: (fromCode, toCode) => widget.liveData
                    .currencyRate(fromCode: fromCode, toCode: toCode),
                currencyIsStale: widget.liveData.isCurrencyStale,
                currencyShouldRetryNow: widget.liveData.shouldRetryCurrencyNow,
                currencyLastErrorAt: widget.liveData.lastCurrencyErrorAt,
                currencyLastRefreshedAt:
                    widget.liveData.lastCurrencyRefreshedAt,
                currencyNetworkEnabled: widget.liveData.currencyNetworkEnabled,
                currencyRefreshCadence: widget.liveData.currencyRefreshCadence,
                onRetryCurrencyNow: () async {
                  final places = <Place>[
                    if (home != null) home,
                    if (destination != null) destination,
                  ];
                  if (places.isEmpty) return;
                  await widget.liveData.refreshAll(places: places);
                },
                home: home,
                destination: destination,
              );
            },
    );

    if (!widget.isEditing || !canEdit) {
      // IMPORTANT: This key must sit on a RenderBox-backed widget so that
      // long-press interactions are hit-testable in widget tests.
      //
      // KeyedSubtree is not reliably hit-testable because it does not
      // necessarily introduce its own RenderObject.
      return _wrapToolFocusFrame(itemId: item.id, toolId: tool.id, child: tile);
    }

    final payload = _payloadForToolTile(item: item, currentIndex: currentIndex);

    final previewTile = UnitanaTile(
      title: localizedWidgetTitle,
      leadingIcon: tool.icon,
      accentColor: tool.lensId == null
          ? null
          : LensAccents.toolIconTintForBrightness(
              toolId: tool.id,
              lensId: tool.lensId,
              brightness: brightness,
            ),
      primary: primary,
      secondary: secondary,
      footer: '',
      body: null,
      primaryDeemphasizedPrefix: null,
      compactValues: true,
      valuesTopInset: 22,
    );

    final draggableTile = LongPressDraggable<_DragTilePayload>(
      data: payload,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 220,
          height: 172,
          child: Opacity(opacity: 0.9, child: previewTile),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.42, child: tile),
      child: tile,
    );

    final stack = Stack(
      children: [
        draggableTile,
        Positioned(
          top: 38,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EditIconButton(
                icon: Icons.edit_rounded,
                onTap: () =>
                    _showTileActions(context, item, currentIndex: currentIndex),
              ),
              const SizedBox(width: 2),
              _EditIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: () async {
                  final ok = await _confirmRemoveTile(
                    context,
                    localizedToolTitle,
                  );
                  if (!ok) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  if (isDefaultTile) {
                    await widget.layout.hideDefaultTool(tool.id);
                  } else {
                    await widget.layout.removeItem(item.id);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );

    final target = DragTarget<_DragTilePayload>(
      onWillAcceptWithDetails: (details) {
        final incoming = details.data;
        if (incoming.toolIdOrItemId == payload.toolIdOrItemId &&
            incoming.isDefault == payload.isDefault) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) => _handleDrop(
        dragged: details.data,
        targetIndex: currentIndex,
        target: payload,
      ),
      builder: (context, candidates, rejects) => stack,
    );

    return _wrapToolFocusFrame(
      itemId: item.id,
      toolId: tool.id,
      child: _maybeWiggle(item.id, target),
    );
  }

  Future<bool> _confirmRemoveTile(BuildContext context, String label) async {
    return showDestructiveConfirmationSheet(
      context,
      title: DashboardCopy.toolPickerActionRemoveConfirmTitle(context, label),
      message: DashboardCopy.toolPickerActionRemoveConfirmMessage(context),
      confirmLabel: DashboardCopy.toolPickerActionRemoveConfirmCta(context),
    );
  }

  Future<void> _showTileActions(
    BuildContext context,
    DashboardBoardItem item, {
    int? currentIndex,
  }) async {
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
                key: ValueKey('dashboard_tile_action_replace_${item.id}'),
                leading: const Icon(Icons.swap_horiz),
                title: Text(DashboardCopy.toolPickerActionReplace(context)),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_TileEditAction.replace),
              ),
              ListTile(
                key: ValueKey('dashboard_tile_action_remove_${item.id}'),
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  DashboardCopy.toolPickerActionRemove(context),
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

    if (action == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _TileEditAction.replace:
        final picked = await showModalBottomSheet<ToolDefinition>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => FractionallySizedBox(
            heightFactor: 0.85,
            child: ToolPickerSheet(session: widget.session),
          ),
        );
        if (picked == null) {
          return;
        }
        if (!context.mounted) {
          return;
        }
        // Prevent duplicate tiles for the same tool.
        // Allow replacing the tile with the same tool (no-op).
        final currentToolId = item.toolId ?? _legacyToolIdForKind(item.kind);
        if (currentToolId != picked.id &&
            _dashboardHasToolId(picked.id, ignoreItemId: item.id)) {
          UnitanaToast.showError(
            context,
            '${picked.title} is already on your dashboard.',
            key: ValueKey('toast_duplicate_tool_${picked.id}'),
          );
          unawaited(_focusExistingToolTile(picked.id));
          return;
        }
        final isDefaultTile = _isDefaultToolTile(item);
        if (isDefaultTile) {
          // Default tiles are not stored in the user layout list; hide the default and add a new user tile.
          final currentId = item.toolId ?? _legacyToolIdForKind(item.kind);
          if (currentId != null) {
            await widget.layout.hideDefaultTool(currentId);
          }
          await widget.layout.addTool(
            picked,
            anchor: currentIndex == null
                ? null
                : DashboardAnchor(index: currentIndex),
          );
        } else {
          await widget.layout.replaceItem(item.id, picked);
        }
        if (!context.mounted) {
          return;
        }
        UnitanaToast.showSuccess(
          context,
          'Tile replaced with ${picked.title}.',
        );
        return;
      case _TileEditAction.remove:
        final ok = await _confirmRemoveTile(context, _titleForItem(item));
        if (!ok) {
          return;
        }
        if (!context.mounted) {
          return;
        }
        if (_isDefaultToolTile(item)) {
          final toolId = item.toolId ?? _legacyToolIdForKind(item.kind);
          if (toolId != null) {
            await widget.layout.hideDefaultTool(toolId);
          }
        } else {
          await widget.layout.removeItem(item.id);
        }
        if (!context.mounted) {
          return;
        }
        UnitanaToast.showSuccess(context, 'Tile removed from dashboard.');
        return;
    }
  }

  String _titleForItem(DashboardBoardItem item) {
    switch (item.kind) {
      case DashboardItemKind.placesHero:
        return 'Hero';
      case DashboardItemKind.tool:
        final tool = item.toolId == null
            ? null
            : ToolDefinitions.byId(item.toolId!);
        return tool?.title ?? 'Tool';
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ToolPickerSheet(session: widget.session),
      ),
    );
    if (picked == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (_dashboardHasToolId(picked.id)) {
      UnitanaToast.showError(
        context,
        '${picked.title} is already on your dashboard.',
        key: ValueKey('toast_duplicate_tool_${picked.id}'),
      );
      unawaited(_focusExistingToolTile(picked.id));
      return;
    }

    final isDefault = ToolDefinitions.defaultTiles.any(
      (t) => t.id == picked.id,
    );

    if (isDefault && widget.layout.isDefaultToolHidden(picked.id)) {
      if (anchor != null) {
        await widget.layout.setDefaultToolAnchorIndex(picked.id, anchor.index);
      }
      await widget.layout.unhideDefaultTool(picked.id);
      if (!context.mounted) {
        return;
      }
      _showTransientBanner(
        'Restored ${picked.title} on dashboard',
        bannerKey: 'dashboard_restore_tool_${picked.id}',
      );
      return;
    }

    await widget.layout.addTool(picked, anchor: anchor);

    if (!context.mounted) {
      return;
    }
    _showTransientBanner(
      'Added ${picked.title} to dashboard',
      bannerKey: 'dashboard_add_tool_${picked.id}',
    );
  }

  (String, String) _pickToolLabels({
    required ToolDefinition tool,
    required ConversionRecord? latest,
    required Place? activePlace,
  }) {
    final matrixSelection = _matrixSelectionForTool(tool.id);
    if (matrixSelection != null) {
      return (matrixSelection.primaryLabel, matrixSelection.secondaryLabel);
    }

    // Default to tool defaults, then prefer the most recent run.
    var a = latest?.inputLabel ?? tool.defaultPrimary;
    var b = latest?.outputLabel ?? tool.defaultSecondary;

    // Currency is place-aware and should follow the selected
    // reality (Home vs Destination), not the unit-system heuristic.
    if (tool.id == 'currency_convert') {
      final code = currencyCodeForCountryCode(activePlace?.countryCode);
      final symbol = kCurrencySymbols[code] ?? code;
      if (!a.contains(symbol) && b.contains(symbol)) {
        return (b, a);
      }
    }

    // Time tiles should follow the active place's 12/24-hour preference.
    // The Places Hero reflects Place.use24h, so the Time tile preview should
    // mirror that behavior when showing 12h vs 24h sample labels.
    if (tool.id == 'time' && activePlace != null) {
      bool is12h(String v) =>
          RegExp(r'\b(am|pm)\b', caseSensitive: false).hasMatch(v);
      final wants24h = activePlace.use24h;
      final aIs12h = is12h(a);
      final bIs12h = is12h(b);

      if (wants24h) {
        // Prefer the label without AM/PM as primary when available.
        if (aIs12h && !bIs12h) return (b, a);
      } else {
        // Prefer the label with AM/PM as primary when available.
        if (!aIs12h && bIs12h) return (b, a);
      }
    }

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

  MatrixWidgetSelection? _matrixSelectionForTool(String toolId) {
    switch (toolId) {
      case 'shoe_sizes':
      case 'paper_sizes':
      case 'mattress_sizes':
        return widget.session.matrixWidgetSelectionFor(toolId);
      default:
        return null;
    }
  }

  (String, String) _weatherSummaryLabels({required Place? activePlace}) {
    if (activePlace == null) {
      return ('—', 'Set a place');
    }

    final snap = widget.liveData.weatherFor(activePlace);
    if (snap == null) {
      return ('—', 'No weather data');
    }

    final preferMetric = (activePlace.unitSystem == 'metric');
    final c = snap.temperatureC;
    final f = (c * 9 / 5) + 32;
    final primary = preferMetric ? '${c.round()}°C' : '${f.round()}°F';
    final secondary = (snap.conditionText).trim().isEmpty
        ? '—'
        : (snap.conditionText).trim();
    return (primary, secondary);
  }

  bool _isMetricLabel(String toolId, String label) {
    final l = label.toLowerCase();
    return switch (toolId) {
      'height' => l.contains('cm'),
      // Length uses the same canonical engine as Height but is its own tool.
      'length' =>
        l.contains('cm') || l.contains('mm') || RegExp(r'\bm\b').hasMatch(l),
      'baking' => l.contains('ml'),
      'liquids' => l.contains('ml'),
      'area' => l.contains('m²') || l.contains('m2'),
      'volume' => RegExp(r'\bml\b|\bl\b').hasMatch(l),
      'pressure' => RegExp(r'\bkpa\b|\bhpa\b|\bbar\b|\bpa\b').hasMatch(l),
      'weight' => RegExp(r'\bkg\b|\bg\b').hasMatch(l),
      'body_weight' => RegExp(r'\bkg\b|\bg\b').hasMatch(l),
      'distance' => l.contains('km') || RegExp(r'\bm\b').hasMatch(l),
      'speed' => l.contains('km'),
      'temperature' => l.contains('°c') || RegExp(r'\bc\b').hasMatch(l),
      _ => false,
    };
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

class _DashboardWorldTimeMiniMap extends StatelessWidget {
  final double fromOffsetHours;
  final double toOffsetHours;
  final String fromCity;
  final String toCity;

  const _DashboardWorldTimeMiniMap({
    required this.fromOffsetHours,
    required this.toOffsetHours,
    required this.fromCity,
    required this.toCity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bands = List<int>.generate(27, (index) => index - 12);
    int nearestBand(double offset) {
      var best = bands.first;
      var bestDiff = (bands.first - offset).abs();
      for (final band in bands.skip(1)) {
        final diff = (band - offset).abs();
        if (diff < bestDiff) {
          best = band;
          bestDiff = diff;
        }
      }
      return best;
    }

    final fromBand = nearestBand(fromOffsetHours);
    final toBand = nearestBand(toOffsetHours);

    Color bandColor(int band) {
      final isFrom = band == fromBand;
      final isTo = band == toBand;
      if (isFrom && isTo) {
        return Color.lerp(scheme.tertiary, scheme.primary, 0.5)!.withAlpha(155);
      }
      if (isFrom) return scheme.tertiary.withAlpha(145);
      if (isTo) return scheme.primary.withAlpha(145);
      return scheme.surfaceContainerHighest.withAlpha(86);
    }

    String offsetLabel(double hours) {
      final rounded = hours.roundToDouble();
      final sign = hours >= 0 ? '+' : '';
      if ((hours - rounded).abs() < 0.01) {
        return 'UTC$sign${rounded.toInt()}';
      }
      return 'UTC$sign${hours.toStringAsFixed(1)}';
    }

    Widget legend({
      required String city,
      required double offset,
      required Color tone,
      required TextAlign align,
    }) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          '$city ${offsetLabel(offset)}',
          textAlign: align,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone.withAlpha(235),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    String compactHours(double value) {
      final rounded = value.roundToDouble();
      final sign = value >= 0 ? '+' : '';
      if ((value - rounded).abs() < 0.01) {
        return '$sign${rounded.toInt()}';
      }
      return '$sign${value.toStringAsFixed(1)}';
    }

    final deltaLabel = 'Δ ${compactHours(toOffsetHours - fromOffsetHours)}h';
    final summaryLabel =
        '$fromCity ${offsetLabel(fromOffsetHours)} • $toCity ${offsetLabel(toOffsetHours)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 76 || constraints.maxWidth < 170;
        if (compact) {
          final fromX = ((fromBand + 12) / 26).clamp(0.0, 1.0);
          final toX = ((toBand + 12) / 26).clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 0.38,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            scheme.onSurfaceVariant.withAlpha(205),
                            BlendMode.modulate,
                          ),
                          child: Image.asset(
                            'assets/maps/world_outline.png',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0.06, -0.08),
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: _DashboardWorldBackdropPainter(
                          color: scheme.onSurfaceVariant.withAlpha(48),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final band in bands)
                            Expanded(child: ColoredBox(color: bandColor(band))),
                        ],
                      ),
                      Align(
                        alignment: Alignment((fromX * 2) - 1, 0),
                        child: SizedBox(
                          width: 2.4,
                          height: double.infinity,
                          child: ColoredBox(
                            color: scheme.tertiary.withAlpha(235),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment((toX * 2) - 1, 0),
                        child: SizedBox(
                          width: 2.4,
                          height: double.infinity,
                          child: ColoredBox(
                            color: scheme.primary.withAlpha(235),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  deltaLabel,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.45,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          scheme.onSurfaceVariant.withAlpha(205),
                          BlendMode.modulate,
                        ),
                        child: Image.asset(
                          'assets/maps/world_outline.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.06, -0.08),
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: _DashboardWorldBackdropPainter(
                        color: scheme.onSurfaceVariant.withAlpha(56),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final band in bands)
                          Expanded(child: ColoredBox(color: bandColor(band))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                deltaLabel,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                summaryLabel,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: legend(
                    city: fromCity,
                    offset: fromOffsetHours,
                    tone: scheme.tertiary,
                    align: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: legend(
                    city: toCity,
                    offset: toOffsetHours,
                    tone: scheme.primary,
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DashboardWorldBackdropPainter extends CustomPainter {
  final Color color;

  const _DashboardWorldBackdropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    for (var i = 1; i <= 5; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    }
    for (var i = 1; i <= 23; i++) {
      final x = size.width * (i / 24);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardWorldBackdropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DashboardTimeMiniClocks extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final DateTime fromLocal;
  final DateTime toLocal;
  final double fromOffsetHours;
  final double toOffsetHours;
  final bool use24h;

  const _DashboardTimeMiniClocks({
    required this.fromCity,
    required this.toCity,
    required this.fromLocal,
    required this.toLocal,
    required this.fromOffsetHours,
    required this.toOffsetHours,
    required this.use24h,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String two(int value) => value.toString().padLeft(2, '0');

    String formatClock(DateTime dt) {
      if (use24h) {
        return '${two(dt.hour)}:${two(dt.minute)}';
      }
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final suffix = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${two(dt.minute)} $suffix';
    }

    String compactHours(double value) {
      final rounded = value.roundToDouble();
      final sign = value >= 0 ? '+' : '';
      if ((value - rounded).abs() < 0.01) {
        return '$sign${rounded.toInt()}';
      }
      return '$sign${value.toStringAsFixed(1)}';
    }

    final delta = toOffsetHours - fromOffsetHours;
    final deltaLabel = 'Δ ${compactHours(delta)}h';

    Widget clockPill({
      required String city,
      required DateTime local,
      required Color tone,
      required TextAlign align,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tone.withAlpha(130)),
        ),
        child: Column(
          crossAxisAlignment: align == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: align,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone.withAlpha(235),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatClock(local),
              maxLines: 1,
              textAlign: align,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 76 || constraints.maxWidth < 170;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniAnalogClock(
                        local: fromLocal,
                        tone: scheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniAnalogClock(
                        local: toLocal,
                        tone: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  '$fromCity • $toCity',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatClock(fromLocal)} • ${formatClock(toLocal)} • $deltaLabel',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: clockPill(
                    city: fromCity,
                    local: fromLocal,
                    tone: scheme.tertiary,
                    align: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: clockPill(
                    city: toCity,
                    local: toLocal,
                    tone: scheme.primary,
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                deltaLabel,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniAnalogClock extends StatelessWidget {
  final DateTime local;
  final Color tone;

  const _MiniAnalogClock({required this.local, required this.tone});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _MiniAnalogClockPainter(
          local: local,
          tone: tone,
          faceColor: scheme.surfaceContainerHighest.withAlpha(72),
          tickColor: scheme.onSurface.withAlpha(150),
          handColor: scheme.onSurface.withAlpha(228),
        ),
      ),
    );
  }
}

class _MiniAnalogClockPainter extends CustomPainter {
  final DateTime local;
  final Color tone;
  final Color faceColor;
  final Color tickColor;
  final Color handColor;

  const _MiniAnalogClockPainter({
    required this.local,
    required this.tone,
    required this.faceColor,
    required this.tickColor,
    required this.handColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final face = Paint()..color = faceColor;
    final border = Paint()
      ..color = tone.withAlpha(175)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, radius * 0.08);

    canvas.drawCircle(center, radius * 0.98, face);
    canvas.drawCircle(center, radius * 0.98, border);

    final ticks = Paint()
      ..color = tickColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, radius * 0.05);
    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) - (math.pi / 2);
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 0.87,
        center.dy + math.sin(angle) * radius * 0.87,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      canvas.drawLine(inner, outer, ticks);
    }

    final minuteAngle =
        ((local.minute + (local.second / 60)) * math.pi / 30) - (math.pi / 2);
    final hourAngle =
        (((local.hour % 12) + (local.minute / 60)) * math.pi / 6) -
        (math.pi / 2);

    final minuteHand = Paint()
      ..color = handColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, radius * 0.08);
    final hourHand = Paint()
      ..color = handColor.withAlpha(230)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, radius * 0.11);
    final accentHand = Paint()
      ..color = tone.withAlpha(228)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, radius * 0.06);

    final hourEnd = Offset(
      center.dx + math.cos(hourAngle) * radius * 0.45,
      center.dy + math.sin(hourAngle) * radius * 0.45,
    );
    final minuteEnd = Offset(
      center.dx + math.cos(minuteAngle) * radius * 0.65,
      center.dy + math.sin(minuteAngle) * radius * 0.65,
    );
    final accentEnd = Offset(
      center.dx + math.cos(minuteAngle) * radius * 0.72,
      center.dy + math.sin(minuteAngle) * radius * 0.72,
    );

    canvas.drawLine(center, hourEnd, hourHand);
    canvas.drawLine(center, minuteEnd, minuteHand);
    canvas.drawLine(center, accentEnd, accentHand);
    canvas.drawCircle(center, math.max(1.8, radius * 0.08), accentHand);
  }

  @override
  bool shouldRepaint(covariant _MiniAnalogClockPainter oldDelegate) {
    return oldDelegate.local.minute != local.minute ||
        oldDelegate.local.hour != local.hour ||
        oldDelegate.tone != tone ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.handColor != handColor;
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

class ToolPickerSheet extends StatefulWidget {
  final DashboardSessionController? session;

  const ToolPickerSheet({super.key, this.session});

  @override
  State<ToolPickerSheet> createState() => _ToolPickerSheetState();
}

class _ToolPickerSheetState extends State<ToolPickerSheet> {
  String? _expandedLensId;
  String _query = '';
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _lensFocusKeys = <String, GlobalKey>{};

  DashboardSessionController? get _session => widget.session;

  String _localizedToolLabel(BuildContext context, ToolRegistryTool tool) {
    return DashboardCopy.toolDisplayName(
      context,
      toolId: tool.toolId,
      fallback: tool.label,
    );
  }

  String _localizedLensName(BuildContext context, ActivityLens lens) {
    return DashboardCopy.lensName(
      context,
      lensId: lens.id,
      fallback: lens.name,
    );
  }

  String _localizedLensDescriptor(BuildContext context, ActivityLens lens) {
    return DashboardCopy.lensDescriptor(
      context,
      lensId: lens.id,
      fallback: lens.descriptor,
    );
  }

  String _disabledBadgeFor(BuildContext context, ToolRegistryTool tool) {
    switch (tool.surfaceType) {
      case ToolSurfaceType.deferred:
        return DashboardCopy.toolPickerDisabledBadge(context, isDeferred: true);
      case ToolSurfaceType.aliasPreset:
      case ToolSurfaceType.configurableTemplate:
      case ToolSurfaceType.dedicated:
        return DashboardCopy.toolPickerDisabledBadge(
          context,
          isDeferred: false,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _focusKeyForLens(String lensId) {
    return _lensFocusKeys.putIfAbsent(lensId, GlobalKey.new);
  }

  void _focusExpandedLens(String lensId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusKey = _lensFocusKeys[lensId];
      final context = focusKey?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  ToolDefinition? _mapToExistingToolDefinition({
    required ToolRegistryTool tool,
    required String lensId,
  }) {
    // Prefer exact tool-id matches (velocity path).
    final direct = ToolDefinitions.byId(tool.toolId);
    if (direct != null) return direct;

    // Currency is enabled in the registry but is a newer ToolDefinition.
    if (tool.toolId == 'currency_convert') {
      return ToolDefinitions.currencyConvert;
    }

    // Backward compatibility for older registry/tool ids.
    if (tool.toolId == 'liquid_volume') {
      return lensId == ActivityLensId.foodCooking
          ? ToolDefinitions.baking
          : ToolDefinitions.liquids;
    }

    // Activation bundle (Pack F): these remain distinct discovery entries,
    // but route into Time-family surfaces.
    if (tool.toolId == 'world_clock_delta') {
      return ToolDefinitions.time;
    }

    if (tool.toolId == 'jet_lag_delta') {
      return ToolDefinitions.jetLagDelta;
    }

    if (tool.toolId == 'timezone_lookup') {
      return ToolDefinitions.timeZoneConverter;
    }

    return null;
  }

  bool _matchesQuery(ToolRegistryTool tool) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final fallback = tool.label.toLowerCase();
    final localized = DashboardCopy.toolDisplayName(
      context,
      toolId: tool.toolId,
      fallback: tool.label,
    ).toLowerCase();
    final localizedAliases = DashboardCopy.toolSearchAliases(
      context,
      toolId: tool.toolId,
    );
    final tokenMatch = tool.searchTokens.any(
      (token) => token.toLowerCase().contains(q),
    );
    final localizedTokenMatch = localizedAliases.any(
      (token) => token.toLowerCase().contains(q),
    );
    return fallback.contains(q) ||
        localized.contains(q) ||
        tokenMatch ||
        localizedTokenMatch;
  }

  List<ToolRegistryTool> _searchResults() {
    final q = _query.trim();
    if (q.isEmpty) return const <ToolRegistryTool>[];

    final matches = ToolRegistry.all.where(_matchesQuery).toList();
    // Keep results deterministic and readable.
    matches.sort((a, b) {
      final aLabel = _localizedToolLabel(context, a);
      final bLabel = _localizedToolLabel(context, b);
      return aLabel.compareTo(bLabel);
    });
    return matches;
  }

  Widget _searchResultsSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final results = _searchResults();
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          DashboardCopy.toolPickerNoMatchingTools(context),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    const maxResults = 12;
    final visible = results.take(maxResults).toList(growable: false);
    final remaining = results.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(context, DashboardCopy.toolPickerResultsHeader(context)),
        for (final t in visible)
          ListTile(
            key: Key('toolpicker_search_tool_${t.toolId}'),
            enabled: t.isEnabled,
            leading: Icon(
              t.icon,
              color: LensAccents.toolIconTintForBrightness(
                toolId: t.toolId,
                lensId: t.lenses.isEmpty
                    ? ActivityLensId.travelEssentials
                    : t.lenses.first,
                brightness: theme.brightness,
              ),
            ),
            title: Text(_localizedToolLabel(context, t)),
            subtitle: () {
              final lensName = t.lenses.isEmpty
                  ? null
                  : () {
                      final lens = ActivityLenses.byId(t.lenses.first);
                      if (lens == null) return '';
                      return _localizedLensName(context, lens);
                    }();
              final deferReason = t.deferReason?.trim();
              if (deferReason != null && deferReason.isNotEmpty) {
                final prefix = (lensName == null || lensName.isEmpty)
                    ? ''
                    : '$lensName • ';
                return Text(
                  '$prefix$deferReason',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                );
              }
              if (lensName == null || lensName.isEmpty) return null;
              return Text(
                lensName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              );
            }(),
            trailing: t.isEnabled
                ? const Icon(Icons.chevron_right_rounded)
                : Text(
                    _disabledBadgeFor(context, t),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
            onTap: !t.isEnabled
                ? null
                : () {
                    final lensId = t.lenses.isEmpty ? '' : t.lenses.first;
                    final mapped = _mapToExistingToolDefinition(
                      tool: t,
                      lensId: lensId,
                    );
                    if (mapped == null) {
                      return;
                    }
                    Navigator.of(context).pop(mapped);
                  },
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              DashboardCopy.toolPickerMoreCount(context, remaining),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  List<Widget> _buildToolRows(
    BuildContext context, {
    required String lensId,
    required List<ToolRegistryTool> tools,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = tools.where(_matchesQuery).toList(growable: false);
    if (visible.isEmpty) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Text(
            _query.trim().isEmpty
                ? DashboardCopy.toolPickerNoToolsYet(context)
                : DashboardCopy.toolPickerNoMatchingTools(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      for (final t in visible)
        ListTile(
          key: Key('toolpicker_tool_${t.toolId}'),
          enabled: t.isEnabled,
          leading: Icon(
            t.icon,
            color: LensAccents.toolIconTintForBrightness(
              toolId: t.toolId,
              lensId: lensId,
              brightness: theme.brightness,
            ),
          ),
          title: Text(_localizedToolLabel(context, t)),
          subtitle: t.deferReason == null
              ? null
              : Text(
                  t.deferReason!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
          trailing: t.isEnabled
              ? const Icon(Icons.chevron_right_rounded)
              : Text(
                  _disabledBadgeFor(context, t),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
          onTap: !t.isEnabled
              ? null
              : () {
                  final mapped = _mapToExistingToolDefinition(
                    tool: t,
                    lensId: lensId,
                  );
                  if (mapped == null) {
                    return;
                  }
                  Navigator.of(context).pop(mapped);
                },
        ),
    ];
  }

  Widget _lensHeader(BuildContext context, ActivityLens lens) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expanded = _expandedLensId == lens.id;

    return Container(
      key: _focusKeyForLens(lens.id),
      child: ListTile(
        key: ValueKey('toolpicker_lens_${lens.id}'),
        leading: Icon(
          lens.icon,
          color: LensAccents.iconTintForBrightness(lens.id, theme.brightness),
        ),
        title: Text(_localizedLensName(context, lens)),
        subtitle: Text(_localizedLensDescriptor(context, lens)),
        trailing: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onTap: () {
          final nextExpanded = expanded ? null : lens.id;
          setState(() {
            _expandedLensId = nextExpanded;
          });
          if (nextExpanded != null) {
            _focusExpandedLens(nextExpanded);
          }
        },
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: theme.textTheme.titleMedium,
        subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _recentShortcut(BuildContext context) {
    final ids = _session?.recentToolIds(max: 1) ?? const <String>[];
    if (ids.isEmpty) return const SizedBox.shrink();

    final tool = ToolRegistry.byId[ids.first];
    if (tool == null || !tool.isEnabled) return const SizedBox.shrink();

    // Recents are global entry points; prefer direct toolId mapping.
    final mapped = _mapToExistingToolDefinition(tool: tool, lensId: '');
    if (mapped == null) return const SizedBox.shrink();

    return ListTile(
      key: const ValueKey('toolpicker_recent'),
      leading: const Icon(Icons.history_rounded),
      title: Text(DashboardCopy.toolPickerMostRecent(context)),
      subtitle: Text(_localizedToolLabel(context, tool)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).pop(mapped),
    );
  }

  Widget _searchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        key: const ValueKey('toolpicker_search'),
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: DashboardCopy.toolPickerSearchHint(context),
          isDense: true,
        ),
        onChanged: (v) {
          setState(() {
            _query = v;

            // If the user starts searching with everything collapsed, expand the
            // first lens that has a match so the hierarchy also responds.
            if (_expandedLensId == null && _query.trim().isNotEmpty) {
              for (final lens in ActivityLenses.all) {
                final tools = ToolRegistry.toolsForLens(lens.id);
                if (tools.any(_matchesQuery)) {
                  _expandedLensId = lens.id;
                  _focusExpandedLens(lens.id);
                  break;
                }
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DashboardCopy.toolPickerTitle(context),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('toolpicker_close'),
                  tooltip: DashboardCopy.toolPickerCloseTooltip(context),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          _recentShortcut(context),
          _searchField(context),
          if (_query.trim().isNotEmpty) _searchResultsSection(context),
          for (final lens in ActivityLenses.all) ...[
            _lensHeader(context, lens),
            if (_expandedLensId == lens.id)
              ..._buildToolRows(
                context,
                lensId: lens.id,
                tools: ToolRegistry.toolsForLens(lens.id),
              ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EditIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _EditIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface.withAlpha(220);

    final button = SizedBox(
      width: 32,
      height: 32,
      child: Center(child: Icon(icon, size: 18, color: fg)),
    );

    if (onTap == null) {
      return MouseRegion(cursor: SystemMouseCursors.grab, child: button);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: button,
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
