# HANDOFF_NOTE_2025-12-30i — App icon + micro-tile overflow fix

## Why
- Make the `unitana_logo.png` the actual app icon across platforms so the brand matches what users see on the home screen.
- Fix failing `dashboard_smoke_test` caused by `RenderFlex overflowed by 12px` inside `UnitanaTile` when tiles are extremely short on small phones.

## What changed
### App icon
- Generated icons from `app/unitana/assets/brand/unitana_logo.png` and applied them to:
  - Android launcher icons (mipmap densities)
  - iOS `AppIcon.appiconset`
  - macOS `AppIcon.appiconset`
  - Web icons + favicon

### Layout overflow fix
- Updated `UnitanaTile` to introduce a `isMicro` layout mode for very short tiles:
  - tighter padding and vertical gaps
  - smaller icon and primary text size
  - hides `secondaryText` and `footerText` in micro mode (prevents vertical overflow)

## Files in this patch
- `app/unitana/lib/features/dashboard/widgets/unitana_tile.dart`
- `app/unitana/android/app/src/main/res/mipmap-*/ic_launcher.png`
- `app/unitana/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `app/unitana/macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `app/unitana/web/favicon.png`
- `app/unitana/web/icons/Icon-*.png`
- `docs/ai/context_db.json`

## Verification
Run:
- `dart format .`
- `flutter analyze`
- `flutter test`

Expected:
- `dashboard_smoke_test.dart` passes without any `RenderFlex overflow` exceptions.
