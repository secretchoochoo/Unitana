#!/usr/bin/env python3
"""Register a patch zip in the repo and the AI context database.

Usage:
  python3 docs/tools/register_patch.py --zip /path/to/patch.zip \
    --title "Fix dashboard smoke overflow" \
    --summary "Resolved RenderFlex overflow; updated tests" \
    --slice "dashboard" \
    --files "lib/features/dashboard/..." 

What it does:
- Copies the zip into docs/patches/YYYY-MM-DD/
- Appends a record under `artifacts.patches` in docs/ai/context_db.json
- Adds a line entry to docs/patches/PATCH_LOG.md
"""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--zip", dest="zip_path", required=True, help="Path to patch zip")
    p.add_argument("--title", required=True)
    p.add_argument("--summary", required=True)
    p.add_argument("--slice", default="")
    p.add_argument("--files", default="")
    p.add_argument("--date", default="", help="Override date YYYY-MM-DD")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    docs = repo_root / "docs"
    ai_db = docs / "ai" / "context_db.json"
    patch_log = docs / "patches" / "PATCH_LOG.md"

    zip_src = Path(args.zip_path).expanduser().resolve()
    if not zip_src.exists():
        raise SystemExit(f"Zip not found: {zip_src}")

    day = args.date or datetime.now().strftime("%Y-%m-%d")
    dest_dir = docs / "patches" / day
    dest_dir.mkdir(parents=True, exist_ok=True)

    dest_zip = dest_dir / zip_src.name
    shutil.copy2(zip_src, dest_zip)

    # Load / update context DB
    db = json.loads(ai_db.read_text(encoding="utf-8"))
    db.setdefault("artifacts", {})
    artifacts = db["artifacts"]
    artifacts.setdefault("patches", [])

    patch_id = f"patch-{day}-{len(artifacts['patches'])+1:03d}"
    rec = {
        "id": patch_id,
        "date": day,
        "title": args.title,
        "summary": args.summary,
        "slice": args.slice,
        "files": [x.strip() for x in args.files.split(",") if x.strip()],
        "zip_path": str(dest_zip.relative_to(repo_root)).replace("\\", "/"),
    }
    artifacts["patches"].append(rec)
    ai_db.write_text(json.dumps(db, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Ensure PATCH_LOG exists
    if not patch_log.exists():
        patch_log.write_text(
            "# Patch Log\n\n| Date | Patch | Title |\n|---|---|---|\n",
            encoding="utf-8",
        )

    # Append to patch log
    rel = rec["zip_path"]
    line = f"| {day} | `{rel}` | {args.title} |\n"
    s = patch_log.read_text(encoding="utf-8")
    if line not in s:
        patch_log.write_text(s + line, encoding="utf-8")

    print(f"Registered {patch_id} -> {dest_zip}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
