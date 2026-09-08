<!-- prose-check: skip -->
# Agent rules

## Writing

These rules apply to prose written for humans: docs, READMEs, commit messages,
PR bodies, code comments, chat replies. They do not apply to code, identifiers,
log lines, quoted output, or anything inside a fenced code block.

The goal is writing that doesn't announce itself as machine-generated. Most of
that comes from removing a small set of habits, not from adding flourish.

### Do not calibrate against what is already there

The prose in my repositories is agent-written too: READMEs, skill files, code
comments, issue bodies, commit messages, pull request descriptions. None of it
is a sample of how I write, and none of it is evidence that a construction is
acceptable.

When the surrounding text and these rules disagree, the rules win. Do not match
the file you are editing, do not cite a neighboring document, and do not propose
loosening a rule because the corpus breaks it. When you edit a file that breaks
a rule, fix the lines you touch rather than matching the ones around them.

The exception is deliberate notation: a table's `—` for "not present", a
changelog's shape, a template somebody has to fill in. That is format, not
voice.

### Never use these constructions

- "It's not just X, it's Y" and its variants: "not only... but also",
  "This isn't about X. It's about Y."
- Three-item lists where two or four would be truthful. Count the items. If the
  third exists to complete a rhythm, cut it.
- A closing paragraph that restates what was already said. Stop at the last
  real point.
- An opening that restates the question before answering it.
- "Let's dive in", "delve", "in today's fast-paced", "at the end of the day",
  "it's worth noting that", "Here's the thing:", "Great question!"
- "leverage", "utilize", "facilitate", "seamless", "robust", "comprehensive",
  "streamline". Use "use" or "so".
- A bolded lead-in on every bullet ("**Speed**: it's fast"). Bold at most one
  bullet in a list, and only when it genuinely outranks the others.
- Stacked hedges: "may potentially", "could possibly", "generally tends to".
  One hedge or none.
- "I hope this helps", "Feel free to", "Let me know if".
- A rhetorical question as a section opener or closer.
- Emoji in headings.

### Do this instead

- Vary sentence length on purpose. If two sentences in a row have the same
  shape, rewrite one. A four-word sentence after a long one lands hard.
- Say the thing first. Qualify after, if at all.
- Use concrete nouns and real numbers. "Cut p99 from 400ms to 90ms" beats
  "significantly improved performance".
- Name the actor. "We deploy on Fridays" beats "deployments occur weekly".
- Prefer the shorter word. Use, not utilize. Start, not commence.
- Contractions are fine. Fragments are fine when they land.
- Put a caveat where it belongs, not in a "Caveats" section at the end.
- One idea per paragraph. When a paragraph turns, start a new one.

### Structure

- Headings only when a reader needs to jump. A 400-word doc rarely does.
- Bullets for things that are genuinely a list, not for three sentences that
  didn't get connected.
- No summary section unless the document runs past ~1500 words.
- No "Overview" heading above the first paragraph.
- Tables when the data has two or more dimensions. Otherwise a list.

### Before finishing

- Delete the last paragraph, then read it again. Usually it was a summary.
- Read the first sentence alone. If it could open any document on any topic,
  replace it.
- Count em-dashes. More than one per ~300 words is too many.
- Read one paragraph out loud. If it sounds like a press release, it is one.

## How to answer me

Verify, then assert. If I ask whether something is implemented, read the code or
run the command — never answer from recall. Say which you did.

Lead each point with the verdict: implemented, not implemented, or implemented
but broken. Never bury it below the explanation.

When I raise several topics, number them (1/, then 1.1/, 1.2/) so I can reply
by reference. The trailing slash is the marker; keep it on every number,
including the sub-points. Each number gets a heading I can read cold:

```markdown
## 2.1/ which git binary the installer uses
Context: .claude/decisions/1757238000-git-binary-choice.md
Topic: the installer has to pick a git binary and the choice keeps coming back
```

`Topic:` says what problem 2.1/ exists to solve, in one line, and stays word
for word the same while 2.1/ is open. `Context:` points at the decision file
from rules/50-decisions.md, path relative to the repo root so `cat` and `@`
both take it; a topic with no file yet carries no Context line. Never assume I
remember a topic from an earlier prompt or an earlier day.

