import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('Hero details pill toggles between sun and wind', (tester) async {
    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    // Default details mode.
    expect(find.text('Sunrise • Sunset'), findsOneWidget);

    await tester.tap(find.text('Sunrise • Sunset'));
    await pumpStable(tester);

    expect(find.text('Wind • Gust'), findsOneWidget);

    await tester.tap(find.text('Wind • Gust'));
    await pumpStable(tester);

    expect(find.text('Sunrise • Sunset'), findsOneWidget);
  });
}
