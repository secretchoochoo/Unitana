# Multi-unit conversion UX contract

## Goal
Support tools that have more than one reasonable unit pair (volume, length, weight, pressure, temperature variants, etc.) without turning every modal into a noisy “From/To” form.

The user should be able to:

1. Enter a value once.
2. Choose input and output units quickly.
3. See the primary conversion immediately.
4. Optionally view additional units without cluttering the primary modal.

Non-goals:

- Building a generic spreadsheet UI.
- Introducing per-tool bespoke selectors.
- Expanding public widget APIs.

## Canonical interaction model

### Primary modal stays “one thought wide”
The default modal shows only what most users need most of the time:

- **Enter value** field
- **Primary result** (single conversion)
- **Units row** (input unit pill, swap, output unit pill)
- **History**

Everything else is optional and off the critical path.

### Unit selection uses pills
For any multi-unit tool, unit selection is represented as pills:

- Left pill: **input unit**
- Right pill: **output unit**

Tapping a pill opens a compact selector.

### Swap is a dedicated affordance
Swap is always available, always in the same place:

- A swap icon/button between the pills (or aligned to the right edge of the units row if the tool’s layout requires it).

Swap swaps the meaning of the pills and recomputes results. It must not rewrite the user’s typed value.

## Selector contract

### Compact selector (preferred)
Selecting units should feel like changing a setting, not filling a form.

Open behavior:

- Tapping either unit pill opens a **compact selector sheet**.
- The sheet highlights the current selection.

Display rules:

- If units ≤ ~12: use a simple grid/list with large tap targets.
- If units are many: use a searchable list.

Close behavior:

- Selecting a unit closes the sheet immediately and recomputes results.
- Outside-tap dismissal is allowed (unless the tool has unsaved state beyond the input field).

### “More units” sub-sheet (for extra outputs)
Secondary outputs must not bloat the primary modal.

If the tool supports many “nice to have” conversions, expose them behind:

- A single row/button: **More units…**
- This opens a sub-sheet showing additional computed outputs.

The primary conversion remains the “default answer.”

## Result + history contract

### What tap and long-press mean
History interaction must be consistent across tools:

- **Tap a history row**: copies the *result* for that row to clipboard.
- **Long-press a history row**: copies the *input expression* (value + unit) to clipboard.

Tests should assert copy behavior via the Clipboard channel, not transient notice UI.

### Persistence expectations
For multi-unit tools, persist:

- last input unit
- last output unit

Persistence keying rules:

- Keys are stable and based on tool id + unit id (not display strings).
- If a unit is removed/renamed, fall back to a default unit pair.

## Implementation guidance (guardrails)

- Keep conversion logic unit-graph driven internally (add units without UI redesign).
- UI should not introduce per-tool bespoke “From/To” labels.
- Do not add public widget API parameters unless unavoidable; prefer internal composition.
- Use stable Keys for:
  - modal scroll root
  - unit pills
  - swap control
  - history list

## Decision
We prefer:

1. **Units pill that opens a compact selector** (default).
2. **More units sub-sheet** only when extra outputs matter.

This keeps the modal clean while still supporting power users.
