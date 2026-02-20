# XL Tutorial Slice Spec (Chalkboard Overlay) - 2026-02-20

## Goal
Ship a playful, clear, ELI12 in-app tutorial system that:
- Teaches navigation and core interactions on first visit to each major surface.
- Uses an illustrated chalkboard vibe (not a sterile tooltip style).
- Can be replayed from settings.
- Keeps copy short and actionable.

## Visual Direction
- Typography: use `Single Day` for headings/accent words; keep body text on readable system/body font for accessibility.
- Theme: chalkboard overlay panel, hand-drawn arrows, friendly icon callouts.
- Motion: slide-in card + spotlight pulse only (no heavy animation).
- Readability rules:
  - Max 1-2 sentences per slide.
  - One action verb per slide: "Tap", "Swipe", "Long-press".
  - Always show a "Skip" and "Got it" path.

## Runtime Model
- New controller: `TutorialOverlayController` (session state + step sequencing).
- New registry: `TutorialScriptRegistry` (per-surface step scripts + target keys).
- New widget: `TutorialSpotlightOverlay` (spotlight cutout, chalk card, arrow).

## Persistence
Use per-surface completion, not one global dismissed flag.
- `tutorial.surface.dashboard.completed`
- `tutorial.surface.wizard.completed`
- `tutorial.surface.profiles.completed`
- `tutorial.surface.editMode.completed`
- `tutorial.surface.toolModal.completed`

Replay controls:
- `Reset tutorials` action in Settings.
- Optional `Replay tutorial` action on each major surface.

## Surface Map (Scanned Interactive Inventory)

### 1) First-run wizard
Primary targets:
- Step dots/tabs: `first_run_step_welcome`, `first_run_step_places`, `first_run_step_confirm`
- Navigation: `first_run_nav_prev`, `first_run_nav_next`, `first_run_finish_button`
- City pickers: `first_run_home_city_button`, `first_run_dest_city_button`
- Unit/clock pills on places step
- Preview toggle: `first_run_preview_reality_toggle`
- Profile name field: `first_run_profile_name_field`

Suggested slides:
1. "Welcome" - how to move between steps.
2. "Pick your cities" - home + destination city picker behavior.
3. "Units and clock" - metric/imperial + 12/24h.
4. "Live preview" - what changes in preview when toggling reality.
5. "Finish" - save and continue.

### 2) Dashboard (normal mode)
Primary targets:
- Tools launcher: `dashboard_tools_button`
- Menu/settings launcher: `dashboard_menu_button`
- Pull to refresh area: `dashboard_pull_to_refresh`
- Hero reality toggle: `places_hero_segment_home`, `places_hero_segment_destination`
- Hero env pill toggle: `hero_env_pill`
- Hero details pill toggle: `hero_sun_pill`
- Widget tiles and "+" slots (`dashboard_add_slot_*`)

Suggested slides:
1. "Top controls" - tools vs menu.
2. "Reality toggle" - switch Home/Destination context.
3. "Hero cards" - tap pills to cycle details.
4. "Widgets" - tap to open, long-press in edit mode.
5. "Scroll and refresh" - vertical browsing and pull-to-refresh.

### 3) Dashboard edit mode
Primary targets:
- Enter edit mode: `dashboard_edit_mode`
- Exit controls: `dashboard_edit_done`, `dashboard_edit_cancel`
- Long-press drag tile (whole tile)
- Tile edit/delete action icons
- Empty slot drag targets

Suggested slides:
1. "Long-press to drag".
2. "Drop on tile to swap".
3. "Drop on + slot to place exactly there".
4. "Edit/remove icons".
5. "Done saves layout".

### 4) Profiles board
Primary targets:
- Mode controls: `profiles_board_edit_mode`, `profiles_board_edit_done`, `profiles_board_edit_cancel`
- Tiles: `profiles_board_tile_*`
- Add slots: `profiles_board_add_profile*`
- Drag targets: `profiles_board_target_*`

Suggested slides:
1. "Tap profile to switch".
2. "Add profile with + slots".
3. "In edit mode, long-press tile to reorder".
4. "Edit/delete profile actions".

### 5) Tool picker + tool modals
Primary targets:
- Search: `toolpicker_search`
- Close: `toolpicker_close`
- Tool rows: `toolpicker_tool_*`
- Tool modal close and unit pickers

Suggested slides:
1. "Search tools quickly".
2. "Pick units/currency before converting".
3. "Read result + history actions".

## Unit Price Tutorial (special script)
Include a dedicated mini-walkthrough because this is confusion-prone.
- Slide A: Price field.
- Slide B: Units field + unit selector.
- Slide C: Compare toggle (adds Product B).
- Slide D: Result block (100g/1kg or 100mL/1L lines, two-currency context).

## City Picker UX Note (performance + accidental second tap)
Observed issue: first open can feel delayed, causing double-tap mistakes.
Mitigation implemented in this prep:
- Non-blocking index build for large datasets in `CityPicker`.
- Immediate lightweight fallback list while index warms.
- Wizard city buttons are temporarily disabled while picker is opening.

## Accessibility + UX Acceptance
- Body copy at or above readable contrast in both themes.
- Spotlight never hides primary CTA without alternative keyboard/back path.
- VoiceOver/TalkBack reads step title + action text in order.
- User can skip tutorial at any step.

## Implementation Phasing
1. Framework: overlay + spotlight + script registry + persistence keys.
2. Wizard script (highest onboarding impact).
3. Dashboard normal + edit scripts.
4. Profiles board script.
5. Tool-picker + Unit Price targeted script.
6. Settings replay/reset controls + analytics hooks.

## Success Metrics
- Reduced early-session mis-taps in wizard city selection.
- Higher completion rate of first-run flow.
- Fewer support questions around dashboard navigation and edit mode.
