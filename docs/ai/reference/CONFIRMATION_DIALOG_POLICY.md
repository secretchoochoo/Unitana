# Confirmation Dialog Policy

## Purpose
Keep destructive confirmations visually and behaviorally consistent across Unitana surfaces.

## Policy
- Destructive confirmations must use the bottom-sheet pattern (`showModalBottomSheet`) with drag handle.
- Do not mix AlertDialog for destructive actions on dashboard/profile/tool surfaces.
- Primary action is right-side destructive button (`error` color), secondary action is left-side cancel.
- Copy format:
  - Title: action + target (`Delete profile?`, `Remove Wind widget?`)
  - Body: one-sentence impact statement.

## Safeguard
- Use shared helper:
  - `app/unitana/lib/features/dashboard/widgets/destructive_confirmation_sheet.dart`
- New destructive confirmations should call the helper instead of rolling custom UI.

## Test expectation
- At least one regression test should assert destructive profile/tile confirmation uses bottom sheet and not `AlertDialog`.
