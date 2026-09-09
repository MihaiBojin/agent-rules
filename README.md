# agent-rules

Rules for coding agents, kept in one place and referenced from projects instead
of copy-pasted. Five of them: how to write prose for humans, how to answer me,
how to describe a change, how to treat git history, and how much to build when
writing code.

`rules/*.md` holds them, one file per rule. Everything else exists to get those
files in front of Claude Code, Codex, and Antigravity without keeping a separate
copy for each.

## Files

| Path | What it is |
|---|---|
| `rules/*.md` | The rules, one per file. The only files with content worth editing. |
| `generated/AGENTS.md` | Built from `rules/*.md` by `make build`. Codex reads one file and cannot import another, so it gets the concatenation. |
| `generated/README.md` | Says the above to anyone who opens the directory. |
| `install.sh` | Wires the rules into each tool's expected location. |
| `Makefile` | Thin wrapper over `install.sh`. |
| `hooks/check-prose.sh` | Claude Code `PostToolUse` hook. Greps written markdown and hands violations back. |
| `hooks/codex-session-start.sh` | Codex `SessionStart` hook. Returns the ruleset as `additionalContext`. |
| `hooks/prose-patterns.txt` | The grep patterns. Edit alongside `rules/10-writing.md`. |

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
| `make install` | User-level wiring plus the prose hook, every tool it detects |
| `make project` | Per-repo wiring plus the prose hook. `DIR=/path` targets another repo |
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
the file at session start. Each of them picks up whatever the file says at the
time, which is why editing a rule needs `make build` and nothing else. No
reinstall, no second machine to remember.

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

`generated/AGENTS.md` is 8,063 bytes across 164 lines, so the tightest of these
leaves 4.1x headroom. The individual `rules/*.md` run 526 bytes to 2,658.
`.github/workflows/size.yml` fails a pull request that pushes the artifact
past 200 lines.

## The prose hook

Rules are context, not enforcement, and adherence drifts over a long session.
The prose hook is the backstop: it runs on every write, greps the file, and
exits 2 so Claude sees its own violations and fixes them.

`install.sh global` adds the `PostToolUse` entry to `~/.claude/settings.json`
pointing at `hooks/check-prose.sh` in this repo by absolute path, so it fires in
every repo whether or not that repo was wired. `install.sh project` links the
script into `.claude/hooks/` and adds an entry to `.claude/settings.json` that
goes through `$CLAUDE_PROJECT_DIR`, so the repo carries its own copy for anyone
who clones it. Both skip the edit when it's already there, and both need `jq`;
without it you get the snippet on stderr and add it yourself.

Wiring both scopes in the same repo runs the check twice on each write. The
second run reports the same lines, so the cost is duplicated stderr.

`install.sh uninstall` drops the global entry, since it points into this repo
and nothing else can claim it. The project entry is left alone, because it may
be committed and shared.

It only reads `.md`, `.markdown`, and `.txt`. Fenced code blocks are blanked
before checking, so line numbers in the output match the real file.

A file whose first ten lines contain `<!-- prose-check: skip -->` is left alone.
Every `rules/*.md` carries that marker, since between them they quote every
phrase they ban. `build` strips the per-file markers and puts one at the top of
`generated/AGENTS.md`.

## What the prose hook can't catch

Grep finds vocabulary and two or three fixed constructions. It's blind to the
things that most make writing sound generated:

- Rule-of-three lists
- A closing paragraph that summarizes the one above it
- Bolded lead-ins on every bullet
- Sentences that all run the same length

The hook prints a reminder about these, but catching them needs a reader. If the
reminder stops working, the next step is a cheap-model pass over changed
markdown rather than a longer regex.

## Editing the rules

Edit `rules/*.md`, then `make build`. `make install` and `make project` build
first anyway, and `make status` prints `STALE` when the artifact and the sources
disagree. Nothing reads the artifact as a source, so an edit made there is lost
on the next build.

This repo carries no root `AGENTS.md` or `CLAUDE.md` on purpose. Either one
would load as guidance for agents working on the repo itself, which is also why
the artifact lives in `generated/`.

Keep the concatenation under ~200 lines, the point where Claude Code's own
adherence drops off. Every line costs context in every session.

Two habits worth keeping:

- Write rules concrete enough to check. "Count the items" beats "avoid formulaic
  lists."
- When you add a vocabulary ban, add the pattern to `prose-patterns.txt` in the
  same commit.

Before trusting a change, take a few files an agent wrote before it and
regenerate them with the rules loaded. Diff, and count tells in both. If the
count doesn't drop, the new rule is too abstract.
