# generated/

`AGENTS.md` is the full profile. `AGENTS-limited.md` is the limited profile.
`../install.sh build` compiles both from the sources explicitly named in
`../profiles/full.list` and `../profiles/limited.list`. Generated edits are
lost on the next build. Neither artifact contains personal instructions.

Codex symlinks the selected artifact globally and in projects. Its global
SessionStart hook reads the same selected file and injects migrated personal
text from the user's home directory. Both artifacts instruct the agent to
read that personal file when present. Claude Code and project Antigravity
get symlinks to the selected source files. Global Antigravity gets an `@`
include of the selected artifact.

Both artifacts are committed and keep distinct paths across installations.
They sit here so agents working on this repo do not load them as root guidance.

Edit sources under `../rules/` and their profile lists, then run `make build`.
`make status` reports freshness for both files. `make test` checks generated
output against the checked-in artifacts and exercises the real installer with
fake home directories, including full/limited switches and personal migration.
