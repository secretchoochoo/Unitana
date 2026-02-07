import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/cities.dart';
import 'package:unitana/widgets/city_picker.dart';

void main() {
  testWidgets('CityPicker shows top-cities heading and city search quality', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CityPicker(cities: kCuratedCities)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top Cities'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);

    await tester.enterText(find.byType(TextField), 'tokyo');
    await tester.pumpAndSettle();

    expect(find.text('Best Matches'), findsOneWidget);
    expect(find.textContaining('🇯🇵 Tokyo'), findsWidgets);
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

    expect(find.text('No matches yet. Try city or country.'), findsOneWidget);
  });
}
