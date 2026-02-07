# Tool Action Row Alignment Policy

## Purpose
Keep action controls visually consistent across tool modals and prevent drift as new dedicated tool surfaces are added.

## Contract
1. Tool action controls that affect the current card context (for example `Swap`, `+ Add Widget`) should share a single horizontal action row.
2. Default alignment is trailing (`end`) to preserve scan order from configuration card -> actions -> result cards.
3. Action row spacing:
   - horizontal gap: 8dp
   - vertical separation from preceding block: 10dp
4. Use the same outlined button family unless a tool has a clear primary destructive/commit action.
5. Do not stack context actions into separate rows unless width constraints force wrap behavior.

## Time-family adoption
- `Time`, `Jet Lag Delta`, and `Time Zone Converter` now use a single action row with `Swap` and optional `+ Add Widget`.
