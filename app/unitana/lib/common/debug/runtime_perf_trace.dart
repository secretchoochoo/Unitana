import 'package:flutter/foundation.dart';

class RuntimePerfTrace {
  const RuntimePerfTrace._();

  static final bool enabled =
      kDebugMode &&
      const bool.fromEnvironment(
        'UNITANA_RUNTIME_PERF_TRACE',
        defaultValue: false,
      );

  static Stopwatch start(String label) {
    final sw = Stopwatch();
    if (!enabled) return sw;
    sw.start();
    debugPrint('[RuntimePerf] $label start');
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
    debugPrint('[RuntimePerf] $label ${elapsed}ms$suffix');
  }
}
