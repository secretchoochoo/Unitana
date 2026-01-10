# Platform icon audit (release readiness)

Purpose: prevent “placeholder icon” regressions by validating launcher icons for every target before packaging.

## iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` exists
- `ios/Runner/Info.plist` has `CFBundleIconName` set to `AppIcon`
- Clean build: delete app from simulator, `flutter clean`, then `flutter build ios --debug`

## Android
- `android/app/src/main/res/mipmap-*/ic_launcher.png` exists
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` exists (adaptive icon)
- `android/app/src/main/AndroidManifest.xml` uses `android:icon="@mipmap/ic_launcher"`
- Build: `flutter build apk --debug`, `flutter build appbundle --debug`

## Web
- `web/manifest.json` references icons that exist:
  - `web/icons/Icon-192.png`
  - `web/icons/Icon-512.png`
- `web/favicon.png` exists
- Build: `flutter build web`

## macOS
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` exists
- Build: `flutter build macos --debug`

## Windows
- `windows/runner/resources/app_icon.ico` exists (non-empty)
- `windows/runner/Runner.rc` references the icon resource
- Build: `flutter build windows --debug`

## Linux (if shipping)
- Desktop entry + icon installation are packaging-step dependent; verify the `.desktop` entry references an installed icon name.
- Build: `flutter build linux --debug`
