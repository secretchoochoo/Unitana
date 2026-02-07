import 'package:flutter/foundation.dart';

class PickerPerfTrace {
  const PickerPerfTrace._();

  static final bool enabled =
      kDebugMode &&
      const bool.fromEnvironment(
        'UNITANA_PICKER_PERF_TRACE',
        defaultValue: false,
      );

  static Stopwatch start(String label) {
    final sw = Stopwatch();
    if (!enabled) return sw;
    sw.start();
    if (enabled) {
      debugPrint('[PickerPerf] $label start');
    }
    return sw;
  }

  static void logElapsed(
    String label,
    Stopwatch sw, {
    String? extra,
    int minMs = 0,
  }) {
    if (!enabled) return;
    final elapsed = sw.elapsedMilliseconds;
    if (elapsed < minMs) return;
    final suffix = extra == null || extra.isEmpty ? '' : ' | $extra';
    debugPrint('[PickerPerf] $label ${elapsed}ms$suffix');
  }
}
