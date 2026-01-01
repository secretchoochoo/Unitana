# Workflow for working with ChatGPT on Unitana

## Non-negotiables
1. Keep `docs/ai/context_db.json` present at `docs/ai/context_db.json`.
2. Update the patch log on every meaningful change.
3. Update the handoff whenever priorities change.
4. Keep the AI docs pack small and canonical.

## Patch note format
Add an entry to `context_db.json.patch_log`:

```json
{
  "patch_id": "PATCH-YYYY-MM-DD-XX",
  "summary": "One sentence outcome",
  "files_changed": ["path/one.dart", "path/two.md"],
  "tests": ["flutter analyze", "flutter test"],
  "notes": ["any gotchas"]
}
```

## When to create new files
Only create a new file when the content is long-lived and canonical. Otherwise, update the existing file.
