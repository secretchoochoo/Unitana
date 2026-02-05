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
  final String inputLabel;
  final String outputLabel;
  final DateTime timestamp;

  const ConversionRecord({
    required this.toolId,
    this.lensId,
    required this.inputLabel,
    required this.outputLabel,
    required this.timestamp,
  });
}

/// Session-scoped state for the dashboard page.
///
/// - selected reality: drives hero + tools
/// - per-tool conversion history (last 10)
class DashboardSessionController extends ChangeNotifier {
  final String prefsNamespace;

  DashboardSessionController({this.prefsNamespace = ''});

  static const String _kHeroEnvMode = 'hero_env_mode_v1';

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
    if (raw == null || raw.trim().isEmpty) return;
    final norm = raw.trim().toLowerCase();
    final next = norm == 'pollen'
        ? HeroEnvPillMode.pollen
        : HeroEnvPillMode.aqi;
    if (next == _heroEnvPillMode) return;
    _heroEnvPillMode = next;
    notifyListeners();
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
