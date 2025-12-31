#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper around record_patch.py.
# Example:
#   ./docs/ai/tools/record_patch.sh 2025-12-29f unitana_patch_example_2025-12-29f.zip "Fix overflow in hero"

PATCH_ID="${1:-}"
ARTIFACT="${2:-}"
SUMMARY="${3:-}"

if [[ -z "$PATCH_ID" || -z "$ARTIFACT" || -z "$SUMMARY" ]]; then
  echo "Usage: $0 <patch-id> <artifact-zip-name> <summary>"
  exit 2
fi

python3 docs/ai/tools/record_patch.py --patch-id "$PATCH_ID" --artifact "$ARTIFACT" --summary "$SUMMARY"
