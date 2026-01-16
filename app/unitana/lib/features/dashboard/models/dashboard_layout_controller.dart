import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_board_item.dart';
import 'tool_definitions.dart';

/// Persists user-added dashboard tiles.
///
/// Current capabilities:
/// - Filling a "+" slot inserts a new tile and saves it.
/// - Long-press actions on user-added tiles can Replace or Remove.
/// - The board remains dense-packed; reorder and resize come later.
class DashboardLayoutController extends ChangeNotifier {
  static const String _prefsKey = 'dashboard_layout_v1';

  // Persisted anchor overrides for default tool tiles.
  //
  // Default tiles are normally ordered by ToolDefinitions.defaultTiles. When a
  // user drags a default tile in edit mode, we store a slot anchor index so the
  // new position remains stable across launches.
  static const String _prefsDefaultToolAnchorsKey =
      'dashboard_default_tool_anchors_v1';

  // Tracks which default tiles (ToolDefinitions.defaultTiles) the user has
  // removed from the dashboard.
  //
  // Stored separately from [_prefsKey] to avoid churn/migrations of the main
  // layout schema.
  //
  // Canonical key (used by tests and current slices):
  static const String _prefsHiddenDefaultsKey = 'dashboard_hidden_defaults_v1';

  // Legacy key used by an earlier hotfix; we keep reading/writing it for
  // backwards compatibility so existing users don't lose state.
  static const String _prefsHiddenDefaultsLegacyKey =
      'dashboard_hidden_default_tools_v1';

  // Older tests/builds used this key name; we remove it during resets to avoid
  // stale hidden-default state.
  static const String _prefsHiddenDefaultsAltLegacyKey = 'hidden_defaults_v1';

  final List<DashboardBoardItem> _items = <DashboardBoardItem>[];
  final List<DashboardBoardItem> _draftBaseline = <DashboardBoardItem>[];

  final Map<String, int> _defaultToolAnchors = <String, int>{};
  final Map<String, int> _draftDefaultToolAnchorsBaseline = <String, int>{};

  final Set<String> _hiddenDefaultToolIds = <String>{};
  final Set<String> _draftHiddenDefaultBaseline = <String>{};
  bool _isEditing = false;
  bool _loaded = false;

  // Monotonic token used to invalidate in-flight async work (notably [load])
  // when destructive operations like [clear] run.
  int _epoch = 0;

  bool get isLoaded => _loaded;

  bool get isEditing => _isEditing;

  List<DashboardBoardItem> get items =>
      List<DashboardBoardItem>.unmodifiable(_items);

  bool isDefaultToolHidden(String toolId) =>
      _hiddenDefaultToolIds.contains(toolId);

  int? defaultToolAnchorIndex(String toolId) => _defaultToolAnchors[toolId];

  Future<void> setDefaultToolAnchorIndex(String toolId, int? index) async {
    final trimmed = toolId.trim();
    if (trimmed.isEmpty) return;
    if (index == null) {
      if (_defaultToolAnchors.remove(trimmed) == null) return;
      notifyListeners();
      if (!_isEditing) await _persist();
      return;
    }
    if (_defaultToolAnchors[trimmed] == index) return;
    _defaultToolAnchors[trimmed] = index;
    notifyListeners();
    if (!_isEditing) await _persist();
  }

