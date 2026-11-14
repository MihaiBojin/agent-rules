# agent-rules

Rules for coding agents, kept in one place and referenced from projects instead of copy-pasted. `rules/` holds them,
one file per rule. The installer wires every `rules/*.md` into Claude Code, Codex and Antigravity.

## The rules

| File | What it governs |
|---|---|
| `rules/10-writing.md` | Prose conventions for docs, commit messages, PRs and code comments. |
| `rules/18-verification.md` | Verify before asserting. |
| `rules/30-new-state.md` | Describe the current behavior in documentation, PRs and comments. |
| `rules/40-git.md` | Worktree isolation, commit permission and signatures. |
| `rules/60-code.md` | Build the requested scope with the smallest design that meets it. |

How a chat reply reads, its numbered decision threads and its answer structure, comes from the `dialogue` plugin in
[MihaiBojin/agent-plugins](https://github.com/MihaiBojin/agent-plugins), not from these rules.

## Install

```bash
git clone git@github.com:MihaiBojin/agent-rules.git ~/repos/agent-rules
cd ~/repos/agent-rules
make install
```

| Command | What it does |
|---|---|
| `make install` | Install the rules globally. |
| `make project DIR=/path/to/repo` | Install project rules. |
| `make build` | Build `generated/AGENTS.md`. |
| `make status DIR=/path/to/repo` | Report wiring and artifact freshness. |
| `make uninstall DIR=/path/to/repo` | Remove global wiring and this project's owned wiring. Keep backups and personal text. |
| `make test` | Run stdlib unittest integration tests in temporary repositories and fake home directories. |

`DIR` defaults to the current directory. The shell commands are `./install.sh global` and `./install.sh project [path]`.
Running the installer without arguments offers a menu. Global installation skips a tool whose config directory is
missing unless `AGENT_RULES_ALL=1` is set. Installing removes this checkout's links to rule files that no longer exist.

## Where the rules land

| Tool | Global | Project | Scoping |
|---|---|---|---|
| Claude Code | `~/.claude/rules/*.md`, one symlink per rule | `.claude/rules/*.md`, same | `paths:` frontmatter |
| Codex | `~/.codex/AGENTS.md` symlink to `generated/AGENTS.md`, plus a `SessionStart` hook | `AGENTS.md` symlink, read as a chain from git root down to cwd | none |
| Antigravity | `@` include line in `~/.gemini/GEMINI.md` | `.agents/rules/*.md`, one symlink per rule | four activation modes |

None of the three fetches a URL, so every path is a local file, and nothing holds a copy: a symlink, an
`@/absolute/path`, or a hook that reads the file at session start. Editing a rule needs `make build` and nothing else.

Codex loads `generated/AGENTS.md` through its global symlink. Its SessionStart hook reads that same file and
injects it alongside `~/.codex/agent-rules-personal.md`. The first install backs up an existing global `AGENTS.md` and
moves personal text above and below its managed block into that personal file. The artifact instructs the
agent to read the personal file only when its contents are absent from context. The trusted hook includes its text
directly. Accept the hook in the Codex TUI for that injection. Uninstall restores the personal text to a regular global `AGENTS.md` and keeps the migration file and backups.
Install and uninstall keep the tables that Codex writes inside the managed block of `~/.codex/config.toml`, such as
`[hooks.state]` with the trust it records for each hook.
Personal instructions are private to each home directory and never enter the checked-in artifacts. Link replacements
are staged beside their destinations; creation, backup or replacement failures leave existing instructions in place.

A nonempty global `AGENTS.override.md` causes a safe refusal: Codex reads it instead of `AGENTS.md`, according to the
[official discovery order](https://learn.chatgpt.com/docs/agent-configuration/agents-md). Conflicting migration files,
malformed managed blocks and unrelated global Codex symlinks also cause a refusal without replacing personal text.
Project `AGENTS.md` files and unrelated symlinks remain in place. Claude and Antigravity rule directories reconcile only
this checkout's owned links. Existing personal rule files with a rule's filename remain in place; status reports partial
wiring.

After a project install, set each new rule's activation to **Always On** in the Antigravity panel. Global Antigravity
loads `generated/AGENTS.md` through its managed `@` include. Its personal text stays outside that block.

## Size limits

Antigravity caps a rules file at 12,000 characters and Codex at 32,768 bytes, but Claude Code is the tightest: adherence
drops past ~200 lines. `.github/workflows/size.yml` fails a pull request that pushes `generated/AGENTS.md` past that.
Every line costs context in every session.

## Editing the rules

Edit `rules/`, then run `make build`. Every `rules/*.md` is a source. `make status` prints `STALE` when
`generated/AGENTS.md` differs from its sources. Edits to generated
files are lost on the next build.

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
