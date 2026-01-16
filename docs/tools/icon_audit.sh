#!/usr/bin/env bash
set -euo pipefail

# Monorepo wrapper. Preferred entrypoint.
# Runs the lightweight platform icon audit for the Unitana app.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET="${REPO_ROOT}/app/unitana/tools/icon_audit.sh"

if [ ! -x "$TARGET" ]; then
  echo "❌ icon_audit: expected executable at $TARGET" >&2
  exit 1
fi

exec "$TARGET" "$@"