  Future<void> setUserItemAnchorIndex(String itemId, int? index) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final existing = _items[idx];
    final nextAnchor = index == null ? null : DashboardAnchor(index: index);
    if (existing.anchor?.index == nextAnchor?.index) return;
    _items[idx] = DashboardBoardItem(
      id: existing.id,
      kind: existing.kind,
      span: existing.span,
      toolId: existing.toolId,
      anchor: nextAnchor,
      userAdded: existing.userAdded,
    );
    notifyListeners();
    if (!_isEditing) await _persist();
  }

  int? userItemAnchorIndex(String itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return null;
    return _items[idx].anchor?.index;
  }

  /// Starts an edit session.
  ///
  /// During an edit session, tile mutations do not persist until [commitEdit]
  /// is called. [cancelEdit] rolls back to the baseline snapshot.
  void beginEdit() {
    if (_isEditing) return;
    _draftBaseline
      ..clear()
      ..addAll(_items);
    _draftDefaultToolAnchorsBaseline
      ..clear()
      ..addAll(_defaultToolAnchors);
    _draftHiddenDefaultBaseline
      ..clear()
      ..addAll(_hiddenDefaultToolIds);
    _isEditing = true;
    notifyListeners();
  }

  void cancelEdit() {
    if (!_isEditing) return;
    _items
      ..clear()
      ..addAll(_draftBaseline);
    _draftBaseline.clear();

    _defaultToolAnchors
      ..clear()
      ..addAll(_draftDefaultToolAnchorsBaseline);
    _draftDefaultToolAnchorsBaseline.clear();

    _hiddenDefaultToolIds
      ..clear()
      ..addAll(_draftHiddenDefaultBaseline);
    _draftHiddenDefaultBaseline.clear();

    _isEditing = false;
    notifyListeners();
  }

  Future<void> commitEdit() async {
    if (!_isEditing) return;
    _draftBaseline.clear();
    _draftDefaultToolAnchorsBaseline.clear();
    _draftHiddenDefaultBaseline.clear();
    _isEditing = false;
    notifyListeners();
    await _persist();
  }

  Future<void> load() async {
    final epochAtStart = _epoch;
    final prefs = await SharedPreferences.getInstance();

    // If the controller was cleared while we were awaiting prefs, abort.
    if (epochAtStart != _epoch) return;
    final raw = prefs.getString(_prefsKey);

    final defaultAnchorsRaw = prefs.getString(_prefsDefaultToolAnchorsKey);

    // Hidden defaults: canonical is a JSON string list, but older builds may have stored a StringList.
    final hiddenValue =
        prefs.get(_prefsHiddenDefaultsKey) ??
        prefs.get(_prefsHiddenDefaultsLegacyKey);

    String? hiddenRaw;
    List<String>? hiddenList;

    if (hiddenValue is String) {
      hiddenRaw = hiddenValue;
    } else if (hiddenValue is List) {
      hiddenList = hiddenValue.whereType<String>().toList();
    }

    // If a destructive operation ran since we started, drop the load.
    if (epochAtStart != _epoch) return;

    _items.clear();
    _draftBaseline.clear();
    _defaultToolAnchors.clear();
    _draftDefaultToolAnchorsBaseline.clear();
    _hiddenDefaultToolIds.clear();
    _draftHiddenDefaultBaseline.clear();
    _isEditing = false;

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded) {
            final item = _fromJson(entry);
            if (item != null) _items.add(item);
          }
        }
      } catch (_) {
        // Ignore corrupt prefs; fall back to defaults.
      }
    }

    final hiddenSet = <String>{};

    if (hiddenList != null) {
      for (final entry in hiddenList) {
        if (entry.trim().isNotEmpty) hiddenSet.add(entry);
      }
    } else if (hiddenRaw != null && hiddenRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(hiddenRaw);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is String && entry.trim().isNotEmpty) {
              hiddenSet.add(entry);
            }
          }
        }
      } catch (_) {
        // Ignore corrupt prefs.
      }
    }

    _hiddenDefaultToolIds.addAll(hiddenSet);

    if (defaultAnchorsRaw != null && defaultAnchorsRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(defaultAnchorsRaw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key;
            final val = entry.value;
            if (key is String && val is int) {
              final trimmed = key.trim();
              if (trimmed.isNotEmpty) _defaultToolAnchors[trimmed] = val;
            }
          }
        }
      } catch (_) {
        // Ignore corrupt prefs.
      }
    }

    // Migrate legacy StringList to the canonical JSON string format.
    if (hiddenList != null) {
      await _storeHiddenDefaults(prefs, _hiddenDefaultToolIds);
    }

    _loaded = true;
    notifyListeners();
  }

  /// Persists the "hidden default tiles" set in the canonical JSON-string format.
  ///
  /// We also mirror to legacy keys for backwards compatibility.
  Future<void> _storeHiddenDefaults(
    SharedPreferences prefs,
    Set<String> hiddenToolIds,
  ) async {
    // Ensure we can safely change stored types (e.g., StringList -> String).
    await prefs.remove(_prefsHiddenDefaultsKey);
    await prefs.remove(_prefsHiddenDefaultsLegacyKey);
    await prefs.remove(_prefsHiddenDefaultsAltLegacyKey);

    if (hiddenToolIds.isEmpty) return;

    final payload = jsonEncode(hiddenToolIds.toList(growable: false)..sort());
    await prefs.setString(_prefsHiddenDefaultsKey, payload);
    await prefs.setString(_prefsHiddenDefaultsLegacyKey, payload);
    await prefs.setString(_prefsHiddenDefaultsAltLegacyKey, payload);
  }

  Future<void> clear() async {
    // Invalidate any in-flight load.
    _epoch++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    // Clear default tool anchors.
    await prefs.remove(_prefsDefaultToolAnchorsKey);

    // Clear hidden-default state across all known keys (canonical + legacy).
    await prefs.remove(_prefsHiddenDefaultsKey);
    await prefs.remove(_prefsHiddenDefaultsLegacyKey);
    await prefs.remove(_prefsHiddenDefaultsAltLegacyKey);

    // Defensive: if any older build wrote a slightly different legacy key,
    // remove it too (no harm if absent).
    await prefs.remove('dashboard_hidden_default_tools_v1');

    _items.clear();
    _draftBaseline.clear();
    _defaultToolAnchors.clear();
    _draftDefaultToolAnchorsBaseline.clear();
    _hiddenDefaultToolIds.clear();
    _draftHiddenDefaultBaseline.clear();
    _isEditing = false;
    notifyListeners();
  }

  /// Restores the dashboard to the current default configuration.
  ///
  /// This:
  /// - Removes all user-added tiles and any layout edits.
  /// - Clears the "hidden default tiles" state so removed defaults return.
  ///
  /// Default tiles are derived from [ToolDefinitions.defaultTiles], so the
  /// resulting dashboard can evolve over time as defaults change.
  Future<void> resetDashboardDefaults() async {
    await clear();
  }

  Future<void> hideDefaultTool(String toolId) async {
    if (_hiddenDefaultToolIds.add(toolId)) {
      notifyListeners();
      if (!_isEditing) await _persist();
    }
  }

  Future<void> unhideDefaultTool(String toolId) async {
    if (_hiddenDefaultToolIds.remove(toolId)) {
      notifyListeners();
      if (!_isEditing) await _persist();
    }
  }

  Future<void> addTool(ToolDefinition tool, {DashboardAnchor? anchor}) async {
    // Keep ids unique and stable across sessions.
    final id = '${tool.id}_${DateTime.now().millisecondsSinceEpoch}';

    _items.add(
      DashboardBoardItem(
        id: id,
        kind: DashboardItemKind.tool,
        span: DashboardTileSpan.oneByOne,
        toolId: tool.id,
        anchor: anchor,
        userAdded: true,
      ),
    );

    notifyListeners();
    if (!_isEditing) await _persist();
  }

  Future<void> replaceItem(String itemId, ToolDefinition tool) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;

    final existing = _items[idx];
    _items[idx] = DashboardBoardItem(
      id: existing.id,
      kind: DashboardItemKind.tool,
      span: existing.span,
      toolId: tool.id,
      anchor: existing.anchor,
      userAdded: true,
    );

    notifyListeners();
    if (!_isEditing) await _persist();
  }

  Future<void> removeItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
    if (!_isEditing) await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_items.map(_toJson).toList(growable: false));
    await prefs.setString(_prefsKey, payload);

    // Persist default tool anchor overrides.
    if (_defaultToolAnchors.isEmpty) {
      await prefs.remove(_prefsDefaultToolAnchorsKey);
    } else {
      final anchorsPayload = jsonEncode(_defaultToolAnchors);
      await prefs.setString(_prefsDefaultToolAnchorsKey, anchorsPayload);
    }

    // Persist hidden-default state only when non-empty. If empty, remove the
    // keys so Reset Dashboard Defaults can truly clear the state.
    if (_hiddenDefaultToolIds.isEmpty) {
      await prefs.remove(_prefsHiddenDefaultsKey);
      await prefs.remove(_prefsHiddenDefaultsLegacyKey);
      await prefs.remove(_prefsHiddenDefaultsAltLegacyKey);
    } else {
      final hiddenPayload = jsonEncode(
        _hiddenDefaultToolIds.toList(growable: false)..sort(),
      );
      // Write canonical + legacy keys for compatibility.
      await prefs.setString(_prefsHiddenDefaultsKey, hiddenPayload);
      await prefs.setString(_prefsHiddenDefaultsLegacyKey, hiddenPayload);
      await prefs.setString(_prefsHiddenDefaultsAltLegacyKey, hiddenPayload);
    }
  }

  String? _toolIdForLegacyKind(DashboardItemKind kind) {
    switch (kind) {
      case DashboardItemKind.toolHeight:
        return 'height';
      case DashboardItemKind.toolBaking:
        return 'baking';
      case DashboardItemKind.toolLiquids:
        return 'liquids';
      case DashboardItemKind.toolArea:
        return 'area';
      default:
        return null;
    }
  }

  Map<String, dynamic> _toJson(DashboardBoardItem item) {
    return <String, dynamic>{
      'id': item.id,
      'kind': item.kind.name,
      'toolId': item.toolId,
      'colSpan': item.span.colSpan,
      'rowSpan': item.span.rowSpan,
      'anchorIndex': item.anchor?.index,
      'userAdded': item.userAdded,
    };
  }

  DashboardBoardItem? _fromJson(Object? entry) {
    if (entry is! Map) return null;

    final id = entry['id'];
    final kindRaw = entry['kind'];
    final colSpan = entry['colSpan'];
    final rowSpan = entry['rowSpan'];

    if (id is! String) return null;
    if (kindRaw is! String) return null;
    if (colSpan is! int) return null;
    if (rowSpan is! int) return null;

    final decodedKind = DashboardItemKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () => DashboardItemKind.toolHeight,
    );

    // Prefer explicit tool id (new schema). Fall back to legacy kind mapping.
    final toolIdRaw = entry['toolId'];
    final toolId = toolIdRaw is String
        ? toolIdRaw
        : _toolIdForLegacyKind(decodedKind);

    // Normalize tool tiles to the generic kind going forward.
    final kind = toolId != null ? DashboardItemKind.tool : decodedKind;

    final anchorIndex = entry['anchorIndex'];

    // Migration: historical payloads never stored this. Everything persisted in
    // this controller is user-added by definition, so default to true.
    final ua = entry['userAdded'];
    final userAdded = ua is bool ? ua : true;

    return DashboardBoardItem(
      id: id,
      kind: kind,
      span: DashboardTileSpan(colSpan: colSpan, rowSpan: rowSpan),
      toolId: toolId,
      anchor: anchorIndex is int ? DashboardAnchor(index: anchorIndex) : null,
      userAdded: userAdded,
    );
  }
}
