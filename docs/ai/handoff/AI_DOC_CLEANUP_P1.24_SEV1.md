# AI Doc Cleanup Note (P1.24)

## Goal
Reduce prompt and contract drift by keeping a single canonical source for future handoffs.

## Quarantined forks
- `docs/ai/handoff/NEXT_CHAT_PROMPT_P1.23zb.md`
  - Rationale: this is a historical snapshot that conflicts with the canonical prompt. It is now explicitly marked DEPRECATED and should not be edited.
  - Canonical replacement: `docs/ai/prompts/NEXT_CHAT_PROMPT.md`.

## Notes
- No files were deleted in this patch, since the patch workflow uses file sync. Deletions should be done in-repo only when the team is ready to enforce them with a git commit.