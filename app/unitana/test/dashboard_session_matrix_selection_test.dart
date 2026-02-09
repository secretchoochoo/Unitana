import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matrix widget selection persists per profile namespace', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final session = DashboardSessionController(prefsNamespace: 'profile_a');
    await session.loadPersisted();
    await session.setMatrixWidgetSelection(
      toolId: 'paper_sizes',
      rowKey: 'paper_a4',
      system: 'JIS',
      value: 'B5 (182 x 257 mm)',
      referenceLabel: 'A4',
      primaryLabel: 'B5 (182 x 257 mm)',
      secondaryLabel: 'JIS • A4',
    );

    final current = session.matrixWidgetSelectionFor('paper_sizes');
    expect(current, isNotNull);
    expect(current!.primaryLabel, 'B5 (182 x 257 mm)');
    expect(current.secondaryLabel, 'JIS • A4');

    final reloaded = DashboardSessionController(prefsNamespace: 'profile_a');
    await reloaded.loadPersisted();
    final persisted = reloaded.matrixWidgetSelectionFor('paper_sizes');
    expect(persisted, isNotNull);
    expect(persisted!.rowKey, 'paper_a4');
    expect(persisted.system, 'JIS');
    expect(persisted.primaryLabel, 'B5 (182 x 257 mm)');
    expect(persisted.secondaryLabel, 'JIS • A4');
  });

  test('matrix widget selection remains isolated by namespace', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final a = DashboardSessionController(prefsNamespace: 'profile_a');
    await a.loadPersisted();
    await a.setMatrixWidgetSelection(
      toolId: 'shoe_sizes',
      rowKey: 'shoe_10',
      system: 'EU',
      value: '43',
      referenceLabel: '28.0 cm',
      primaryLabel: '43',
      secondaryLabel: 'EU • 28.0 cm',
    );

    final b = DashboardSessionController(prefsNamespace: 'profile_b');
    await b.loadPersisted();
    expect(b.matrixWidgetSelectionFor('shoe_sizes'), isNull);
  });
}
