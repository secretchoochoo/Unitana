# Pack F Scope Follow-ups: Jet Lag Delta, Weight/Body Weight, Height Imperial Input

## Purpose
Capture scoped follow-up contracts discovered during activation work so they are not lost behind implementation velocity.

## 1) Jet Lag Delta unique purpose

### Current state
- `jet_lag_delta` is now a dedicated surface with a lightweight planner card.
- It still shares Time-family timezone selectors/clocks under the hood.

### Product gap
- Travel users need an explicit "planning delta" tool:
  - destination offset awareness
  - suggested adjustment windows
  - sleep/meeting-friendly conversion guidance

### Scope contract (next design slice)
1. Keep `Time` as general clocks/conversion.
2. Add a dedicated `Jet Lag Delta` mode/surface with:
   - "departing from" + "arriving to" zone intent
   - simple hour-difference framing
   - optional "best call windows" block.
3. Keep dedicated mode and iterate planner depth without regressing Time core behavior.

## 2) Weight vs Body Weight semantics

### Current state
- `body_weight` aliases `weight` (same conversion engine).
- `weight` is attached to Food/Cooking lens; `body_weight` is Health/Fitness.
- Defaults currently remain generic kg/lb conversion defaults.

### Product gap
- Users perceive Body Weight as distinct from cooking weight.
- Lens context should influence defaults and copy more strongly.

### Scope contract (next design slice)
1. Keep one canonical conversion engine.
2. Strengthen `body_weight` preset behavior:
   - default copy and examples focus on personal weight.
   - default direction follows locale preference and common health logging conventions.
3. Keep `weight` cooking-centric with ingredient/package framing.

## 3) Height imperial input UX

### Current state
- Converter accepts rich text forms (`5'10"`, `5 10`, `5ft 10in`).
- Users still enter shorthand decimals (`6.4`) and expect `6 ft 4 in`.

### Current mitigation (shipped)
- Added parser support: `6.4` / `6,4` interpreted as `6 ft 4 in` when inches <= 11.

### Remaining design gap
- Single text field remains ambiguous and not self-evident.

### Scope contract (next design slice)
1. When `ft/in -> cm` is active for Height, offer dedicated dual inputs:
   - `ft` field
   - `in` field
2. Keep the layout aligned with existing modal rhythm:
   - same input container width and vertical spacing tokens
   - no bespoke spacing primitives.
3. Keep text parser as fallback for history edits and pasted values.

## Sequencing recommendation
1. Jet Lag Delta dedicated mode contract
2. Height dual-field UI contract + implementation
3. Body Weight preset differentiation pass