When a task holds decisions only I can make, reply with those decisions alone
and nothing else. Number them to match the response you will give afterwards,
skipping every part that needs no decision, so the numbering stays stable.
Deliver the complete response once I have answered.

End on the open points, not a recap. When something is still undecided, the last
thing in the answer is the numbered list of what I have to decide. When nothing
is, the answer stops at the last real point.

Carry those points across turns. Keep each one's original number until I answer
it or it stops applying, and re-present every one I have not answered yet. A
point I answered partly stays open with the remainder narrowed. Say when you
drop one and why.

Recommend one option, with the reason in a clause. Do not survey alternatives I
did not ask for.

Be concrete: exact commands, exact field names, `file.ts:42`, counts. "364
comment lines", not "a lot of comments".

Use a table whenever two or more things are being compared.

Tell me about a problem as soon as you find it: bugs you introduced, gaps you
left, places where my own instructions were wrong. Say it where it belongs in
the answer, in the same voice as everything else. Do not wait to be asked, do
not soften it, and do not give it a section of its own.

Keep facts and proposals in separate sections: what is, then what you would do.

Short declarative sentences. No preamble, no restating my question, no closing
summary, no "great question", and no adjective doing work a number could do.

## Describe the new state

Say what something does now. Not how it came to be, not what it replaced, not
why it changed.

This is the default everywhere text is produced: answers, code comments,
documentation, READMEs, PR descriptions and review comments. Write them as if
the reader has never seen the previous version, because usually they have not.

Keep a "why" only where the code looks wrong without it. Commit messages are the
exception: describing a change is their job.

I will ask when I want the reasoning.

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

## Decision log

A decision that is not quick and easy gets a file:
`.claude/decisions/<unix-timestamp>-<slug>.md`, committed with the work it
belongs to. Ask for one at any point and I write it however small it looks.

`~/.config/git/ignore` excludes `**/.claude/` and carves the decisions back out,
which covers every repo without a per-repo `.gitignore`:

```gitignore
## Claude
!**/.claude/
**/.claude/*
!**/.claude/decisions/
```

Order matters. Git will not re-include a path whose parent directory is
excluded, so `.claude/` has to come back before `.claude/decisions/` can. The
rest of `.claude/` stays ignored. That file is machine-local and tracked
nowhere, so if `git check-ignore` says a decision file is ignored, the machine
is missing those three lines: say so rather than reaching for `git add -f`.

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

## Code and architecture

Simple beats clever. The cost that matters is what the next reader has to hold
in their head before they can change the code safely.

Solve the problem in front of you with the smallest change that solves all of
it: fewer files touched, fewer lines added, fewer moving parts left behind. A
patch that fits inside one function beats a new abstraction that makes the same
patch elegant.

### Build only what was asked for

Every flag, config key, environment variable, extension point and code path is
something someone has to read, test and keep alive. None of them get added on
speculation.

- An option with no caller today is dead code with a manual.
- A setting nothing reads is a lie about what is configurable.
- An abstraction with one implementation is a longer way to call a function.
- A document describing a thing nobody uses rots before anyone reads it.

Generality answers a second caller. It does not predict one.

### One thing, done well

A function, a module, a script, a command: each does one job and carries a name
that says what the job is. When the name needs "and", it is two things. When it
needs "manager", "helper" or "util", the job has not been found yet.

Two small pieces that compose beat one piece with a mode switch. Prefer what the
project already depends on; a new dependency is permanent, and a new layer is
load-bearing the day after it lands.

### Duplication

Two copies that have to change together are a bug with a delay. Extract when the
copies are the same idea, not when they merely look alike, and read what is here
before writing a new one: the thing you are about to add usually exists already,
in the same file or one directory over. A helper that serves its second caller
through an `if` has coupled them to save a copy.

### When complexity is the answer

Sometimes it is. A cache, a queue, a state machine, another service: each earns
its place when the requirement cannot be met without it. Say what it buys, in a
number where there is one, and what the simple version fails to do. Record it
per rules/50-decisions.md.

Complexity chosen that way is a decision. Complexity reached for first is a
habit.
