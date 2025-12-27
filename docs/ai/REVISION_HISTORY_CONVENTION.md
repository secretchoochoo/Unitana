# Revision history convention

Goal: keep docs readable while still tracking change over time.

## When to include revision history

Add a small revision block when a document will change over time, for example runbooks, onboarding docs, workflow guides, and architecture notes.

You can skip it for one-off snapshots (for example a dated retro) where the filename already captures time.

## Format

Place this at the bottom of the document:

```
## Revision history
- YYYY-MM-DD | <name or team> | <1 line summary>
```

## Guidance

- Keep it short. One line per change.
- Prefer facts over feelings.
- If a change is large, link to the PR or slice id.

Example:

```
## Revision history
- 2025-12-27 | Unitana team | Added context_db.json and slice template.
```
