import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/tool_registry.dart';

void main() {
  test('deferred tools remain explicit and reasoned', () {
    final deferred = ToolRegistry.deferredTools();
    final deferredIds = deferred.map((t) => t.toolId).toSet();

    expect(deferredIds, {'clothing_sizes'});

    for (final tool in deferred) {
      expect(
        tool.isEnabled,
        isFalse,
        reason: '${tool.toolId} must be disabled',
      );
      expect(tool.deferReason, isNotNull);
      expect(tool.deferReason!.trim(), isNotEmpty);
      if (tool.toolId == 'clothing_sizes') {
        expect(tool.deferReason, contains('Activate only after'));
        expect(tool.deferReason, contains('confidence'));
      }
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

  test('energy is enabled as configurable template', () {
    final energy = ToolRegistry.byId['energy'];
    expect(energy, isNotNull);
    expect(energy!.isEnabled, isTrue);
    expect(energy.surfaceType, ToolSurfaceType.configurableTemplate);
    expect(energy.deferReason, isNull);
  });

  test('pace is enabled as configurable template', () {
    final pace = ToolRegistry.byId['pace'];
    expect(pace, isNotNull);
    expect(pace!.isEnabled, isTrue);
    expect(pace.surfaceType, ToolSurfaceType.configurableTemplate);
    expect(pace.deferReason, isNull);
  });

  test('cups/grams estimates is enabled as configurable template', () {
    final cups = ToolRegistry.byId['cups_grams_estimates'];
    expect(cups, isNotNull);
    expect(cups!.isEnabled, isTrue);
    expect(cups.surfaceType, ToolSurfaceType.configurableTemplate);
    expect(cups.deferReason, isNull);
  });

  test('hydration is enabled as dedicated surface', () {
    final hydration = ToolRegistry.byId['hydration'];
    expect(hydration, isNotNull);
    expect(hydration!.isEnabled, isTrue);
    expect(hydration.surfaceType, ToolSurfaceType.dedicated);
    expect(hydration.deferReason, isNull);
  });
}
