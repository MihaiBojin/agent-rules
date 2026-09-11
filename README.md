# agent-rules

Rules for coding agents, kept in one place and referenced from projects instead of copy-pasted. `rules/*.md` holds them,
one file per rule. Everything else exists to get those files in front of Claude Code, Codex, and Antigravity without
keeping a separate copy for each.

## The rules

| File | What it governs |
|---|---|
| `rules/10-writing.md` | Prose written for humans: docs, commit messages, chat replies. Banned constructions with an example beside each. |
| `rules/20-answering.md` | What a reply says. Verify before asserting, verdict first, one recommendation, a number instead of an adjective. |
| `rules/25-threads.md` | What a reply looks like. The numbered threads an answer is built from, and how they open, close and reopen. |
| `rules/30-new-state.md` | Describe what something does now, not what it replaced. Commit messages are the exception. |
| `rules/40-git.md` | Branching, when to commit and push, and which trailers survive. |
| `rules/60-code.md` | How much to build. The smallest change that solves all of it, and when complexity earns its place. |

## What a session looks like with them on

`rules/25-threads.md` is the one you notice from the first message. An agent gives everything you have to decide a
number with a trailing slash, flat: 1/, 2/, 3/, whether you raised it or the agent turned it up on its own. A choice it
made on your behalf arrives as a thread, and a skill that reports in one line still numbers whatever it leaves you to
settle. Each thread gets one heading line saying what is unsettled, with a `---` above it drawn across the terminal. The
number stays with its thread for the whole session, never reused and never renumbered, and it is carried into later
turns until you answer it or it stops applying. Answer with "3/ yes, drop it" and there is no ambiguity about what you
dropped. A second level shows up only for a real list inside one thread, which is why four deletions under 5/ are 5.1/
through 5.4/ and no list in an answer opens at a bare `1.`.

### Commands

At the start of a line you type, never inside text you paste:

| You type | You get |
|---|---|
| `3/ yes, drop it` | your answer lands on thread 3, reopening it if it was closed |
| `+ can we cache this?` | a new thread at the lowest number the session has not used |
| `+/ can we cache this?` | the same, if the slash is already in your fingers |
| `5+ what about the tests?` | the next free child of 5/, so 5.3/ once 5.1/ and 5.2/ exist |
| `5+/ what about the tests?` | the same |
| `3/$` | thread 3 closed, named once as `Closed: 3/` and never raised again |
| `3.2/$` | 3.2/ closed, 3/ left open |
| `=/` | anything the agent held back opened as a thread, then every open thread listed by its heading, nothing else in the reply |

Lowest unused, not one past the highest, so a number you dropped stays dropped instead of coming back attached to
something else. A reopened thread returns at its old number under its old heading, opening with two or three sentences
on where it stood when you closed it.

A heading holds still so you can track it. When a thread narrows or its heading turns out wrong, the agent rewrites the
line and prints the old one under it as `Replaces: 3/ whether the marketplace is still accurate`, once, in that answer.
The number stays what it was.

## Install

```bash
git clone git@github.com:MihaiBojin/agent-rules.git ~/repos/agent-rules
cd ~/repos/agent-rules
make install
```

| Command | What it does |
|---|---|
| `make build` | Regenerate `generated/AGENTS.md` from `rules/*.md` |
| `make install` | User-level wiring, every tool it detects |
| `make project` | Per-repo wiring. `DIR=/path` targets another repo |
| `make status` | What is wired up right now |
| `make uninstall` | Undo both scopes |

`install.sh` writes absolute paths, so where you clone matters: move the repo and re-run `make install`. Re-running is
safe, anything in the way is moved to `<path>.bak-<timestamp>`, and `./install.sh` with no arguments offers the same set
as a menu. It skips a tool whose config directory is missing unless you set `AGENT_RULES_ALL=1`. Open Codex once
afterwards and accept the hook it prompts for.

## Where the rules land

| Tool | Global | Project | Scoping |
|---|---|---|---|
| Claude Code | `~/.claude/rules/*.md`, one symlink per rule | `.claude/rules/*.md`, same | `paths:` frontmatter |
| Codex | `SessionStart` hook in `~/.codex/config.toml`, plus a pointer in `~/.codex/AGENTS.md` | `AGENTS.md` symlink, read as a chain from git root down to cwd | none |
| Antigravity | `@` include line in `~/.gemini/GEMINI.md` | `.agents/rules/*.md`, one symlink per rule | four activation modes |

None of the three fetches a URL, so every path is a local file, and nothing holds a copy: a symlink, an
`@/absolute/path`, or a hook that reads the file at session start. Editing a rule needs `make build` and nothing else.

Codex gets both the hook and a managed block in `~/.codex/AGENTS.md`, because a hook stays untrusted until you accept it
once in the TUI and is skipped silently until then. The installer maintains only its own marked block in any config file
it touches, so `make uninstall` leaves the rest byte-identical, and a project with its own `AGENTS.md` keeps it. After a
project install, set each new rule's activation to **Always On** in the Antigravity panel. That one can't be scripted.

## Size limits

Antigravity caps a rules file at 12,000 characters and Codex at 32,768 bytes, but Claude Code is the tightest: adherence
drops past ~200 lines. `.github/workflows/size.yml` fails a pull request that pushes `generated/AGENTS.md` past that.
Every line costs context in every session.

## Editing the rules

Edit `rules/*.md`, then `make build`. `make status` prints `STALE` when the artifact and the sources disagree, and
nothing reads the artifact as a source, so an edit made there is lost on the next build.

The edit reaches your next session, not the one you are sitting in. Claude Code attaches the rules to the first message
of a session and replays that attachment when you resume, so a session opened on Monday still answers by Monday's rules
on Thursday. Start a fresh session after changing a rule you want honored.

Write rules concrete enough to check. "Count the items" beats "avoid formulaic lists". Before trusting a change,
regenerate a few files an agent wrote without it, diff, and count tells in both. If the count doesn't drop, the rule is
too abstract.

The decision log is the `decisions` plugin in [MihaiBojin/agent-plugins](https://github.com/MihaiBojin/agent-plugins),
one file per topic in `.decisions/`. The rules here say nothing about it. This repo carries no root `AGENTS.md` or
`CLAUDE.md` on purpose, since either would load as guidance for agents working on the repo itself, which is also why the
artifact lives in `generated/`.
