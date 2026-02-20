# XL-W: Documentation Realignment + Performance/Hardening Plan

## Purpose
Run a major documentation and code-quality pass now that the product has advanced beyond early MVP docs and initial wireframes.

## Repo Scan Snapshot (2026-02-19)
- Dart source files: `67`
- Test files: `122`
- Approximate Dart LOC: `35,247`
- Largest hotspots:
  - `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart` (`8,123` LOC)
  - `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart` (`2,328` LOC)
  - `app/unitana/lib/features/dashboard/dashboard_screen.dart` (`2,169` LOC)
  - `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart` (`2,138` LOC)
  - `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart` (`2,129` LOC)
  - `app/unitana/lib/features/dashboard/models/dashboard_copy.dart` (`1,786` LOC)

## Drift Found During Scan
- Entry docs were stale or pointed to missing files:
  - root `README.md` referenced non-existent `docs/ai/WORKING_WITH_CHATGPT.md`
  - `docs/README.md` referenced non-existent `docs/ai/NEXT_CHAT_PROMPT.md`
  - `app/unitana/README.md` remained Flutter template boilerplate
- Product docs likely behind current runtime:
  - `docs/00-mvp-truth.md`
  - `docs/01-flows.md`
  - `docs/02-wireframes.md`
  - `docs/03-ux-package.md`

## Phase Plan

### Phase 1: Canonical Docs Realignment (XL)
Goal: make docs truthful and navigable for current shipped behavior.

Work:
- Rewrite the four top-level product docs (`00-03`) against current runtime.
- Ensure all docs link to existing files only.
- Add explicit superseded banners where needed instead of silent drift.
- Align terminology across:
  - Dashboard hero + weather cockpit
  - Tool surfaces (convertor vs lookup/matrix vs dedicated tool)
  - Profiles and first-run wizard behavior
  - Settings/Developer Tools/public-build gating

Acceptance:
- No broken links in `README.md`, `docs/README.md`, and `docs/00-03`.
- `docs/00-mvp-truth.md` matches current default tile/tool strategy and runtime contracts.
- `docs/02-wireframes.md` reflects current implemented flows, not placeholders.

### Phase 2: Docs IA Hardening (XL)
Goal: prevent drift recurrence.

Work:
- Add owner + source-of-truth headers to high-churn docs.
- Add “last validated against code” date in key docs.
- Add lightweight docs verification script for:
  - dead relative links
  - references to missing files
  - duplicate canonical claims between docs

Acceptance:
- Docs verify command is runnable in CI/local.
- Reference index clearly maps canonical vs supporting vs archival docs.

### Phase 3: Performance Tuning and Code Hardening (XL)
Goal: reduce technical risk and improve maintainability/perf before public-release branch split.

Scope:
- File-level decomposition targets:
  - `tool_modal_bottom_sheet.dart`
  - `places_hero_v2.dart`
  - `dashboard_screen.dart`
  - `dashboard_board.dart`
  - `dashboard_live_data.dart`
- Comment hygiene:
  - remove stale comments
  - convert ambiguous comments into concrete contract comments
- Perf instrumentation/hot-path audit:
  - dashboard rebuild boundaries
  - weather/hero update churn
  - modal matrix/table rendering cost
- Reliability hardening:
  - network fallback transparency
  - stale/retry semantics consistency
  - deterministic test coverage for high-risk flows

Acceptance:
- `dart format .`, `flutter analyze`, `flutter test` stay green after each slice.
- Hotspot files reduced in size and/or split by clear domain boundaries.
- No stale comment findings in targeted files after pass.
- Perf budget checks documented and repeatable.

## Proposed Slice Breakdown
- XL-W1: Rewrite `docs/00-mvp-truth.md` and `docs/01-flows.md` from current code.
- XL-W2: Rewrite `docs/02-wireframes.md` and `docs/03-ux-package.md`; mark superseded sections.
- XL-W3: Add docs verification tooling + ownership headers + dead-link checks.
- XL-W4: Hardening pass A (dashboard + hero boundaries).
- XL-W5: Hardening pass B (tool modal decomposition + matrix rendering contracts).
- XL-W6: Hardening pass C (comment hygiene + perf validation + final cleanup).

## Non-Goals
- No feature redesign inside docs-only slices.
- No public-release branch split implementation in this phase (planning can happen in parallel).

## Quality Gates (per slice)
- `dart format .`
- `flutter analyze`
- `flutter test`
- docs verification script (when added in XL-W3)
