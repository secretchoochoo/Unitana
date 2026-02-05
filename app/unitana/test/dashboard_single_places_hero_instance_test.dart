import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/widgets/places_hero_v2.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Dashboard surface renders exactly one PlacesHeroV2', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    expect(find.byType(PlacesHeroV2), findsOneWidget);
  });
}
