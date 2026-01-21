import 'package:flutter/foundation.dart';

/// Session-scoped details pill mode.
///
/// Shared between the main Places Hero and the pinned overlay.
enum HeroDetailsPillMode { sun, wind }

/// Session-scoped env pill mode (Hero left rail).
enum HeroEnvPillMode { aqi, pollen }

/// Backwards-compatible enum name for pinned overlay callers.
enum PinnedHeroDetailsMode { sun, wind }

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

  // Places hero env pill mode (AQI / Pollen).
  //
  // Session-scoped only: not persisted. Defaults to AQI as a neutral baseline.
  HeroEnvPillMode _heroEnvPillMode = HeroEnvPillMode.aqi;

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

  HeroEnvPillMode get heroEnvPillMode => _heroEnvPillMode;

  void setHeroEnvPillMode(HeroEnvPillMode value) {
    if (_heroEnvPillMode == value) return;
    _heroEnvPillMode = value;
    notifyListeners();
  }

  void toggleHeroEnvPillMode() {
    _heroEnvPillMode = _heroEnvPillMode == HeroEnvPillMode.aqi
        ? HeroEnvPillMode.pollen
        : HeroEnvPillMode.aqi;
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
