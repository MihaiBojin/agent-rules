## Git and worktrees

Commit and push only when I ask. Before edits or development commands, run `git worktree list`. Use this task's linked
worktree and branch, one per writer. New task branches start at the fetched default tip. Never share another agent's
checkout or use main. Keep the main worktree clean on the default branch; fetch and fast-forward it at task start
and after merges. Stop on failed sync and report it; never stash or discard work. Build and test in linked worktrees.
Release preparation and fixes use linked worktrees and PRs. Main is for sync and publishing verified merged releases;
serialize main updates and releases. Tag the exact verified commit. Other release lines use linked worktrees.
Preserve other agents' branches and worktrees. If isolation fails, stop before editing.

Keep agent trailers: `Co-Authored-By: Claude` and harness `<tool>-Session:`. Keep GitHub's squash-subject `(#NN)`.
Commits use `commit.gpgsign=true` and the configured key; never hardcode one. GitHub squash merges use its web-flow key:
I stay the author, `GitHub <noreply@github.com>` is the committer, and Verified is normal. Do not bypass it or offer to.
