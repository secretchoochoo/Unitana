#!/usr/bin/env bash
set -euo pipefail

# App-local wrapper to monorepo verify entrypoint.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"

"${REPO_ROOT}/tools/verify.sh" "$@"
