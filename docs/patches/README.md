# Patch Archive

Patch zips are optional but useful when iterating quickly with ChatGPT. They act like small, reviewable "shipping crates": each one should be self-contained, traceable to a specific intent, and easy to apply or revert.

## Folder map

- `docs/patches/YYYY-MM-DD/` – all patch zips created that day
- `docs/patches/PATCH_LOG.md` – human-readable index

## Zip naming schema

`unitana_patch_<short_slug>_YYYY-MM-DD[a|b|c].zip`

Examples:

- `unitana_patch_compile_fix_dashboard_menu_and_unitsystem_2025-12-28c.zip`
- `unitana_patch_stability_plus_postmortem_and_next_prompt_2025-12-29.zip`

## What a patch should include

- Only the files that changed
- If code changes: updated or added tests
- If docs-only: a brief `notes.md` inside the day folder, or an entry in `PATCH_LOG.md`

## Registering patches in the AI context DB

Use `docs/tools/register_patch.py` to copy a zip into this archive and append an entry to `docs/ai/context_db.json`.
