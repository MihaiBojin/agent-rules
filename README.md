# agent-rules

Rules for coding agents, kept in one place and referenced from projects instead
of copy-pasted. Six of them: how to write prose for humans, how to answer me,
how to carry a numbered thread across a session, how to describe a change, how
to treat git history, and how much to build when writing code.

`rules/*.md` holds them, one file per rule. Everything else exists to get those
files in front of Claude Code, Codex, and Antigravity without keeping a separate
copy for each.

## What a session looks like with them on

`rules/25-threads.md` changes the shape of every reply, so it is the one you
notice from the first message. An agent gives everything you raise a number
with a trailing slash, flat: 1/, 2/, 3/. Each thread gets one heading line
stating what is unsettled, a `---` above it drawn across the terminal, and a
`Context:` line pointing at a file when the background needs more than a
heading. The number stays with its thread for the whole session, never reused
and never renumbered, and it is carried into later turns until you answer it or
it stops applying. Answer with "3/ yes, drop it" and there is no ambiguity
about what you dropped.

A second level shows up only for a real list inside one thread. Four deletions
under 5/ are 5.1/ through 5.4/. That is also why no list in an answer opens at a
bare `1.`, which would collide with thread 1/.

You drive it from the start of a line you type:

| You type | You get |
|---|---|
| `3/ yes, drop it` | your answer lands on thread 3 |
| `+ can we cache this?` | a new thread at the lowest number the session has not used |
| `+/ can we cache this?` | the same, if the slash is already in your fingers |
| `5+ what about the tests?` | the next free child of 5/, so 5.3/ once 5.1/ and 5.2/ exist |
| `5+/ what about the tests?` | the same |
| `3/$` | thread 3 closed, named once as `Closed: 3/` and never raised again |

Lowest unused, not one past the highest, so a number you dropped stays dropped
instead of coming back attached to something else. A `+` inside text you paste
is not a marker, which keeps a diff hunk from reading as forty new threads.

Reopening a closed thread is the same `3/` you would use to answer it. It comes
back at its old number under its old heading, opening with two or three
sentences on where it stood when you closed it.

Settled threads come first in a reply and the ones needing your decision come
last, with nothing after them. When a task holds decisions only you can make,
the reply holds those decisions alone, numbered to match the full answer that
follows once you have chosen.

`rules/20-answering.md` governs the answer around the threads. A verdict leads
every point instead of trailing the explanation, a claim about the code comes
with the command that produced it, and one option gets recommended rather than
four surveyed.

## Files

| Path | What it is |
|---|---|
| `rules/*.md` | The rules, one per file. The only files with content worth editing. |
| `generated/AGENTS.md` | Built from `rules/*.md` by `make build`. Codex reads one file and cannot import another, so it gets the concatenation. |
| `generated/README.md` | Says the above to anyone who opens the directory. |
| `install.sh` | Wires the rules into each tool's expected location. |
| `Makefile` | Thin wrapper over `install.sh`. |
| `hooks/codex-session-start.sh` | Codex `SessionStart` hook. Returns the ruleset as `additionalContext`. |

## Install

```bash
git clone git@github.com:MihaiBojin/agent-rules.git ~/repos/agent-rules
cd ~/repos/agent-rules
make install
```

Then open Codex once and accept the hook when it prompts. Until you do, Codex
falls back to the pointer described below.

`install.sh` writes absolute paths into each tool's config, so where you clone
matters. Move the repo later and you re-run `make install`.

| Command | What it does |
|---|---|
| `make build` | Regenerate `generated/AGENTS.md` from `rules/*.md` |
| `make install` | User-level wiring, every tool it detects |
| `make project` | Per-repo wiring. `DIR=/path` targets another repo |
| `make status` | What is wired up right now |
| `make uninstall` | Undo both scopes |

`./install.sh` with no arguments offers the same set as a menu, fzf if you have
it. Re-running is safe: a link already pointing at this repo is left alone and
nothing is reported. Anything else in the way is moved to
`<path>.bak-<timestamp>` and the move goes to stderr, so
`./install.sh global 2>/dev/null` shows you only the happy path.

`install.sh global` skips a tool whose config directory is missing. Set
`AGENT_RULES_ALL=1` to wire up one you haven't run yet.

