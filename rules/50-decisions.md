<!-- prose-check: skip -->
## Decision log

A decision that is not quick and easy gets a file:
`.claude/decisions/<unix-timestamp>-<slug>.md`, committed with the work it
belongs to. Ask for one at any point and I write it however small it looks.

The file is the only place the history lives. Answers, commit bodies, PR
descriptions, READMEs and code comments say what is true now and point at the
file instead of retelling how we got there.

`~/.config/git/ignore` carves these back out of the `**/.claude/` exclusion on
my machines. If `git check-ignore` says a decision file is ignored, that machine
is missing the carve-out: say so rather than reaching for `git add -f`.

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
`decided <ISO date>` once none do. Entries append under the date they were
written. `why:` is the reason that was argued, one line, left out when nobody
gave one. `alt:` is one rejected option per line and what killed it: keep the
number, drop the method. An option nobody weighed does not get a line.

Nothing between entries. No paragraph explaining the one above it. Anything
needing more than those four lines belongs in the code or its comment.
