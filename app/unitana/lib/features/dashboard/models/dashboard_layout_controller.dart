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

  final List<DashboardBoardItem> _items = <DashboardBoardItem>[];
  final List<DashboardBoardItem> _draftBaseline = <DashboardBoardItem>[];
  bool _isEditing = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  bool get isEditing => _isEditing;

  List<DashboardBoardItem> get items =>
      List<DashboardBoardItem>.unmodifiable(_items);

  /// Starts an edit session.
  ///
  /// During an edit session, tile mutations do not persist until [commitEdit]
  /// is called. [cancelEdit] rolls back to the baseline snapshot.
  void beginEdit() {
    if (_isEditing) return;
    _draftBaseline
      ..clear()
      ..addAll(_items);
    _isEditing = true;
    notifyListeners();
  }

  void cancelEdit() {
    if (!_isEditing) return;
    _items
      ..clear()
      ..addAll(_draftBaseline);
    _draftBaseline.clear();
    _isEditing = false;
    notifyListeners();
  }

  Future<void> commitEdit() async {
    if (!_isEditing) return;
    _draftBaseline.clear();
    _isEditing = false;
    notifyListeners();
    await _persist();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    _items.clear();
    _draftBaseline.clear();
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

    _loaded = true;
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _draftBaseline.clear();
    _isEditing = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
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
