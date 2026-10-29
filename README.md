# agent-rules

Rules for coding agents, kept in one place and referenced from projects instead of copy-pasted. `rules/` holds them,
one file per rule. `profiles/full.list` and `profiles/limited.list` name the sources each profile loads. The installer
wires those files into Claude Code, Codex and Antigravity.

## The rules

| File | What it governs |
|---|---|
| `rules/10-writing.md` | Prose conventions for docs, commit messages, PRs and code comments. Both profiles. |
| `rules/18-verification.md` | Verify before asserting. Both profiles. |
| `rules/20-answering.md` | Verdict first, problem reporting, one recommendation and concrete answers. Full only. |
| `rules/25-threads.md` | Numbered conversation threads and their commands. Full only. |
| `rules/30-new-state.md` | Describe the current behavior in documentation, PRs and comments. Both profiles. |
| `rules/full/31-conversation-scope.md` | Extend prose conventions to chat replies. Full only. |
| `rules/40-git.md` | Worktree isolation, commit permission and signatures. Both profiles. |
| `rules/60-code.md` | Build the requested scope with the smallest design that meets it. Both profiles. |

The limited profile keeps engineering obligations and prose conventions for repository text. Its prose conventions do
not govern chat replies. The full profile includes every rule and the existing thread protocol.

## What a session looks like with the full profile

`rules/25-threads.md` is the one you notice from the first message. An agent gives everything you have to decide a
number with a trailing slash, flat: 1/, 2/, 3/, whether you raised it or the agent turned it up on its own. A choice it
made on your behalf arrives as a thread, and a skill that reports in one line still numbers whatever it leaves you to
settle. Each thread gets one heading line saying what is unsettled, with a `---` above it drawn across the terminal. The
number stays with its thread for the whole session, never reused and never renumbered, and it is carried into later
turns until you answer it or it stops applying. Answer with "3/ yes, drop it" and there is no ambiguity about what you
dropped. A second level shows up only for a real list inside one thread, which is why four deletions under 5/ are 5.1/
through 5.4/ and no list in an answer opens at a bare `1.`.

Ways of settling one thread get letters instead of digits, so a thread that can go three ways offers 15a/, 15b/ and
15c/ in the order the agent would take them. Type `15b` and thread 15 is settled, its other options closed with it.

### Commands

At the start of a line you type, never inside text you paste:

| You type | You get |
|---|---|
| `3/ yes, drop it` | your answer lands on thread 3, reopening it if it was closed |
| `3/` | thread 3 printed with where it stands, reopening it if it was closed, nothing else in the reply |
| `+ can we cache this?` | a new thread at the lowest number the session has not used |
| `+/ can we cache this?` | the same, if the slash is already in your fingers |
| `5+ what about the tests?` | the next free child of 5/, so 5.3/ once 5.1/ and 5.2/ exist |
| `5+/ what about the tests?` | the same |
| `15b` or `15b/` | thread 15 settled by taking option b, its other options closed with it |
| `15b/$` | option b ruled out, thread 15 left open to the rest |
| `3/$` | thread 3 closed, named once as `Closed: 3/` and never raised again |
| `3.2/$` | 3.2/ closed, 3/ left open |
| `=/` | anything the agent held back opened as a thread and explained, then every open thread listed by its heading, nothing else in the reply |
| `=//` | the same list, with where each thread stands under its heading |

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
| `make install` | Install the full profile globally. Also restores full after a limited install. |
| `make install-limited` | Install the limited profile globally. |
| `make project DIR=/path/to/repo` | Install full project rules. |
| `make project-limited DIR=/path/to/repo` | Install limited project rules. |
| `make build` | Build both `generated/AGENTS.md` and `generated/AGENTS-limited.md`. |
| `make status DIR=/path/to/repo` | Report both scope profiles, wiring and artifact freshness. |
| `make uninstall DIR=/path/to/repo` | Remove global wiring and this project's owned wiring. Keep backups and personal text. |
| `make test` | Run stdlib unittest integration tests in temporary repositories and fake home directories. |

`DIR` defaults to the current directory. The shell commands are `./install.sh global`, `global-limited`, `project [path]`
and `project-limited [path]`. Running the installer without arguments offers a menu. Global installation skips a tool
whose config directory is missing unless `AGENT_RULES_ALL=1` is set.

Global selection is saved in `~/.config/agent-rules/profile`; project selection is saved in `.agent-rules-profile`.
A limited project does not remove full rules loaded globally. `make status` infers older installations and warns when scope profiles differ. Use
`make install-limited` and `make project-limited DIR=/path/to/repo` for limited rules at both scopes. Full rollback uses
`make install` and `make project DIR=/path/to/repo`. Both compiled files keep their own paths across every switch.

## Where the rules land

| Tool | Global | Project | Scoping |
|---|---|---|---|
| Claude Code | `~/.claude/rules/*.md`, one symlink per rule | `.claude/rules/*.md`, same | `paths:` frontmatter |
| Codex | `~/.codex/AGENTS.md` symlink to the selected artifact, plus a `SessionStart` hook | `AGENTS.md` symlink, read as a chain from git root down to cwd | none |
| Antigravity | `@` include line in `~/.gemini/GEMINI.md` | `.agents/rules/*.md`, one symlink per rule | four activation modes |

None of the three fetches a URL, so every path is a local file, and nothing holds a copy: a symlink, an
`@/absolute/path`, or a hook that reads the file at session start. Editing a rule needs `make build` and nothing else.

Codex loads the selected artifact through its global symlink. Its SessionStart hook reads that same artifact and
injects it alongside `~/.codex/agent-rules-personal.md`. The first install backs up an existing global `AGENTS.md` and
moves personal text above and below its managed block into that personal file. Both artifacts explicitly instruct the
agent to read the personal file only when its contents are absent from context. The trusted hook includes its text
directly. Accept the hook in the Codex TUI for that injection. Uninstall restores the personal text to a regular global `AGENTS.md` and keeps the migration file and backups.
Personal instructions are private to each home directory and never enter the checked-in artifacts. Link replacements
are staged beside their destinations; creation, backup or replacement failures leave existing instructions in place.

A nonempty global `AGENTS.override.md` causes a safe refusal: Codex reads it instead of `AGENTS.md`, according to the
[official discovery order](https://learn.chatgpt.com/docs/agent-configuration/agents-md). Conflicting migration files,
malformed managed blocks and unrelated global Codex symlinks also cause a refusal without replacing personal text.
Project `AGENTS.md` files and unrelated symlinks remain in place. Claude and Antigravity rule directories reconcile only
this checkout's owned links, including excluded rules whose source files still exist. Existing personal rule files with
a selected filename remain in place; status reports partial wiring.

After a project install, set each new rule's activation to **Always On** in the Antigravity panel. Global Antigravity
loads the selected artifact through its managed `@` include. Its personal text stays outside that block.

## Size limits

Antigravity caps a rules file at 12,000 characters and Codex at 32,768 bytes, but Claude Code is the tightest: adherence
drops past ~200 lines. `.github/workflows/size.yml` fails a pull request that pushes `generated/AGENTS.md` past that.
Every line costs context in every session.

## Editing the rules

Edit `rules/` and the explicit profile lists, then run `make build`. New sources must be listed in every profile that
needs them. `make status` prints `STALE` for each artifact that differs from its selected sources. Edits to generated
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
