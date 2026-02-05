# AI doc cleanup (P1.23b)

## Deleted
- `docs/ai/prompts/NEXT_CHAT_PROMPT_P1.23zb.md`
- `docs/ai/prompts/NEXT_CHAT_PROMPT_SENIOR_REVIEW.md`

### Rationale
Both were forks/variants of the same “next chat” prompt. Keeping multiple competing prompts has repeatedly taught the next assistant contradictory rules, which increases churn and regression risk. The canonical prompt is now:
- `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Keep (canonical)
- `docs/ai/handoff/CURRENT_HANDOFF.md`
- `docs/ai/context_db.json`
- `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
- `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md`

## Optional future cleanup (not done in this patch)
- Consolidate older retros that cover the same incident into a single “final” retro, and move the rest into `docs/ai/archive/`.
