<!-- prose-check: skip -->
# generated/

`AGENTS.md` here is built by `../install.sh build` from `../rules/*.md`. Edits
made to it are discarded on the next build.

It is committed because Codex and Hermes read a single file and have no import
syntax, so `install.sh project` symlinks this artifact into the repo it wires
up. Claude Code and Antigravity read a directory and get `../rules/*.md`
directly.

It sits here rather than at the repo root so that agents working *on* this
repo don't pick it up as their own guidance.

To change a rule, edit the file under `../rules/` and run:

```bash
./install.sh build
```

`./install.sh status` prints `STALE` when this file and `../rules/` disagree.
