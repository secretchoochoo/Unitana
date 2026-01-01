#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

required=(
  "$ROOT_DIR/context_db.json"
  "$ROOT_DIR/INDEX.md"
  "$ROOT_DIR/handoff/CURRENT_HANDOFF.md"
  "$ROOT_DIR/prompts/NEXT_CHAT_PROMPT.md"
  "$ROOT_DIR/reference/WORKFLOW.md"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing required file: $f"
    exit 1
  fi
done

python3 - <<'PY'
import json, pathlib
p = pathlib.Path("docs/ai/context_db.json")
json.loads(p.read_text())
print("OK: context_db.json is valid JSON")
PY

echo "OK: AI docs pack looks good"
