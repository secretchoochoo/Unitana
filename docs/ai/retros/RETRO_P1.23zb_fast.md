# Fast Retro: P1.23zb (Stabilization)

## What broke
- **Hero data looked "dead"**: weather/temp/sunrise/pollen reverted to placeholders (`--°C`, `--:--`), even though the app still rendered.
- **Pinned mini-hero disappeared**: the condensed "terminal" readout did not reliably show when scrolling.
- **Build churn**: repeated patch cycles accumulated small regressions (layout and refresh behavior) without a single, stable source-of-truth.

## Probable causes
- **No initial live-data refresh**: the live-data controller was not being refreshed on launch in mock mode, so the UI had no snapshots to render.
- **Pinned visibility trigger too strict**: the scroll threshold required more scroll than the typical user gesture; it felt like the pinned cockpit regressed.
- **High coupling without guardrails**: hero UX lives across multiple widgets (board, screen overlays, live-data controller). Without golden tests, small changes looked "safe" but altered behavior.

## What we changed (this patch)
- Trigger a **first-frame refresh** (`_refreshAllNow`) so the hero never boots into placeholder values.
- Add a **manual refresh control** next to the refresh status label; label is also tappable.
- Make the refresh status label **visibly stale** (orange) when aged.
- Loosen the pinned overlay scroll threshold so the mini-hero **reappears predictably**.
- Improve the clock block: **time line** and **date line** separated; date separator changed from `/` to `•`.
- Increase currency pill primary text sizing while keeping **FittedBox(scaleDown)** safety.

## Guardrails to add next
1. Golden tests/screenshots for:
   - PlacesHeroV2 at multiple widths
   - Pinned cockpit row visible state
2. A widget test that asserts **refreshAll runs once** on first frame (mock backend) and produces non-placeholder values.
3. A single UX contract doc for the hero + pinned cockpit that lists:
   - which line shows what
   - color accents allowed
   - scroll trigger behavior
