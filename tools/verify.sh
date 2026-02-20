#!/usr/bin/env bash
set -euo pipefail

# Monorepo verify entrypoint.
# Can be run from any cwd inside the repository.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
APP_ROOT="${REPO_ROOT}/app/unitana"

"${REPO_ROOT}/docs/tools/verify_docs.sh"

cd "${APP_ROOT}"

flutter pub get
dart format .
flutter analyze
flutter test

echo "✅ verify.sh passed"
