import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitanaAppState buildSeededState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);
    state.places = const <Place>[
      Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
      ),
      Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Lisbon',
        countryCode: 'PT',
        timeZoneId: 'Europe/Lisbon',
        unitSystem: 'metric',
        use24h: true,
      ),
    ];
    state.defaultPlaceId = 'home';
    return state;
  }

  testWidgets('Settings opens language sheet and persists selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('dashboard_menu_settings')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('settings_option_language')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('settings_language_system')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings_language_en')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_language_es')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_language_fr')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_language_pt-PT')),
      findsOneWidget,
    );

    final ptOption = find.byKey(const ValueKey('settings_language_pt-PT'));
    await tester.ensureVisible(ptOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(ptOption);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(state.preferredLanguageCode, 'pt-PT');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('preferred_language_code_v1'), 'pt-PT');
  });

  testWidgets('Settings exposes profile auto-suggest toggle (off by default)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('dashboard_menu_settings')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final toggle = find.byKey(
      const ValueKey('settings_option_profile_suggest'),
    );
    expect(toggle, findsOneWidget);
    expect(state.autoProfileSuggestEnabled, isFalse);

    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle(const Duration(milliseconds: 120));
    await tester.tap(toggle);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(state.autoProfileSuggestEnabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auto_profile_suggest_enabled_v1'), isTrue);
    expect(state.activeProfileId, 'profile_1');
  });

  testWidgets('Settings opens theme sheet and persists selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('dashboard_menu_settings')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('settings_option_theme')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('settings_theme_system')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_theme_dark')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_theme_light')), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_theme_light')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(state.preferredThemeMode, 'light');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('preferred_theme_mode_v1'), 'light');
  });

  testWidgets('Settings persists lo-fi audio toggle and volume', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('dashboard_menu_settings')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final audioToggle = find.byKey(
      const ValueKey('settings_option_lofi_audio'),
    );
    expect(audioToggle, findsOneWidget);
    expect(state.lofiAudioEnabled, isFalse);
    final initialSlider = find.byKey(
      const ValueKey('settings_lofi_volume_slider'),
    );
    expect(initialSlider, findsOneWidget);
    expect(tester.widget<Slider>(initialSlider).onChanged, isNull);

    await tester.ensureVisible(audioToggle);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(audioToggle);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(state.lofiAudioEnabled, isTrue);
    final enabledSlider = find.byKey(
      const ValueKey('settings_lofi_volume_slider'),
    );
    expect(enabledSlider, findsOneWidget);
    expect(tester.widget<Slider>(enabledSlider).onChanged, isNotNull);

    final slider = enabledSlider;
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.drag(slider, const Offset(200, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('lofi_audio_enabled_v1'), isTrue);
    expect((prefs.getDouble('lofi_audio_volume_v1') ?? 0) > 0.35, isTrue);

    final reloaded = UnitanaAppState(UnitanaStorage());
    await reloaded.load();
    expect(reloaded.lofiAudioEnabled, isTrue);
    expect(reloaded.lofiAudioVolume > 0.35, isTrue);
  });
}
