# Handoff Note — 2025-12-30a (Dashboard + insertion + persistence)

## What changed
- Tapping an empty "+" dashboard cell now **adds a tool tile** (instead of immediately opening the tool modal).
- The inserted tile is **persisted** via SharedPreferences and will reappear on relaunch.
- The top-right dashboard menu now includes **Tools**, which opens the same Tool Picker and inserts a tile into the next available slot.

## How it works (high level)
- New controller: `DashboardLayoutController` persists a list of user-added `DashboardBoardItem`s under the key:
  - `dashboard_layout_v1`
- Board items can optionally include a `DashboardAnchor(index: row * cols + col)`.
  - During placement, anchored items are placed first (best-effort), then the remaining tiles are dense-packed.
  - If the column count changes (2->3), the anchor index is remapped into the new grid (row = index ~/ cols, col = index % cols).

## Stable test keys
- Each "+" tile uses a stable key: `ValueKey('dashboard_add_slot_<row>_<col>')`.
  - Example used in tests: `dashboard_add_slot_4_0`.

## Regression coverage added
- `test/dashboard_tool_insertion_persistence_test.dart`
  - Verifies "+" inserts a tile.
  - Verifies persistence by rebuilding the screen.

## Next follow-ups
- Add replace behavior (tap existing tile in edit mode or long-press) so users can swap tools into a specific slot.
- Decide whether duplicates are allowed long-term (currently allowed for proof-of-flow).
- Consider persisting ordering once rearrange is introduced.
