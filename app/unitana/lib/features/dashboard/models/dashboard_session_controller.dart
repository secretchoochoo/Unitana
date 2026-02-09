import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session-scoped details pill mode.
///
/// Shared between the main Places Hero and the pinned overlay.
enum HeroDetailsPillMode { sun, wind }

/// Session-scoped env pill mode (Hero left rail).
enum HeroEnvPillMode { aqi, pollen }

/// Backwards-compatible enum name for pinned overlay callers.
enum PinnedHeroDetailsMode { sun, wind }

/// Session-scoped right pill mode for the pinned mini-hero overlay.
///
/// Independent from the main hero to keep semantics clear while scrolling.
enum PinnedHeroRightMode { timeTemp, currency }

enum DashboardReality { destination, home }

@immutable
class ConversionRecord {
  final String toolId;

  /// Optional activity lens tag for display/presets.
  ///
  /// History ownership remains canonical by [toolId].
  final String? lensId;
  final String? fromUnit;
  final String? toUnit;
  final String inputLabel;
  final String outputLabel;
  final DateTime timestamp;

  const ConversionRecord({
    required this.toolId,
    this.lensId,
    this.fromUnit,
    this.toUnit,
    required this.inputLabel,
    required this.outputLabel,
    required this.timestamp,
  });
}

@immutable
class MatrixWidgetSelection {
  final String rowKey;
  final String system;
  final String value;
  final String referenceLabel;
  final String primaryLabel;
  final String secondaryLabel;

  const MatrixWidgetSelection({
    required this.rowKey,
    required this.system,
    required this.value,
    required this.referenceLabel,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'rowKey': rowKey,
    'system': system,
    'value': value,
    'referenceLabel': referenceLabel,
    'primaryLabel': primaryLabel,
    'secondaryLabel': secondaryLabel,
  };

  static MatrixWidgetSelection? fromJson(Object? raw) {
    final map = raw is Map ? raw : null;
    if (map == null) return null;
    final rowKey = map['rowKey']?.toString().trim() ?? '';
    final system = map['system']?.toString().trim() ?? '';
    final value = map['value']?.toString().trim() ?? '';
    final referenceLabel = map['referenceLabel']?.toString().trim() ?? '';
    final primaryLabel = map['primaryLabel']?.toString().trim() ?? '';
    final secondaryLabel = map['secondaryLabel']?.toString().trim() ?? '';
    if (rowKey.isEmpty ||
        system.isEmpty ||
        value.isEmpty ||
        primaryLabel.isEmpty ||
        secondaryLabel.isEmpty) {
      return null;
    }
    return MatrixWidgetSelection(
      rowKey: rowKey,
      system: system,
      value: value,
      referenceLabel: referenceLabel,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
    );
  }
}

/// Session-scoped state for the dashboard page.
///
/// - selected reality: drives hero + tools
/// - per-tool conversion history (last 10)
class DashboardSessionController extends ChangeNotifier {
  final String prefsNamespace;

  DashboardSessionController({this.prefsNamespace = ''});

  static const String _kHeroEnvMode = 'hero_env_mode_v1';
  static const String _kMatrixWidgetSelectionByTool =
      'matrix_widget_selection_by_tool_v1';

  String _k(String base) =>
      prefsNamespace.trim().isEmpty ? base : '$base::${prefsNamespace.trim()}';
  bool _envModeLoaded = false;
  // Places hero details pill mode.
  //
  // Session-scoped only: not persisted, so tests remain hermetic.
  // Default to sunrise/sunset so the first render matches the Hero V2 contract
  // used by regression tests.
  HeroDetailsPillMode _heroDetailsPillMode = HeroDetailsPillMode.sun;

  // Pinned hero (compact overlay) details mode.
  //
  // Session-scoped only and intentionally independent from the main hero.
  // The main hero defaults to sunrise/sunset for first-glance context; the
  // pinned overlay defaults to wind/gust for quick “is it miserable outside?”
  // checking while scrolling.
  PinnedHeroDetailsMode _pinnedHeroDetailsMode = PinnedHeroDetailsMode.wind;

  // Pinned hero (compact overlay) right pill mode.
  //
  // Session-scoped only: defaults to Time/Temp for quick glance.
  PinnedHeroRightMode _pinnedHeroRightMode = PinnedHeroRightMode.timeTemp;

