#!/usr/bin/env python3
"""Append a patch record to docs/ai/context_db.json.

Usage:
  python3 docs/ai/tools/record_patch.py \
    --patch-id 2025-12-29f \
    --artifact unitana_patch_something_2025-12-29f.zip \
    --summary "One-line summary" \
    --files "lib/foo.dart,lib/bar.dart" \
    --tests "flutter analyze; flutter test" \
    --notes "Optional longer notes"

This script is intentionally dependency-free (no jq required).
"""

import argparse
import datetime
import json
import os
from typing import Any, Dict, List

def _load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def _write_json(path: str, obj: Dict[str, Any]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--context-db", default="docs/ai/context_db.json")
    ap.add_argument("--patch-id", required=True)
    ap.add_argument("--artifact", required=True)
    ap.add_argument("--summary", required=True)
    ap.add_argument("--files", default="")
    ap.add_argument("--tests", default="")
    ap.add_argument("--notes", default="")
    args = ap.parse_args()

    path = args.context_db
    if not os.path.exists(path):
        raise SystemExit(f"context_db.json not found at: {path}")

    db = _load_json(path)
    db.setdefault("patch_tracking", {})
    db["patch_tracking"].setdefault("policy", {})
    db["patch_tracking"].setdefault("log", [])

    today = datetime.date.today().isoformat()
    entry = {
        "patch_id": args.patch_id,
        "date": today,
        "artifact": args.artifact,
        "summary": args.summary.strip(),
        "files_touched": [s.strip() for s in args.files.split(",") if s.strip()],
        "tests": args.tests.strip(),
        "notes": args.notes.strip(),
        "source": "local_script",
    }

    # Guardrails: prevent accidental duplicates
    existing = db["patch_tracking"]["log"]
    if any(isinstance(e, dict) and e.get("patch_id") == args.patch_id for e in existing):
        raise SystemExit(f"patch_id already exists in patch_tracking.log: {args.patch_id}")
    if any(isinstance(e, dict) and e.get("artifact") == args.artifact for e in existing):
        raise SystemExit(f"artifact already exists in patch_tracking.log: {args.artifact}")

    db["patch_tracking"]["log"].append(entry)
    db["last_updated"] = today

    _write_json(path, db)
    print(f"Recorded patch {args.patch_id} -> {path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
