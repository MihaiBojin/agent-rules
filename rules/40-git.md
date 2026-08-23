<!-- prose-check: skip -->
## Git history

Agent trailers are fine. `Co-Authored-By: Claude` and `<tool>-Session:` both
stay when the harness adds them.

Local commits are GPG-signed already (`commit.gpgsign=true`). Which key is git
config's business and differs by machine, so never hardcode a key id. A
squash-merge performed by GitHub is signed by GitHub's own web-flow key, not
mine: the author stays me, the committer becomes `GitHub <noreply@github.com>`,
and the commit shows as Verified. That is expected. Do not route around it, and
do not offer to.

`(#NN)` in a squash-merge subject is GitHub's, and is fine. Do not strip it.

Branch before committing if I am on the default branch. Commit and push only
when I ask.
