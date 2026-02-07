import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitana/app/app.dart';

void main() {
  testWidgets('UnitanaApp configures localization delegates and locales', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const UnitanaApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, contains(const Locale('en')));
    expect(
      app.localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );
    expect(
      app.localizationsDelegates,
      contains(GlobalWidgetsLocalizations.delegate),
    );
    expect(
      app.localizationsDelegates,
      contains(GlobalCupertinoLocalizations.delegate),
    );
  });
}
