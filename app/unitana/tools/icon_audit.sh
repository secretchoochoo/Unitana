#!/usr/bin/env bash
set -euo pipefail

# Platform icon audit (release readiness)
# Can be run from anywhere.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "❌ icon_audit: $*" >&2
  exit 1
}

note() {
  echo "• $*"
}

find_flutter_root() {
  local dir="$1"
  while true; do
    if [ -f "$dir/pubspec.yaml" ] && [ -d "$dir/lib" ]; then
      echo "$dir"
      return 0
    fi
    if [ "$dir" = "/" ]; then
      return 1
    fi
    dir="$(cd -- "$dir/.." && pwd)"
  done
}

FLUTTER_ROOT="$(find_flutter_root "$SCRIPT_DIR")" || fail "Could not locate Flutter root (pubspec.yaml) above $SCRIPT_DIR"

cd "$FLUTTER_ROOT"

note "Flutter root: $FLUTTER_ROOT"

# iOS
[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ] || fail "Missing iOS AppIcon Contents.json"
/usr/bin/python3 - <<'PY'
import plistlib
from pathlib import Path
p = Path('ios/Runner/Info.plist')
if not p.exists():
    raise SystemExit('Missing ios/Runner/Info.plist')
pl = plistlib.load(p.open('rb'))
if pl.get('CFBundleIconName') != 'AppIcon':
    raise SystemExit(f"CFBundleIconName expected 'AppIcon', found {pl.get('CFBundleIconName')!r}")
print('✓ iOS Info.plist CFBundleIconName = AppIcon')
PY

# Android
[ -f "android/app/src/main/AndroidManifest.xml" ] || fail "Missing AndroidManifest.xml"
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  [ -f "android/app/src/main/res/mipmap-${d}/ic_launcher.png" ] || fail "Missing android mipmap-${d}/ic_launcher.png"
done
[ -f "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" ] || fail "Missing android adaptive icon xml"
if ! grep -q 'android:icon="@mipmap/ic_launcher"' android/app/src/main/AndroidManifest.xml; then
  fail "AndroidManifest.xml does not reference @mipmap/ic_launcher"
fi

# Web
[ -f "web/favicon.png" ] || fail "Missing web/favicon.png"
[ -f "web/manifest.json" ] || fail "Missing web/manifest.json"
[ -f "web/icons/Icon-192.png" ] || fail "Missing web/icons/Icon-192.png"
[ -f "web/icons/Icon-512.png" ] || fail "Missing web/icons/Icon-512.png"

# macOS
[ -f "macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ] || fail "Missing macOS AppIcon Contents.json"

# Windows
[ -f "windows/runner/resources/app_icon.ico" ] || fail "Missing windows app_icon.ico"
[ -s "windows/runner/resources/app_icon.ico" ] || fail "windows app_icon.ico is empty"
[ -f "windows/runner/Runner.rc" ] || fail "Missing windows Runner.rc"

echo "✅ icon_audit.sh passed"
