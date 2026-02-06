Unitana restore point
=====================

Timestamp: 20260205-213448
Repo root: /Users/codypritchard/unitana
Base commit: 7a94d80f411223043d7cb469572227789d66b4ad

Artifacts:
- base_commit.txt
- status_short.txt
- status_full.txt
- working_tree.diff
- staged.diff
- tracked_files.txt
- worktree_snapshot.tgz

Restore quick path:
1) checkout base commit
2) reapply working_tree.diff and staged.diff as needed
3) if needed, extract worktree_snapshot.tgz into a clean checkout