  // Places hero env pill mode (AQI / Pollen).
  //
  // Session-scoped only: not persisted. Defaults to AQI as a neutral baseline.
  HeroEnvPillMode _heroEnvPillMode = HeroEnvPillMode.aqi;
  Map<String, MatrixWidgetSelection> _matrixWidgetSelectionByTool =
      const <String, MatrixWidgetSelection>{};

  /// Best-effort load of persisted env pill mode.
  ///
  /// - Defaults remain deterministic until this method is called.
  /// - Tests remain hermetic unless they explicitly call this (or set prefs).
  Future<void> loadPersisted() async {
    if (_envModeLoaded) return;
    _envModeLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_k(_kHeroEnvMode)) ?? prefs.getString(_kHeroEnvMode);
    final next = (raw == null || raw.trim().isEmpty)
        ? _heroEnvPillMode
        : (raw.trim().toLowerCase() == 'pollen'
              ? HeroEnvPillMode.pollen
              : HeroEnvPillMode.aqi);
    final matrixRaw =
        prefs.getString(_k(_kMatrixWidgetSelectionByTool)) ??
        prefs.getString(_kMatrixWidgetSelectionByTool);
    final loadedMatrix = _decodeMatrixWidgetSelections(matrixRaw);
    final matrixChanged = !_mapsEqual(
      _matrixWidgetSelectionByTool,
      loadedMatrix,
    );
    final envChanged = next != _heroEnvPillMode;
    _heroEnvPillMode = next;
    _matrixWidgetSelectionByTool = loadedMatrix;
    if (envChanged || matrixChanged) {
      notifyListeners();
    }
  }

