import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/cities.dart';
import 'package:unitana/widgets/city_picker.dart';

void main() {
  testWidgets('CityPicker shows popular heading and supports EST shorthand', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CityPicker(cities: kCuratedCities)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Popular Cities'), findsOneWidget);
    expect(find.textContaining('🇺🇸 New York'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'est');
    await tester.pumpAndSettle();

    expect(find.text('Best Matches'), findsOneWidget);
    expect(find.textContaining('🇺🇸 New York'), findsWidgets);
  });

  testWidgets('CityPicker shows clear empty-state guidance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CityPicker(cities: kCuratedCities)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzzzz-no-city');
    await tester.pumpAndSettle();

    expect(
      find.text('No matches yet. Try city, country, timezone, or EST.'),
      findsOneWidget,
    );
  });
}
