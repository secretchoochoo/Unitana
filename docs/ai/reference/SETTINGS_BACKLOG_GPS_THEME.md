# Settings Backlog: GPS Auto-Profile + Light Theme

## 1) Optional GPS-Assisted Profile Auto-Selection

### Goal
Reduce manual profile switching by suggesting/selecting the most context-relevant profile.

### Corrected decision logic
1. User must explicitly enable this in Settings.
2. Build candidate score per profile:
   - `destination_match_score` (highest weight)
   - `home_match_score` (secondary)
   - `recency_score` (tie-break influence, not primary)
3. If best candidate score is above confidence threshold, switch/suggest that profile.
4. If confidence is low/ambiguous, do not switch silently:
   - keep current profile, or
   - prompt with a one-tap suggestion.
5. Fallback only when no usable geo signal:
   - most recently used profile.

### Why this is better than strict boolean chaining
- Avoids brittle `A and B or C` behavior when location is stale/noisy.
- Prevents accidental switches near borders or dense multi-city regions.
- Preserves user trust with confidence gating and explainability.

### Settings surface (future)
- `Auto-select profile by location` toggle
- `Switch behavior`: `Auto`, `Suggest`, `Off`
- Optional diagnostics text: `Last auto-selection reason`

## 2) Light Theme (Solarized-inspired) with Dracula parity

### Goal
Add a first-class light mode without breaking visual hierarchy or accessibility.

### Direction
- Keep existing Dracula dark theme.
- Add Solarized-light-inspired theme token map in parallel.
- Theme options in Settings:
  - `System`
  - `Dark (Dracula)`
  - `Light (Solarized)`

### Implementation policy
- Map semantic roles, not raw colors:
  - surface/background
  - on-surface typography roles
  - borders/dividers
  - accent/success/warning/error
- Preserve marquee art direction where possible, but enforce contrast for all text/UI chrome.
- Add targeted cross-theme golden/screenshot coverage for hero, tool tile, and tool modal.
