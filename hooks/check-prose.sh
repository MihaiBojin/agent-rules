#!/usr/bin/env bash
# PostToolUse (Write|Edit) hook: flag AI tells in markdown and hand them back
# to Claude. Exit 2 sends stderr to Claude, which then fixes its own prose.
#
# Fails open on every unexpected condition. A style checker that blocks writes
# is a style checker you disable within a week.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

case "$file" in
  *.md|*.markdown|*.txt) ;;
  *) exit 0 ;;
esac
[ -r "$file" ] || exit 0

# Opt-out: a file whose first 10 lines carry this marker is never checked.
# The rules file itself needs it, since it quotes every banned phrase.
head -n 10 "$file" 2>/dev/null | grep -qF '<!-- prose-check: skip -->' && exit 0

# Strip fenced code blocks before checking.
# Blank out fenced code blocks rather than deleting them, so grep -n reports
# real line numbers from the original file.
prose="$(awk 'BEGIN{f=0} /^```/{f=!f; print ""; next} f==1{print ""; next} {print}' "$file" 2>/dev/null)"
[ -n "$prose" ] || exit 0

patterns_file="$(dirname "$0")/prose-patterns.txt"
[ -r "$patterns_file" ] || exit 0

hits="$(printf '%s\n' "$prose" | grep -nEi -f "$patterns_file" 2>/dev/null || true)"
[ -n "$hits" ] || exit 0

{
  echo "Prose check flagged $file. Rewrite these lines to follow the writing rules:"
  echo "$hits"
  echo
  echo "Regex only catches vocabulary. Also re-check the file for: rule-of-three"
  echo "lists, a closing summary paragraph, and bolded lead-ins on every bullet."
} >&2
exit 2
