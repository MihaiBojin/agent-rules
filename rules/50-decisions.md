<!-- prose-check: skip -->
## Decision log

A decision that is not quick and easy gets a file:
`.claude/decisions/<unix-timestamp>-<slug>.md`, committed with the work it
belongs to. Ask for one at any point and I write it however small it looks.

`**/.claude/` is excluded in `~/.config/git/ignore`, so the first decision file
in a repo also puts this in that repo's `.gitignore`:

```gitignore
# .claude/ is ignored globally; decisions are the exception
!.claude/
.claude/*
!.claude/decisions/
```

Order matters. Git will not re-include a path whose parent directory is
excluded, so `.claude/` has to come back before `.claude/decisions/` can. The
rest of `.claude/` stays ignored.

The file is the only place the history lives. Answers, commit bodies, PR
descriptions, READMEs and code comments say what is true now and point at the
file instead of retelling how we got there.

One file per topic, however many decisions the topic takes:

```markdown
# Which git binary the installer uses

Topic: the installer has to pick a git binary and the choice keeps coming back
Status: decided 2026-09-07
Opened: 2026-09-07

## 2026-09-07

q: Which git should we use: system, brew, user specified
a: use system git, cache the binary location for a day
why: brew git moves with the machine, system git does not
alt: git from $PATH on every call — 700ms of extra runtime
alt: a configured path — one more thing to set per machine
```

`Topic:` is the line the answer heading carries, word for word, so the wording
outlives the session. `Status:` reads `open` while any `q:` has no `a:`, and
`decided <ISO date>` once none do. Entries append in order under the date they
were written.

`why:` carries the reason that was argued, in one line. Leave it out when nobody
gave one.

`alt:` carries one rejected option per line and what killed it. Keep the number,
drop the method: "700ms of extra runtime", not which benchmark said so, which
tool ran it, or what the other rows were. An option nobody weighed is not an
alternative and does not get a line.

Nothing between entries. No paragraph explaining the entry above it, no
restatement of the options in prose. Anything needing more than those four lines
belongs in the code or its comment.
