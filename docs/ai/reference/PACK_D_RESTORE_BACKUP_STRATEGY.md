# Pack D Restore + Backup Strategy (Pre-Consolidation Gate)

## Why this exists
Pack D includes consolidation and selective deletion of stale/duplicate docs.  
Before any destructive cleanup, we need a fast, repeatable rollback path.

## Non-negotiable gate before deletions
Do not delete or bulk-move docs unless a restore point is created in the same session.

## Standard restore-point workflow
From repo root:

```bash
./tools/create_restore_point.sh
```

Optional explicit output location:

```bash
./tools/create_restore_point.sh /absolute/path/to/output
```

This produces:
- base commit id
- full git status
- staged + unstaged diffs
- tracked file list
- compressed worktree snapshot (`worktree_snapshot.tgz`)

## Consolidation execution protocol
1. Create restore point.
2. Record intended deletes/moves in a short plan file or PR notes.
3. Execute cleanup in small batches (prefer 1 category at a time).
4. Run gates:
   - `dart format .`
   - `flutter analyze`
   - `flutter test`
5. Spot-check canonical docs:
   - `docs/ai/handoff/CURRENT_HANDOFF.md`
   - `docs/ai/context_db.json`
   - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
6. If mismatch/discrepancy appears, restore from diff/snapshot immediately.

## Rollback options
### Fast rollback (preferred)
- Checkout base commit from `base_commit.txt`.
- Reapply `working_tree.diff` and `staged.diff` as needed.

### Full snapshot restore
- Start from a clean checkout.
- Extract `worktree_snapshot.tgz` on top of repo root.
- Re-run gates.

## Sequencing note
This is a mandatory preflight for Pack D and any future autonomous cleanup pass.
