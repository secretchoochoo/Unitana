#!/usr/bin/env bash
set -euo pipefail

# Monorepo wrapper. Preferred entrypoint.
# Runs Flutter merge gates + icon audit for the Unitana app.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET="${REPO_ROOT}/app/unitana/tools/verify.sh"

if [ ! -x "$TARGET" ]; then
  echo "❌ verify: expected executable at $TARGET" >&2
  exit 1
fi

exec "$TARGET" "$@"
