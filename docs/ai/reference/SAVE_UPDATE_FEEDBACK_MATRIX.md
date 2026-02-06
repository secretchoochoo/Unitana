# Save/Update Feedback Matrix

## Goal
Standardize save/update feedback behavior across dashboard, profiles, wizard, tools, and settings.

## Feedback policy
- Mutation that commits user-visible state should emit immediate success feedback.
- Use `UnitanaToast.showSuccess` for short confirmations.
- Keep copy short and surface-specific (`Dashboard updated`, `Profiles updated`).
- Destructive confirmations use the shared bottom-sheet policy in `CONFIRMATION_DIALOG_POLICY.md`.
- If a flow navigates away on success, toast should still appear on the destination surface when possible.

## Matrix
| Surface | User action | Current behavior | Target behavior | Status |
|---|---|---|---|---|
| Dashboard edit mode | Tap `Done` | `Dashboard updated` toast | Keep | Aligned |
| Dashboard reset defaults | Confirm reset | `Dashboard reset to defaults.` toast | Keep | Aligned |
| Dashboard tile remove | Confirm remove | `Tile removed from dashboard.` toast | Keep | Aligned |
| Profiles board edit mode | Tap `Done` | `Profiles updated` toast | Keep | Aligned |
| Profiles delete | Confirm delete | No success toast | Add `Profile deleted` toast | Gap |
| Profile add + save wizard | Complete creation | Implicit via navigation | Add explicit `Profile created` toast | Gap |
| Profile edit + save wizard | Complete edit | Implicit via navigation | Add explicit `Profile updated` toast | Gap |
| First-run create profile | Complete slide 3 | Implicit via navigation | Add explicit `Profile created` toast | Gap |
| Tool convert action | Tap `Convert` | Result panel updates, no toast | Keep no toast | Intentional |
| Tool add widget | Tap `+ Add Widget` | Success toast in board flow | Keep | Aligned |
| Tool clear history | Confirm clear | No success toast | Add `History cleared` toast | Gap |
| Settings mutation (future language/theme) | Save setting | Varies / TBD | Standard success toast per setting group | Planned |

## Copy contract
- Success:
  - `Dashboard updated`
  - `Profiles updated`
  - `Profile created`
  - `Profile updated`
  - `Profile deleted`
  - `History cleared`
- Error:
  - Keep current explicit error toasts (do not silently fail).

## Test safeguards
- Add/keep widget tests that assert toast presence for:
  - dashboard done/reset/remove
  - profiles done
  - profile create/edit/delete completion
  - tool history clear

## Rollout order
1) Close profile create/edit/delete success feedback gaps.
2) Close tool history clear success feedback gap.
3) Add a small utility/wrapper (optional) to avoid message drift.
