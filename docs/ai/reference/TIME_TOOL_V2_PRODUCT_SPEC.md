# Time Tool V2 Product Spec (Draft)

## Product goal
Make Time a travel decision tool, not a numeric converter.

## Core jobs
1) See current time in two places quickly.
2) Understand offset delta immediately.
3) Swap comparison direction fast.
4) Pick different zones when needed.

## Non-goals (for now)
- generic `12h <-> 24h` conversion form
- copy/paste converter history
- dense planner workflows until visual design is locked

## Required UI blocks
1) Zone selector block
- `From time zone`
- `To time zone`
- `Swap`

2) Current time block
- both zones shown side-by-side in one block
- 12h and 24h both visible
- clear UTC offset labels
- signed delta label

3) Optional add-widget action
- keep secondary and unobtrusive

## UX constraints
- no ambiguous labels (`Planner` removed until defined with explicit task wording)
- no controls that require user guessing “what this does”
- no converter-style history in Time mode

## Follow-up phase (after design sprint)
- add “meeting overlap” track only if visually/operationally clear
- consider map/timeline view as separate sub-mode (not mixed into base mode)
