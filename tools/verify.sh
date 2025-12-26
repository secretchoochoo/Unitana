#!/usr/bin/env bash
set -euo pipefail

# Run this from the Flutter project root.
# Usage: ./tools/verify.sh

flutter pub get

dart format .
flutter analyze
flutter test

echo "✅ verify.sh passed"
