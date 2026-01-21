#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper to run the Flutter icon audit from monorepo root.
# Can be run from anywhere.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

"${REPO_ROOT}/app/unitana/tools/icon_audit.sh"
