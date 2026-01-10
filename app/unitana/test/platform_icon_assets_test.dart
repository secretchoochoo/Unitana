import 'dart:io';

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
}
