import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/tool_registry.dart';

void main() {
  test('deferred tools remain explicit and reasoned', () {
    final deferred = ToolRegistry.deferredTools();
    final deferredIds = deferred.map((t) => t.toolId).toSet();

    expect(deferredIds, {
      'cups_grams_estimates',
      'pace',
      'hydration',
      'energy',
      'clothing_sizes',
    });

    for (final tool in deferred) {
      expect(
        tool.isEnabled,
        isFalse,
        reason: '${tool.toolId} must be disabled',
      );
      expect(tool.deferReason, isNotNull);
      expect(tool.deferReason!.trim(), isNotEmpty);
    }
  });

  test('time and temperature aliases map to canonical targets', () {
    final byId = ToolRegistry.byId;

    expect(byId['world_clock_delta']?.surfaceType, ToolSurfaceType.aliasPreset);
    expect(byId['world_clock_delta']?.aliasTargetToolId, 'time');

    expect(byId['jet_lag_delta']?.surfaceType, ToolSurfaceType.dedicated);
    expect(byId['jet_lag_delta']?.aliasTargetToolId, isNull);

    expect(byId['timezone_lookup']?.surfaceType, ToolSurfaceType.aliasPreset);
    expect(byId['timezone_lookup']?.aliasTargetToolId, 'time_zone_converter');

    expect(byId['oven_temperature']?.surfaceType, ToolSurfaceType.aliasPreset);
    expect(byId['oven_temperature']?.aliasTargetToolId, 'temperature');
  });
}
