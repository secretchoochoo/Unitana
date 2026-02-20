# Unitana

Unitana is a travel-first dual-reality dashboard for home/destination context:
time, weather, currency, and conversion tools in one surface.

## Release

Current public release target: `v1.0.0`.

## Install

### Android (APK)

1. Download `app-release.apk` from the latest GitHub Release assets.
2. On Android, allow installation from unknown sources for your browser/files app.
3. Open the APK and install.

### iOS (Simulator Build)

1. Clone repo and install dependencies:

```bash
cd app/unitana
flutter pub get
cd ios
pod install
```

2. Build iOS simulator app:

```bash
cd app/unitana
flutter build ios --simulator --release \
  --dart-define=UNITANA_APP_VERSION=1.0.0 \
  --dart-define=UNITANA_BUILD_NUMBER=100 \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

3. Open `app/unitana/ios/Runner.xcworkspace` in Xcode and run on simulator/device.

For App Store/TestFlight distribution, use Xcode archive/signing with your Apple Developer account.

## Build

From `app/unitana`:

```bash
flutter pub get
flutter build apk --release \
  --dart-define=UNITANA_APP_VERSION=1.0.0 \
  --dart-define=UNITANA_BUILD_NUMBER=100 \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

For iOS:

```bash
flutter build ios --simulator --release \
  --dart-define=UNITANA_APP_VERSION=1.0.0 \
  --dart-define=UNITANA_BUILD_NUMBER=100 \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

## Branch Strategy

1. `codex/development`:
   - Active implementation branch.
   - Full internal docs and QA/dev tooling allowed.
2. `codex/release-vX.Y.Z`:
   - Release-hardening branch cut from `codex/development`.
   - Developer Tools disabled by default.
   - Public docs/readme only.
3. `main`:
   - Mirrors the currently shipped release state.
   - Updated only from validated release branch promotions.

Promotion flow:

1. Develop and test on `codex/development`.
2. Cut `codex/release-vX.Y.Z`.
3. Apply release-only hardening and build artifacts.
4. Tag and publish GitHub Release.
5. Merge release branch to `main`.

## Public Repo Release Checklist

1. Create public repo.
2. Push `codex/release-v1.0.0`.
3. Create tag `v1.0.0`.
4. Attach Android APK and iOS build notes in the Release.
5. Verify About screen shows `Version 1.0.0 (100)`.

## Development Commands

From `app/unitana`:

```bash
dart format .
flutter analyze
flutter test
flutter run
```

From repo root:

```bash
./tools/verify.sh
```

## Git Hook (Optional)

```bash
git config core.hooksPath tools/githooks
```
