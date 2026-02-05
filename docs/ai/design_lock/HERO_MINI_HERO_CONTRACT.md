# HERO + MINI-HERO DESIGN CONTRACT (LOCKED)

## Scope
This contract governs:
- **PlacesHeroV2** (expanded dashboard hero)
- **Pinned mini-hero readout** (collapsed header readout during scroll)
- **Wizard previews** of both hero states

This contract exists to prevent UI regressions and test brittleness as the collapsing header morphs between layers.

## Non-negotiables
1) **No pop-in header behavior**
- The dashboard header must remain a continuous morphing `SliverPersistentHeader`.
- Do not reintroduce threshold-based insertion or any layout that visibly “jumps” during scroll.

2) **Canonical hero test keys must be unique**
- Canonical hero keys must never exist twice in the widget tree at the same time.
- Only the dashboard surface is allowed to emit canonical keys used by widget tests.

3) **Preview surfaces must not emit canonical keys**
- Wizard previews, profile preview cards, and any other non-dashboard surfaces must set:
  - `includeTestKeys: false`

4) **Dracula discipline**
- Most text is white.
- Accent colors are restrained and consistent with the Dracula palette.
- Avoid rainbow text; prefer subtle accents (icons, small highlights, labels).

## Key invariants (tests depend on these)
### PlacesHeroV2 key policy
- Add/keep a single bool: `includeTestKeys`.
- When `includeTestKeys == true`, the widget emits canonical keys used by dashboard tests.
- When `includeTestKeys == false`, the widget must emit **no canonical dashboard keys**.

### Mini-hero readout key policy
- The pinned/collapsed layer must not reuse expanded hero canonical keys.
- If keys are required for internal testing, they must live under a dedicated namespace, for example:
  - `mini_*` or `pinned_*`

### Environment pill key policy
- The dashboard should expose **one** canonical env pill key on the dashboard surface.
- Do not render multiple env pills with the same key (for example, one per place) on the same surface.

## Layout invariants
### Expanded hero vs pinned mini readout
- Expanded hero occupies the expanded header area.
- Collapsed mini readout is pinned; it remains legible and does not overlap tappable dashboard content.

### AQI/Pollen pill swap icon alignment
- Swap icon must be **right-aligned** within the pill.
- Do not center-align the swap icon; it reads as “floating” and reduces affordance.

### “Updated … ↻” cluster alignment (dashboard)
- “Updated …” text and the refresh icon must sit close together (tight spacing).
- The cluster must be centered beneath the profile name (visually aligned with the name above).

## Wizard invariants (critical)
### Step 2: Pick Your Places
- Must fit on one phone screen with **no scrolling**.
- Unit system + clock format controls must remain compact:
  - Row 1: **Metric / Imperial**
  - Row 2: **12-Hour / 24-Hour**
- The mini-hero preview should remain visible on the same screen.

### Step 3: Name and Confirm
- Title: **Name and Confirm**
- The UI must not show duplicated toggle rows:
  - Remove any extra “mini hero toggle” row above the hero preview.
  - The hero preview already owns its toggle behavior.

## Change control
Any change that affects:
- hero layout (expanded or collapsed),
- key emission policy,
- wizard step layouts,
- dashboard header morph behavior,

must include:
1) A note in `docs/ai/context_db.json` (patch_log entry + decision, if applicable).
2) If visuals change, a deliberate golden update (do not update blindly).
3) Confirmation that canonical keys remain unique across the collapsing transition.

## Where to update docs
- `docs/ai/handoff/CURRENT_HANDOFF.md`
- `docs/ai/context_db.json`
- `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md` (this file)
