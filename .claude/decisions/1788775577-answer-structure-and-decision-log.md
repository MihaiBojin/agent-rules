# How answers are structured and where decisions are recorded

Topic: answers assume conversation context I no longer have days and projects later
Status: decided 2026-09-07
Opened: 2026-09-07

## 2026-09-07

q: How should an answer end while decisions are still open
a: on the numbered open points, carrying their numbers across turns
why: a recap restates what I just read, the open points are the only thing left to act on

q: How does an answer point at the history behind a numbered topic
a: a Context line under each numbered heading, path relative to the repo root
why: `cat` and `@` both take a repo-relative path, so I read it without an IDE
alt: absolute path — clickable, but only opens in an editor

q: Where do decision files live
a: `.claude/decisions/<unix-timestamp>-<slug>.md`, committed with the work
why: traceability of old discussions has to survive a fresh clone and reach anyone else on the repo
alt: same path but gitignored — gone on a new machine
alt: `~/.claude/projects/<slug>/topics/` — no git noise, but per-machine and invisible to the repo

q: Which topics get a file
a: the ones that are not quick and easy, plus any I ask for
why: a file per one-off question is churn nobody reopens
alt: every numbered topic — a file recording "yes, push it"

q: What goes in a decision file
a: q, a, why and alt lines, nothing between them
why: the ask, the result, the reason and what the rejected options cost is the whole of the traceability
alt: full transcript appended per turn — the thing I would have to reread to use
alt: current state only — obeys 30-new-state, loses how we got there

q: Does a decision log contradict rules/30-new-state.md
a: no, the log is the one place history is kept, everything else still describes the new state
why: 30-new-state keeps history out of prose read cold, not out of a record kept for lookup

q: `**/.claude/` is ignored globally, so how does a decision file get committed
a: carve `**/.claude/decisions/` back out in `~/.config/git/ignore`
why: one edit covers every repo, and a repo with no decisions yet reports the same `git status` as before
alt: an un-ignore stanza in each repo's `.gitignore` — travels with the repo, at the cost of a stanza in every repo I touch
alt: `decisions/` at the repo root — committed by default, a new top-level directory in every repo
alt: `git add -f` per file — invisible to everything that respects gitignore

q: Should decision tracking be switchable, and does it belong in a plugin
a: deferred to issue #6, the rule stays always-on until that lands
why: the toggle has to reach Codex and Hermes too, which have no plugin host, and that shape is not settled
alt: ship a toggle in Claude Code's settings.json now — leaves the other tools with no switch

q: Which marker carries a numbered point in an answer
a: a trailing slash — `1/`, `1.1/`
why: `#1` autolinks to issue #1 wherever an answer is pasted into GitHub
alt: bare `1`, `1.1` — reads as prose when a sentence starts with it
