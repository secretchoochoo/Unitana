import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';

void main() {
  test('Dashboard session history preserves optional lens tags', () {
    final session = DashboardSessionController();

    session.addRecord(
      ConversionRecord(
        toolId: 'liquids',
        lensId: 'food_and_cooking',
        inputLabel: '1 cup',
        outputLabel: '240 ml',
        timestamp: DateTime(2025, 12, 29, 12, 0, 0),
      ),
    );

    final history = session.historyFor('liquids');
    expect(history, hasLength(1));
    expect(history.first.lensId, 'food_and_cooking');
  });
}
