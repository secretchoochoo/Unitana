# Release Build Workflow

## Purpose

This document defines the repository-side setup for producing release artifacts without falling back to example IDs or debug signing.

## Preconditions

- Repo verification passes:
  - `./tools/verify.sh`
- Release config verification passes:
  - `./tools/verify_release_config.sh`
- Android release signing secrets exist locally:
  - `app/unitana/android/key.properties`
- If building Apple release artifacts locally, local signing overrides exist:
  - `app/unitana/ios/Flutter/Signing.xcconfig`
  - `app/unitana/macos/Runner/Configs/Signing.xcconfig`

## Android release signing setup

1. Copy the template:

```bash
cp app/unitana/android/key.properties.example app/unitana/android/key.properties
```

2. Replace all placeholder values in `app/unitana/android/key.properties`.

Expected fields:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

The committed Android Gradle config will refuse release builds if this file is missing so we do not silently sign release artifacts with the debug key.

## Apple signing setup

For iOS, copy:

```bash
cp app/unitana/ios/Flutter/Signing.xcconfig.example app/unitana/ios/Flutter/Signing.xcconfig
```

For macOS, copy:

```bash
cp app/unitana/macos/Runner/Configs/Signing.xcconfig.example app/unitana/macos/Runner/Configs/Signing.xcconfig
```

Use those local files to provide:

- `DEVELOPMENT_TEAM`
- `CODE_SIGN_STYLE`
- optional manual-signing overrides if your distribution process requires them

The committed repo keeps the bundle identifiers stable while leaving team/provisioning secrets and workstation-specific signing choices uncommitted.

## Release build commands

From `app/unitana/`:

### Android App Bundle

```bash
flutter build appbundle \
  --release \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

### Android APK

```bash
flutter build apk \
  --release \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

### iOS archive prep

```bash
flutter build ios \
  --release \
  --no-codesign \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

If local signing is configured and you intend to archive directly through Xcode, open the workspace in `app/unitana/ios/Runner.xcworkspace` and use the `Release` configuration with the local signing overrides in place.

### macOS

```bash
flutter build macos \
  --release \
  --dart-define=UNITANA_DEVTOOLS_ENABLED=false
```

## Required release checks

- `UNITANA_DEVTOOLS_ENABLED=false` for public builds
- `./tools/verify.sh` green before packaging
- `./tools/verify_release_config.sh` green before packaging
- release artifact version matches `app/unitana/pubspec.yaml`
- platform bundle/application identifiers resolve to `app.unitana`-based IDs

## Current repository guarantees

- example platform identifiers are rejected by `./tools/verify_release_config.sh`
- Android release config no longer points at the debug signing config
- CI runs the release-config verification step before analyze/test

## Remaining non-repo work

- provision the real Android keystore and passwords outside version control
- configure Apple team/provisioning details for the delivery environment
- exercise one end-to-end signed release candidate per platform before treating the release path as fully complete
