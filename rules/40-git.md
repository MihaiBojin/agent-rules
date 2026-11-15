## Git and releases

Prepare releases in linked worktrees from the fetched configured branch, through pull requests. The main checkout is for
sync and for publishing verified merged releases; serialize main updates and releases. Tag the verified commit. Preserve
other agents' branches and worktrees.

Keep agent trailers: `Co-Authored-By: Claude` and harness `<tool>-Session:`. Keep GitHub's squash-subject `(#NN)`.
Commits use `commit.gpgsign=true` and the configured key; never hardcode one. GitHub squash merges use its web-flow key:
I stay the author, `GitHub <noreply@github.com>` is the committer, and Verified is normal. Do not bypass it or offer to.