  Future<void> _persistEnvMode() async {
    // If persistence was never initialized, don't opportunistically create
    // storage state during tests.
    if (!_envModeLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final v = _heroEnvPillMode == HeroEnvPillMode.pollen ? 'pollen' : 'aqi';
    await prefs.setString(_k(_kHeroEnvMode), v);
    if (prefsNamespace.trim().isNotEmpty) {
      await prefs.remove(_kHeroEnvMode);
    }
  }

  Future<void> _persistMatrixWidgetSelections() async {
    if (!_envModeLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _matrixWidgetSelectionByTool.map(
        (key, value) => MapEntry<String, Object?>(key, value.toJson()),
      ),
    );
    await prefs.setString(_k(_kMatrixWidgetSelectionByTool), payload);
    if (prefsNamespace.trim().isNotEmpty) {
      await prefs.remove(_kMatrixWidgetSelectionByTool);
    }
  }

  HeroDetailsPillMode get heroDetailsPillMode => _heroDetailsPillMode;

  void setHeroDetailsPillMode(HeroDetailsPillMode value) {
    if (_heroDetailsPillMode == value) return;
    _heroDetailsPillMode = value;
    notifyListeners();
  }

  void toggleHeroDetailsPillMode() {
    _heroDetailsPillMode = _heroDetailsPillMode == HeroDetailsPillMode.sun
        ? HeroDetailsPillMode.wind
        : HeroDetailsPillMode.sun;
    notifyListeners();
  }

  // Pinned overlay details mode (independent from main hero).
  PinnedHeroDetailsMode get pinnedHeroDetailsMode => _pinnedHeroDetailsMode;

  void setPinnedHeroDetailsMode(PinnedHeroDetailsMode value) {
    if (_pinnedHeroDetailsMode == value) return;
    _pinnedHeroDetailsMode = value;
    notifyListeners();
  }

  void togglePinnedHeroDetailsMode() {
    _pinnedHeroDetailsMode = _pinnedHeroDetailsMode == PinnedHeroDetailsMode.sun
        ? PinnedHeroDetailsMode.wind
        : PinnedHeroDetailsMode.sun;
    notifyListeners();
  }

  PinnedHeroRightMode get pinnedHeroRightMode => _pinnedHeroRightMode;

  void setPinnedHeroRightMode(PinnedHeroRightMode value) {
    if (_pinnedHeroRightMode == value) return;
    _pinnedHeroRightMode = value;
    notifyListeners();
  }

  void togglePinnedHeroRightMode() {
    _pinnedHeroRightMode = _pinnedHeroRightMode == PinnedHeroRightMode.timeTemp
        ? PinnedHeroRightMode.currency
        : PinnedHeroRightMode.timeTemp;
    notifyListeners();
  }

  HeroEnvPillMode get heroEnvPillMode => _heroEnvPillMode;

  MatrixWidgetSelection? matrixWidgetSelectionFor(String toolId) {
    final key = toolId.trim();
    if (key.isEmpty) return null;
    return _matrixWidgetSelectionByTool[key];
  }

  Future<void> setMatrixWidgetSelection({
    required String toolId,
    required String rowKey,
    required String system,
    required String value,
    required String referenceLabel,
    required String primaryLabel,
    required String secondaryLabel,
  }) async {
    final normalizedToolId = toolId.trim();
    if (normalizedToolId.isEmpty) return;
    final selection = MatrixWidgetSelection(
      rowKey: rowKey,
      system: system,
      value: value,
      referenceLabel: referenceLabel,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
    );
    final current = _matrixWidgetSelectionByTool[normalizedToolId];
    if (current != null &&
        current.rowKey == selection.rowKey &&
        current.system == selection.system &&
        current.value == selection.value &&
        current.primaryLabel == selection.primaryLabel &&
        current.secondaryLabel == selection.secondaryLabel) {
      return;
    }
    _matrixWidgetSelectionByTool = <String, MatrixWidgetSelection>{
      ..._matrixWidgetSelectionByTool,
      normalizedToolId: selection,
    };
    await _persistMatrixWidgetSelections();
    notifyListeners();
  }

  void setHeroEnvPillMode(HeroEnvPillMode value) {
    if (_heroEnvPillMode == value) return;
    _heroEnvPillMode = value;
    _persistEnvMode();
    notifyListeners();
  }

  void toggleHeroEnvPillMode() {
    _heroEnvPillMode = _heroEnvPillMode == HeroEnvPillMode.aqi
        ? HeroEnvPillMode.pollen
        : HeroEnvPillMode.aqi;
    _persistEnvMode();
    notifyListeners();
  }

  DashboardReality _reality = DashboardReality.destination;
  final Map<String, List<ConversionRecord>> _history = {};

  DashboardReality get reality => _reality;

  void setReality(DashboardReality next) {
    if (next == _reality) return;
    _reality = next;
    notifyListeners();
  }

  List<ConversionRecord> historyFor(String toolId) {
    return List<ConversionRecord>.unmodifiable(_history[toolId] ?? const []);
  }

  ConversionRecord? latestFor(String toolId) {
    final list = _history[toolId];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  void addRecord(ConversionRecord record) {
    final list = _history.putIfAbsent(
      record.toolId,
      () => <ConversionRecord>[],
    );
    list.insert(0, record);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    notifyListeners();
  }

  void clearHistory(String toolId) {
    final list = _history[toolId];
    if (list == null || list.isEmpty) return;
    _history.remove(toolId);
    notifyListeners();
  }

  Map<String, MatrixWidgetSelection> _decodeMatrixWidgetSelections(
    String? raw,
  ) {
    if (raw == null || raw.trim().isEmpty) {
      return const <String, MatrixWidgetSelection>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, MatrixWidgetSelection>{};
      }
      final out = <String, MatrixWidgetSelection>{};
      decoded.forEach((key, value) {
        final k = key.toString().trim();
        if (k.isEmpty) return;
        final parsed = MatrixWidgetSelection.fromJson(value);
        if (parsed == null) return;
        out[k] = parsed;
      });
      return out;
    } catch (_) {
      return const <String, MatrixWidgetSelection>{};
    }
  }

  bool _mapsEqual(
    Map<String, MatrixWidgetSelection> a,
    Map<String, MatrixWidgetSelection> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      final value = entry.value;
      if (other == null) return false;
      if (value.rowKey != other.rowKey ||
          value.system != other.system ||
          value.value != other.value ||
          value.referenceLabel != other.referenceLabel ||
          value.primaryLabel != other.primaryLabel ||
          value.secondaryLabel != other.secondaryLabel) {
        return false;
      }
    }
    return true;
  }

  /// Tool ids ordered by most-recent use.
  ///
  /// This powers the Quick Tools "Recents" surface.
  List<String> recentToolIds({int max = 6}) {
    final entries = _history.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => (toolId: e.key, ts: e.value.first.timestamp))
        .toList(growable: false);

    entries.sort((a, b) => b.ts.compareTo(a.ts));
    final out = <String>[];
    for (final e in entries) {
      if (out.length >= max) break;
      out.add(e.toolId);
    }
    return out;
  }
}
