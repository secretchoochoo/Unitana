import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform icon assets exist for supported targets', () {
    // These paths are intentionally relative to the Flutter project root
    // (unitana/app/unitana). If any are missing, platform builds tend to fall
    // back to placeholders or fail late.
    final requiredPaths = <String>[
      // iOS
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      'ios/Runner/Info.plist',

      // Android (adaptive icon preferred on modern launchers)
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',

      // Web
      'web/manifest.json',
      'web/icons/Icon-192.png',
      'web/icons/Icon-512.png',
      'web/favicon.png',

      // macOS
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',

      // Windows
      'windows/runner/CMakeLists.txt',
      'windows/runner/Runner.rc',
      'windows/runner/resources/app_icon.ico',
    ];

    final missing = <String>[];
    for (final p in requiredPaths) {
      if (!File(p).existsSync() && !Directory(p).existsSync()) {
        missing.add(p);
      }
    }

    expect(missing, isEmpty, reason: 'Missing platform icon assets: $missing');
  });

  test('platform icon wiring is consistent with platform manifests', () {
    // iOS: Info.plist must point at the AppIcon set.
    final iosPlist = File('ios/Runner/Info.plist');
    expect(iosPlist.existsSync(), isTrue, reason: 'Missing iOS Info.plist');
    final iosText = iosPlist.readAsStringSync();
    final iconNameMatch = RegExp(
      r'<key>CFBundleIconName</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    ).firstMatch(iosText);
    expect(
      iconNameMatch,
      isNotNull,
      reason: 'CFBundleIconName not found in iOS Info.plist',
    );
    expect(
      iconNameMatch!.group(1),
      'AppIcon',
      reason: 'iOS CFBundleIconName should be AppIcon',
    );

    // Android: AndroidManifest should use the canonical launcher icon reference.
    final androidManifest = File('android/app/src/main/AndroidManifest.xml');
    expect(
      androidManifest.existsSync(),
      isTrue,
      reason: 'Missing AndroidManifest.xml',
    );
    final androidText = androidManifest.readAsStringSync();
    expect(
      RegExp(r'android:icon\s*=\s*"@mipmap/ic_launcher"').hasMatch(androidText),
      isTrue,
      reason:
          'AndroidManifest.xml must set android:icon to @mipmap/ic_launcher',
    );

    // Web: manifest.json should reference icon files that exist.
    final webManifest = File('web/manifest.json');
    expect(
      webManifest.existsSync(),
      isTrue,
      reason: 'Missing web/manifest.json',
    );
    final webJson =
        jsonDecode(webManifest.readAsStringSync()) as Map<String, dynamic>;
    final icons = (webJson['icons'] as List<dynamic>?) ?? const [];
    final referenced = <String>[];
    for (final entry in icons) {
      if (entry is Map<String, dynamic>) {
        final src = entry['src'];
        if (src is String && src.isNotEmpty) {
          referenced.add(src);
        }
      }
    }
    expect(
      referenced,
      containsAll(<String>['icons/Icon-192.png', 'icons/Icon-512.png']),
      reason: 'Web manifest must include 192 and 512 launcher icons',
    );
    final missingWebIcons = <String>[];
    for (final src in referenced) {
      final path = 'web/$src';
      if (!File(path).existsSync()) {
        missingWebIcons.add(path);
      }
    }
    expect(
      missingWebIcons,
      isEmpty,
      reason: 'Web manifest references missing icon files: $missingWebIcons',
    );

    // Windows: Runner.rc should point at the canonical app_icon.ico, which must be non-empty.
    final runnerRc = File('windows/runner/Runner.rc');
    if (runnerRc.existsSync()) {
      final rcText = runnerRc.readAsStringSync();
      expect(
        rcText.contains('resources\\app_icon.ico'),
        isTrue,
        reason: 'Runner.rc should reference resources\\app_icon.ico',
      );
      final ico = File('windows/runner/resources/app_icon.ico');
      expect(ico.existsSync(), isTrue, reason: 'Missing Windows app_icon.ico');
      expect(
        ico.lengthSync(),
        greaterThan(0),
        reason: 'Windows app_icon.ico is empty',
      );
    }
  });
}
