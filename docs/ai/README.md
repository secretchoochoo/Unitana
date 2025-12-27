# AI docs

This folder exists to make AI-assisted development reliable.

## What lives here

- `context_db.json`: Stable facts and decisions that should survive across chats.
- `NEXT_CHAT_PROMPT.md`: The prompt to start a new chat with the right team and rules.
- `NEXT_CHAT_HANDOFF_*.md`: Snapshot handoffs capturing the latest state.
- `WORKING_WITH_CHATGPT.md`: Workflow rules for making safe changes and reducing churn.
- `RETRO_*.md`: Postmortems and retros.
- `CLEANUP_HARDENING_PLAN_*.md`: Sustaining engineering plans and checklists.

## Updating `context_db.json`

Add a new entry under `slices` for each slice that ships. Keep it short:
- what changed
- paths touched
- verification commands run

The goal is rapid onboarding, not an exhaustive log.
