# PACK K Profile Auto-Suggest Closure Spec (XL-K)

## Goal
Close Pack K by locking deterministic, explainable profile auto-suggest behavior with no surprise switching.

## Behavior Contract
- Feature is explicit opt-in via Settings.
- Suggestions do not auto-switch active profile.
- Explainability reason is always persisted and displayed.
- When location is unavailable/index unavailable/low-confidence, result is deterministic `no suggestion`.
- Tie handling is deterministic and stable.

## Determinism Rules
- Candidate ordering: total score desc -> distance asc -> profile id asc.
- Confidence floor remains enforced (`geoScore < 12` => no suggestion).
- Recency bonus remains bounded and additive only.

## XL-K Validation Added
- Low-confidence far-distance case is locked by regression test.
- Fully tied candidate ordering by profile id is locked by regression test.

## Acceptance Checks
- Existing settings toggle behavior and persistence remain green.
- Existing profile board/profile flow tests remain green.
- New selector edge-case tests remain green.

## Follow-Up
1. Optional reason-code model (instead of raw text) if deeper localization of explainability is needed.
2. Optional confidence band copy tokens exposed directly in settings UI.

