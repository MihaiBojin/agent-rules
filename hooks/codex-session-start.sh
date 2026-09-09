#!/usr/bin/env bash
# Codex SessionStart hook: hand the ruleset to the model as additionalContext.
#
# Codex injects the returned text itself, so the model cannot skip it, and the
# file is re-read on every session; `make build` propagates with no reinstall.
#
# Fails open on every unexpected condition. A hook that breaks session startup
# is a hook you disable within a week.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

rules="${1:-$(dirname "$0")/../generated/AGENTS.md}"
[ -r "$rules" ] || exit 0

jq -Rs --arg event SessionStart \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: .}}' < "$rules"
