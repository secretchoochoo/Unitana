#!/usr/bin/env bash
set -euo pipefail

# Run merge gates + lightweight platform icon audit.
# Can be run from anywhere.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "❌ verify: $*" >&2
  exit 1
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

flutter pub get

dart format .
flutter analyze
flutter test

"${SCRIPT_DIR}/icon_audit.sh"

echo "✅ verify.sh passed"
