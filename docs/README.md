# Docs index

This folder is the project knowledge base. It is organized so a new engineer can find the right document in under 2 minutes.

## Structure

- `architecture/`: System design, diagrams, and key data flows.
- `adr/`: Architecture Decision Records (why we chose X instead of Y).
- `decisions/`: Product and UI decisions that are not full ADRs.
- `context/`: High-level project context exports used for handoffs.
- `ai/`: AI workflow, prompts, lessons learned, retros, and the context database used to start new chats.
- `postmortems/`: Structured retrospectives after incidents or major refactors.
- `incidents/`: Incident logs and timelines.

## Start here

- `../README.md` (repo overview)
- `ai/NEXT_CHAT_PROMPT.md` (continuation prompt)
- `ai/context_db.json` (stable context database)
- `testing.md` (how to run and write regression tests)

## Revision history convention

Prefer a small revision block at the bottom of docs that are expected to change.

See `docs/ai/REVISION_HISTORY_CONVENTION.md`.