## Decision files

The decision log is the `decisions` plugin in
[MihaiBojin/agent-plugins](https://github.com/MihaiBojin/agent-plugins): one
file per topic in `.decisions/` at the repo root, only where that directory
exists. The rules here say nothing about it.

## Where the rules land

| Tool | Global | Project | Scoping |
|---|---|---|---|
| Claude Code | `~/.claude/rules/*.md`, one symlink per rule | `.claude/rules/*.md`, same | `paths:` frontmatter |
| Codex | `SessionStart` hook in `~/.codex/config.toml`, plus a pointer in `~/.codex/AGENTS.md` | `AGENTS.md` symlink, read as a chain from git root down to cwd | none |
| Antigravity | `@` include line in `~/.gemini/GEMINI.md` | `.agents/rules/*.md`, one symlink per rule | four activation modes |

None of the three will fetch a URL, so every path there is a local file. Claude
Code and Antigravity read a directory, which gives one symlink per rule and lets
you see in the transcript which rule fired. Codex reads a single file and has no
import syntax.

Four things the installer handles that aren't obvious from that table.

**Nothing holds a copy of the rules.** Claude Code follows symlinks. Antigravity
resolves `@/absolute/path` against the filesystem. Codex runs a hook that reads
the file at session start. Each of them picks up whatever the file says when a
session starts, which is why editing a rule needs `make build` and nothing
else. No reinstall, no second machine to remember.

**Codex gets a belt and braces.** The hook is the guarantee: Codex injects the
hook's output itself, so the model cannot skip it. But a hook stays untrusted
until you accept it once in the Codex TUI, and until then it is skipped
*silently*, with no warning and no error. So `~/.codex/AGENTS.md` also gets a
managed block telling the agent to read the same path. That fallback depends on
the model choosing to open the file, which it did in every trial, but it is a
fallback rather than a mechanism.

**Your own lines survive.** The installer never replaces a config file it
touches. It maintains a marked block and leaves everything above it alone,
using `<!-- >>> agent-rules >>> -->` in markdown and `# >>> agent-rules >>>` in
`config.toml`. `make uninstall` strips the block and leaves the rest
byte-identical.

**A project that already has its own `AGENTS.md` keeps it.** No backup, no
replacement. Codex has no import syntax, so either paste the rules in or lean on
the global install.

After a project install, open the Antigravity rules panel and set each new
rule's activation to **Always On**. That one can't be scripted.

## Size limits

Each tool caps how much instruction text it will load:

| Tool | Cap |
|---|---|
| Antigravity | 12,000 characters per rules file |
| Codex | 32,768 bytes for project docs (`project_doc_max_bytes`), and the same again for the hook's `additionalContextLimit` |
| Claude Code | 4 MiB, but adherence drops past ~200 lines |

`generated/AGENTS.md` is 8,356 bytes across 170 lines, so the tightest of these
leaves 3.9x headroom. The individual `rules/*.md` run 526 bytes to 2,951.
`.github/workflows/size.yml` fails a pull request that pushes the artifact
past 200 lines.

## Editing the rules

Edit `rules/*.md`, then `make build`. `make install` and `make project` build
first anyway, and `make status` prints `STALE` when the artifact and the sources
disagree. Nothing reads the artifact as a source, so an edit made there is lost
on the next build.

The edit reaches your next session, not the one you are sitting in. Claude Code
attaches the rules to the first message of a session and replays that attachment
when you resume, so a session opened on Monday still answers by Monday's rules
on Thursday, however many times you rebuild. Start a fresh session after
changing a rule you want to see honored.

This repo carries no root `AGENTS.md` or `CLAUDE.md` on purpose. Either one
would load as guidance for agents working on the repo itself, which is also why
the artifact lives in `generated/`.

Keep the concatenation under ~200 lines, the point where Claude Code's own
adherence drops off. Every line costs context in every session.

Write rules concrete enough to check. "Count the items" beats "avoid
formulaic lists", and a banned construction with an example beside it beats a
principle.

Before trusting a change, take a few files an agent wrote before it and
regenerate them with the rules loaded. Diff, and count tells in both. If the
count doesn't drop, the new rule is too abstract.
