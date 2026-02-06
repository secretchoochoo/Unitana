NEXT CHAT PROMPT — Pack B/C Hardening + Pack F Activation Continuation

You are taking over Unitana (Flutter) in a new context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md`
4) `docs/ai/design_lock/CITY_DATA_SCHEMA_CONTRACT.md`

Then execute using this contract.

## Core operating rules
- Keep repo green continuously:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Work directly in-repo (Codex-first); no patch zip workflow unless explicitly requested.
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph (no threshold pop-in)
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens are opt-in only; never blindly update

## Current reality (already landed)
- Pack A is complete (canonical city schema + full required field coverage + validators/contracts).
- Pack B has fallback hardening in place (no blank critical weather/env states under provider failure).
- Pack C has global currency pair mapping/rate wiring in place (hero/mini/tool), with bidi/symbol placement fixes.
- Profile UX phase 1 + parity passes landed:
  - dedicated Profiles board
  - switch/add/edit/delete/reorder behaviors
  - startup recovery when active profile is incomplete
  - dashboard/profile edit-mode UI parity improvements (centered icon rows, spacing fixes).

## Mission
Continue P0/P1 execution with this order:

### Pack B (P0): Live weather/time/AQI/pollen end-to-end hardening
Goal:
- Every in-scope city resolves weather/time/AQI/pollen reliably under success and failure paths.

Required outputs:
- explicit retry/staleness semantics for provider outages
- broader representative global-city coverage tests
- deterministic fallback behavior remains intact (no blank critical states)

### Pack C (P0): Live currency conversion global hardening
Goal:
- Currency conversion remains correct/reliable across global city pairs under outage/cache edge cases.

Required outputs:
- stale-rate/retry/cache invariants covered by tests
- formatting consistency for mixed-script/suffix-prefix currencies
- verification for high-variance pairs and directionality edge cases

### Pack F (P1): Tools surface completion and coming-soon reduction
Goal:
- Move from audit to activation: reduce disabled tools while preserving UX consistency.

Required outputs:
- audited disabled-tools table (keep/merge/remove with rationale)
- at least one high-value activation bundle implemented E2E (modal + tile + tests), unless blocked
- explicit deferral notes for remaining disabled tools

### Pack H (P1): Localization epic bootstrap
Goal:
- Establish language selection + i18n foundations so localization can progress in parallel.

Required outputs:
- Settings language selector scaffold (system + explicit language)
- localization pipeline bootstrap plan and first coverage slice

## Priority and sequencing
- Execute Pack B/C completion before polish/compliance work.
- Keep Pack F active in parallel (do not claim tools completion while disabled entries remain).
- Keep Pack H tracked as active P1 and avoid deferring it indefinitely.
- Radio remains Icebox unless explicitly reprioritized.

## Deliverables per pack
1) What changed and why (short)
2) Gate results (`format/analyze/test`)
3) Regression safeguards added (tests/contracts)
4) Docs updated:
   - `docs/ai/context_db.json`
   - `docs/ai/handoff/CURRENT_HANDOFF.md`
   - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (if execution plan changes)

## First action in new chat
- Audit current Pack B/C residual risk from tests and code paths (retry/stale/cache/outage semantics).
- Audit disabled tools in `tool_registry.dart` and propose the smallest high-value activation bundle.
- Produce a concrete implementation plan and begin coding in the same session unless blocked.
