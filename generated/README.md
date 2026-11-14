# generated/

`AGENTS.md` is every `../rules/*.md` compiled into one file by `../install.sh build`. Edits here are lost on the next
build. It contains no personal instructions.

Codex symlinks it globally and in projects. Its global SessionStart hook reads the same file and injects migrated
personal text from the user's home directory. The file instructs the agent to read that personal file when present.
Claude Code and project Antigravity get symlinks to the source files. Global Antigravity gets an `@` include of this
file.

It sits here so agents working on this repo do not load it as root guidance.

Edit sources under `../rules/`, then run `make build`. `make status` reports whether it is current. `make test` checks
the build against the checked-in file and exercises the real installer with fake home directories, including personal
migration.
