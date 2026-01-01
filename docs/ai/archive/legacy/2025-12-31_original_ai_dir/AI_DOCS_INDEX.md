# Unitana AI docs index

This folder is the entry point for handoffs and assistant context.

## Read order for a fresh chat
1. **docs/ai/WORKING_WITH_CHATGPT.md**
   - Workflow: patch packaging, review gates, test commands, and update rules.
2. **docs/ai/context_db.json**
   - Canonical structured context: design decisions, architecture, widgets, tool registry, and patch history.
3. **Newest docs/ai/NEXT_CHAT_HANDOFF_*.md**
   - The most recent summary of what changed, what is stable, what is next, and how to run checks.
4. **docs/ai/NEXT_CHAT_PROMPT.md**
   - The prompt we paste into a new chat to continue work without losing intent.
5. **Latest docs/ai/CHAT_LESSONS_*.json and docs/ai/RETRO_*.md**
   - Lessons learned and retros that explain why decisions exist.

## What to update when shipping a patch
- Code changes in **app/unitana/...**
- **docs/ai/context_db.json**
  - Add a new entry to `patch_history` with the patch id, title, artifact name, scope, and notes.
- **docs/ai/CHAT_LESSONS_YYYY-MM-DD.json** (if the patch taught us something)
  - Add a small lesson entry with the problem, decision, and guardrails.
- **docs/ui/** (if visuals or layout rules changed)
  - Keep the UI spec aligned with the implementation.

## Naming rules
- Prefer ISO dates in filenames: `YYYY-MM-DD`.
- If multiple updates happen in one day, use a letter suffix: `YYYY-MM-DDa`, `YYYY-MM-DDb`.
- Keep one authoritative handoff per day when possible; append to it instead of creating many similar files.

## Where things live
- **app/unitana/**: Flutter app code.
- **docs/ui/**: UI and interaction specs.
- **docs/ai/**: Assistant context, lessons, and handoffs.

## Minimal payload for a new chat
If you want the smallest useful handoff bundle, provide:
- `docs/ai/context_db.json`
- the newest `docs/ai/NEXT_CHAT_HANDOFF_*.md`
- `docs/ai/NEXT_CHAT_PROMPT.md`
- any relevant snippets from `docs/ui/`
