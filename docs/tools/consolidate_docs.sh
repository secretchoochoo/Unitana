#!/usr/bin/env bash
set -euo pipefail

# Consolidate Unitana docs into predictable, low-sprawl folders.
# Safe to run repeatedly.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$ROOT_DIR/docs"
AI="$DOCS/ai"

mkdir -p "$AI/prompts" "$AI/handoffs" "$AI/lessons" "$AI/retros" "$AI/plans" "$AI/templates"
mkdir -p "$DOCS/ui/screenshots/raw" "$DOCS/ui/screenshots/markup" "$DOCS/ui/mockups"
mkdir -p "$DOCS/patches" "$DOCS/tools"
mkdir -p "$DOCS/postmortems/2025-12" 2>/dev/null || true

move_if_exists() {
  local src="$1" dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$dst"
    mv "$src" "$dst/"
  fi
}

move_if_exists "$AI/NEXT_CHAT_PROMPT.md" "$AI/prompts"
move_if_exists "$AI/NEXT_CHAT_HANDOFF_2025-12-27.md" "$AI/handoffs"
move_if_exists "$AI/CHAT_LESSONS_2025-12-27.json" "$AI/lessons"
move_if_exists "$AI/RETRO_2025-12-27.md" "$AI/retros"
move_if_exists "$AI/CLEANUP_HARDENING_PLAN_2025-12-27.md" "$AI/plans"
move_if_exists "$AI/SLICE_13_DASHBOARD_DESIGN_PROMPT.md" "$AI/prompts"
move_if_exists "$AI/UIUX_PARALLEL_PROMPT.md" "$AI/prompts"
move_if_exists "$AI/SLICE_TEMPLATE.md" "$AI/templates"
move_if_exists "$AI/POSTMORTEM_SEV1_PLACES_HERO_TILE_2025-12-27.md" "$DOCS/postmortems/2025-12"

# Update references for common moved files.
export ROOT_DIR="$ROOT_DIR"
python3 - <<'PY'

from pathlib import Path
import os
root = Path(os.environ["ROOT_DIR"])
repls = {
  "docs/ai/NEXT_CHAT_PROMPT.md": "docs/ai/prompts/NEXT_CHAT_PROMPT.md",
  "docs/ai/NEXT_CHAT_HANDOFF_2025-12-27.md": "docs/ai/handoffs/NEXT_CHAT_HANDOFF_2025-12-27.md",
  "docs/ai/CHAT_LESSONS_2025-12-27.json": "docs/ai/lessons/CHAT_LESSONS_2025-12-27.json",
  "docs/ai/RETRO_2025-12-27.md": "docs/ai/retros/RETRO_2025-12-27.md",
  "docs/ai/CLEANUP_HARDENING_PLAN_2025-12-27.md": "docs/ai/plans/CLEANUP_HARDENING_PLAN_2025-12-27.md",
  "docs/ai/SLICE_TEMPLATE.md": "docs/ai/templates/SLICE_TEMPLATE.md",
  "docs/ai/SLICE_13_DASHBOARD_DESIGN_PROMPT.md": "docs/ai/prompts/SLICE_13_DASHBOARD_DESIGN_PROMPT.md",
  "docs/ai/UIUX_PARALLEL_PROMPT.md": "docs/ai/prompts/UIUX_PARALLEL_PROMPT.md",
}

text_ext = {".md", ".txt", ".json"}
for p in root.rglob("*"):
  if not p.is_file() or p.suffix.lower() not in text_ext:
    continue
  try:
    s = p.read_text(encoding="utf-8")
  except Exception:
    continue
  ns = s
  for a,b in repls.items():
    ns = ns.replace(a,b)
  if ns != s:
    p.write_text(ns, encoding="utf-8")
PY

echo "Docs consolidated."
