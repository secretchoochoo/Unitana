import 'package:flutter/foundation.dart';

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
