#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${1:-$ROOT/tmp/restore_points/$TS}"

mkdir -p "$OUT_DIR"

echo "Creating restore point at: $OUT_DIR"

git -C "$ROOT" rev-parse HEAD >"$OUT_DIR/base_commit.txt"
git -C "$ROOT" status --short >"$OUT_DIR/status_short.txt"
git -C "$ROOT" status >"$OUT_DIR/status_full.txt"
git -C "$ROOT" diff >"$OUT_DIR/working_tree.diff"
git -C "$ROOT" diff --staged >"$OUT_DIR/staged.diff"
git -C "$ROOT" ls-files >"$OUT_DIR/tracked_files.txt"

SNAPSHOT="$OUT_DIR/worktree_snapshot.tgz"
tar \
  --exclude=".git" \
  --exclude=".venv" \
  --exclude="tmp/restore_points" \
  --exclude="app/unitana/.dart_tool" \
  --exclude="app/unitana/build" \
  --exclude="app/unitana/.packages" \
  -czf "$SNAPSHOT" \
  -C "$ROOT" \
  .

cat >"$OUT_DIR/README.txt" <<EOF
Unitana restore point
=====================

Timestamp: $TS
Repo root: $ROOT
Base commit: $(cat "$OUT_DIR/base_commit.txt")

Artifacts:
- base_commit.txt
- status_short.txt
- status_full.txt
- working_tree.diff
- staged.diff
- tracked_files.txt
- worktree_snapshot.tgz

Restore quick path:
1) checkout base commit
2) reapply working_tree.diff and staged.diff as needed
3) if needed, extract worktree_snapshot.tgz into a clean checkout
EOF

echo "Restore point created successfully."
