## Git history

Branch before committing if I am on the default branch. Commit and push only
when I ask.

Agent trailers stay: `Co-Authored-By: Claude` and `<tool>-Session:` when the
harness adds them. `(#NN)` in a squash-merge subject is GitHub's; leave it.

Commits are signed by whatever key git config names (`commit.gpgsign=true`), so
never hardcode a key id. A GitHub squash-merge is signed by GitHub's web-flow
key: the author stays me, the committer becomes `GitHub <noreply@github.com>`,
and the commit shows as Verified. Expected. Do not route around it, and do not
offer to.
