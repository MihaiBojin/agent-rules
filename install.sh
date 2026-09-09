#!/usr/bin/env bash
# agent-rules installer.
#
#   ./install.sh                  interactive menu (fzf if present)
#   ./install.sh global           user-level rules for every tool detected
#   ./install.sh project [path]   per-repo rules for every tool (default: cwd)
#   ./install.sh build            regenerate generated/AGENTS.md from rules/*.md
#   ./install.sh status [path]    what is wired up right now
#   ./install.sh uninstall [path] undo both scopes
#
# rules/*.md are the sources. generated/AGENTS.md is built from them, because
# Codex reads one file and has no import syntax. Claude Code and Antigravity
# get one symlink per source file instead. The artifact lives in generated/ so
# it is not picked up as guidance for this repo itself.
#
# Symlinks, never copies, so `git pull` in this repo updates every machine at
# once. A link that already points where it should is left alone. Anything
# else in the way is moved to <path>.bak-<timestamp> and reported on stderr.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$REPO/rules"
RULES="$REPO/generated/AGENTS.md"  # built from RULES_DIR; see generated/README.md
CODEX_HOOK="$REPO/hooks/codex-session-start.sh"
# Migration: the PostToolUse prose hook this installer used to wire. Kept
# only so an install that already has the entry drops it. Delete once every
# machine has run this version.
STALE_HOOK="$REPO/hooks/check-prose.sh"
STAMP="$(date +%Y%m%d%H%M%S)"
MARK_BEGIN="<!-- >>> agent-rules >>> -->"
MARK_END="<!-- <<< agent-rules <<< -->"
TOML_BEGIN="# >>> agent-rules >>>"
TOML_END="# <<< agent-rules <<<"

CHANGED=0
FORCE_ALL="${AGENT_RULES_ALL:-0}"

say()  { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }
head2(){ printf '\n%s\n' "$*"; }

[ -d "$RULES_DIR" ] || { note "error: $RULES_DIR not found — run this from inside the repo"; exit 1; }

# ------------------------------------------------------------------- build

# render: AGENTS.md on stdout, one header then every rules/*.md in order.
render() {
  local f
  printf '%s\n' "# Agent rules"
  for f in "$RULES_DIR"/*.md; do
    printf '\n'
    cat "$f"
  done
}

# fresh — 0 when AGENTS.md already matches rules/
fresh() {
  local t rc
  t="$(mktemp)"; render > "$t"
  cmp -s "$RULES" "$t"; rc=$?
  rm -f "$t"; return $rc
}

# build — rewrite AGENTS.md when it drifts from rules/
build() {
  local t
  mkdir -p "$(dirname "$RULES")" 2>/dev/null || true
  if fresh; then
    say "  ok        $RULES (current)"
    return 0
  fi
  t="$(mktemp)"; render > "$t"
  chmod 644 "$t"
  mv "$t" "$RULES" && say "  rebuilt   $RULES" && CHANGED=1
}

# ---------------------------------------------------------------- primitives

# link <dest> <src>
link() {
  local dest="$1" src="$2" bak
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    say "  ok        $dest"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    bak="$dest.bak-$STAMP"
    if mv "$dest" "$bak" 2>/dev/null; then
      note "  backup    $dest -> $bak"
    else
      note "  FAILED    could not move $dest aside; skipping"
      return 1
    fi
  fi
  if ln -s "$src" "$dest" 2>/dev/null; then
    say "  linked    $dest"
    CHANGED=1
  else
    note "  FAILED    could not link $dest"
    return 1
  fi
}

# block <dest> [full|ref|ptr] — replace/insert a managed block in a file that
# already holds your own content, so a symlink would clobber it. Three payloads:
#
#   full  the rules verbatim. Stale until the next run. Nothing uses this now.
#   ref   a one-line `@` include, resolved by the harness before the model runs.
#   ptr   an instruction telling the agent to open the file itself.
#
# ref and ptr both track the source live, so editing rules/*.md and rebuilding
# is enough — no reinstall.
block() {
  local dest="$1" mode="${2:-full}" tmp new bak
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  tmp="$(mktemp)"; new="$(mktemp)"
  if [ -f "$dest" ]; then
    # Drop any previous block, then trim trailing blank lines so re-running
    # produces byte-identical output instead of growing the file.
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1} skip==0 {print} $0==e {skip=0}
    ' "$dest" \
    | awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' > "$tmp"
  else
    : > "$tmp"
  fi
  { cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' "# Managed by agent-rules install.sh — edits here are overwritten."
    printf '\n'
    if [ "$mode" = "ref" ]; then
      printf '@%s\n' "$RULES"
    elif [ "$mode" = "ptr" ]; then
      printf '%s\n' "## Rules"
      printf '%s\n' "Read this file at the start of every task and follow it:"
      printf '%s\n' "$RULES"
      printf '\n'
      printf '%s\n' "It covers prose written for humans: commit messages, PR bodies,"
      printf '%s\n' "code comments, docs and chat replies, plus how to answer and how"
      printf '%s\n' "to treat git history. Read it before writing any of those."
    else
      printf '%s\n' "# Source: $RULES"
      printf '\n'
      cat "$RULES"
    fi
    printf '%s\n' "$MARK_END"
  } > "$new"

  if [ -f "$dest" ] && cmp -s "$dest" "$new"; then
    say "  ok        $dest (managed block)"
    rm -f "$tmp" "$new"; return 0
  fi
  if [ -s "${dest:-}" ] 2>/dev/null && [ -f "$dest" ]; then
    bak="$dest.bak-$STAMP"
    cp "$dest" "$bak" && note "  backup    $dest -> $bak"
  fi
  mv "$new" "$dest" && say "  written   $dest (managed block)" && CHANGED=1
  rm -f "$tmp"
}

# codex_hook <config.toml> — managed TOML block registering the SessionStart
# hook. Codex injects the hook's output itself, so the rules cannot be skipped,
# and the hook re-reads the file each session, so `build` is enough.
codex_hook() {
  local dest="$1" tmp new bak
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  tmp="$(mktemp)"; new="$(mktemp)"
  if [ -f "$dest" ]; then
    awk -v b="$TOML_BEGIN" -v e="$TOML_END" '
      $0==b {skip=1} skip==0 {print} $0==e {skip=0}
    ' "$dest" \
    | awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' > "$tmp"
  else
    : > "$tmp"
  fi
  { cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n' "$TOML_BEGIN"
    printf '%s\n' "# Managed by agent-rules install.sh — edits here are overwritten."
    printf '\n'
    printf '%s\n' "[[hooks.SessionStart]]"
    printf '\n'
    printf '%s\n' "[[hooks.SessionStart.hooks]]"
    printf '%s\n' 'type = "command"'
    printf 'command = "%s %s"\n' "$CODEX_HOOK" "$RULES"
    printf '%s\n' "timeout = 10"
    printf '%s\n' 'statusMessage = "loading agent rules"'
    printf '%s\n' "additionalContextLimit = 32768"
    printf '%s\n' "$TOML_END"
  } > "$new"

  if [ -f "$dest" ] && cmp -s "$dest" "$new"; then
    say "  ok        $dest (SessionStart hook)"
    rm -f "$tmp" "$new"; return 0
  fi
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    bak="$dest.bak-$STAMP"
    cp "$dest" "$bak" && note "  backup    $dest -> $bak"
  fi
  mv "$new" "$dest" && say "  written   $dest (SessionStart hook)" && CHANGED=1
  rm -f "$tmp"
  say  "              Codex prompts once in the TUI to trust this hook. Until you"
  say  "              accept, it is skipped silently — the AGENTS.md pointer covers"
  say  "              that gap."
}

# link_rules <dir> — one symlink per rules/*.md, and drop any of ours whose
# source has since been deleted or renamed.
link_rules() {
  local rdir="$1" f old tgt
  for f in "$RULES_DIR"/*.md; do
    link "$rdir/$(basename "$f")" "$f"
  done
  for old in "$rdir"/*.md; do
    [ -L "$old" ] || continue
    tgt="$(readlink "$old")"
    case "$tgt" in
      "$RULES_DIR"/*) [ -e "$tgt" ] || { rm -f "$old" && say "  removed   $old (source gone)"; CHANGED=1; } ;;
    esac
  done
}

unlink_rules() {
  local rdir="$1" f
  for f in "$RULES_DIR"/*.md; do
    unlink_ours "$rdir/$(basename "$f")"
  done
}

unlink_ours() {
  local dest="$1" tgt
  if [ -L "$dest" ] && case "$(readlink "$dest")" in "$REPO"/*) true ;; *) false ;; esac; then
    rm -f "$dest" && say "  removed   $dest"; CHANGED=1
  elif [ -e "$dest" ]; then
    say "  kept      $dest (not ours)"
  fi
}

unblock() {
  local dest="$1" b="${2:-$MARK_BEGIN}" e="${3:-$MARK_END}" tmp
  [ -f "$dest" ] || return 0
  grep -qF "$b" "$dest" 2>/dev/null || return 0
  tmp="$(mktemp)"
  awk -v b="$b" -v e="$e" '
    $0==b {skip=1} skip==0 {print} $0==e {skip=0}
  ' "$dest" > "$tmp"
  mv "$tmp" "$dest" && say "  cleaned   $dest (managed block removed)"; CHANGED=1
}

# want <dir> — act on a tool only if it looks installed, unless AGENT_RULES_ALL=1
want() { [ "$FORCE_ALL" = "1" ] || [ -d "$1" ]; }

# dir_state <dir> — how many of rules/*.md are linked into <dir>
dir_state() {
  local d="$1" f rp n=0 total=0
  for f in "$RULES_DIR"/*.md; do
    total=$((total+1))
    rp="$d/$(basename "$f")"
    if [ -L "$rp" ] && [ "$(readlink "$rp")" = "$f" ]; then n=$((n+1)); fi
  done
  if   [ "$n" = "0" ];      then printf -- '-'
  elif [ "$n" = "$total" ]; then printf 'linked (%d)' "$n"
  else printf 'partial (%d/%d)' "$n" "$total"
  fi
}

state() {
  local dest="$1" tgt
  if [ -L "$dest" ]; then
    tgt="$(readlink "$dest")"
    case "$tgt" in "$REPO"/*) printf 'linked'  ;; *) printf 'other link' ;; esac
  elif [ -f "$dest" ] && grep -qF "$MARK_BEGIN" "$dest" 2>/dev/null; then
    printf 'block'
  elif [ -e "$dest" ]; then
    printf 'occupied'
  else
    printf '-'
  fi
}

# ------------------------------------------------------------------- global

do_global() {
  head2 "Global (user-level)"

  say " generated/AGENTS.md"
  build

  if want "$HOME/.claude"; then
    say " Claude Code"
    link_rules "$HOME/.claude/rules"
    unwire_settings "$HOME/.claude/settings.json" "$STALE_HOOK"
  else
    say  " Claude Code  not detected (~/.claude missing) — AGENT_RULES_ALL=1 to force"
  fi

  if want "$HOME/.codex"; then
    say " Codex"
    # The hook is the guarantee: Codex injects its output, so the model cannot
    # skip it. The pointer block is the fallback for before you trust the hook.
    codex_hook "$HOME/.codex/config.toml"
    block "$HOME/.codex/AGENTS.md" ptr
  else
    say  " Codex        not detected (~/.codex missing) — AGENT_RULES_ALL=1 to force"
  fi

  if want "$HOME/.gemini"; then
    say " Antigravity"
    # Antigravity resolves `@/absolute/path` against the filesystem, so this is
    # a live reference rather than a copy. It never needs a refresh run.
    block "$HOME/.gemini/GEMINI.md" ref
  else
    say  " Antigravity  not detected (~/.gemini missing) — AGENT_RULES_ALL=1 to force"
  fi

}

# ------------------------------------------------------------------ project

do_project() {
  dir="${1:-$PWD}"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || { note "error: no such directory: ${1:-$PWD}"; return 1; }
  head2 "Project: $dir"

  say " generated/AGENTS.md"
  build

  say " Claude Code"
  link_rules "$dir/.claude/rules"

  say " Antigravity"
  link_rules "$dir/.agents/rules"
  say  "              set each new rule's activation to \"Always On\" in the Antigravity UI"

  say " Codex"
  if [ -L "$dir/AGENTS.md" ] || [ ! -e "$dir/AGENTS.md" ]; then
    link "$dir/AGENTS.md" "$RULES"
  else
    say "  kept      $dir/AGENTS.md (already has its own; not replaced)"
    say  "              Codex has no import syntax — paste the rules in, or rely"
    say  "              on the global install"
  fi
}

unwire_settings() {
  f="$1"; cmd="$2"
  [ -f "$f" ] || return 0
  command -v jq >/dev/null 2>&1 || {
    note "  manual    jq not found; drop the $cmd hook from $f yourself"
    return 0
  }
  jq -e --arg c "$cmd" '
        [ .hooks.PostToolUse[]?.hooks[]?.command ] | index($c) != null
      ' "$f" >/dev/null 2>&1 || return 0
  tmp="$(mktemp)"
  if jq --arg c "$cmd" '
        .hooks.PostToolUse |= ( map(
          .hooks |= map(select(.command != $c))
        ) | map(select((.hooks | length) > 0)) )
        | if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end
        | if (.hooks | length) == 0 then del(.hooks) else . end
      ' "$f" > "$tmp" 2>/dev/null; then
    bak="$f.bak-$STAMP"
    cp "$f" "$bak" && note "  backup    $f -> $bak"
    mv "$tmp" "$f" && say "  updated   $f (hook removed)"; CHANGED=1
  else
    rm -f "$tmp"
    note "  FAILED    could not edit $f — is it valid JSON?"
  fi
}

# ------------------------------------------------------------------- status

do_status() {
  dir="${1:-$PWD}"
  head2 "Rules source: $RULES_DIR"
  if fresh; then say "generated/AGENTS.md:  current"; else say "generated/AGENTS.md:  STALE — run make build"; fi

  printf '\n%-46s %s\n' "PATH" "STATE"
  for p in \
    "$HOME/.claude/rules" \
    "$dir/.claude/rules" \
    "$dir/.agents/rules"
  do
    short="$(printf '%s' "$p" | sed "s|^$HOME/|~/|")/"
    printf '%-46s %s\n' "$short" "$(dir_state "$p")"
  done
  for p in \
    "$HOME/.codex/AGENTS.md" \
    "$HOME/.gemini/GEMINI.md" \
    "$dir/AGENTS.md"
  do
    short="$(printf '%s' "$p" | sed "s|^$HOME/|~/|")"
    printf '%-46s %s\n' "$short" "$(state "$p")"
  done
  short="$(printf '%s' "$HOME/.codex/config.toml" | sed "s|^$HOME/|~/|")"
  if [ -f "$HOME/.codex/config.toml" ] && grep -qF "$TOML_BEGIN" "$HOME/.codex/config.toml" 2>/dev/null; then
    printf '%-46s %s\n' "$short" "hook"
  else
    printf '%-46s %s\n' "$short" "-"
  fi
  printf '\nlinked (n) = n of %d rule files point into this repo\n' "$(ls "$RULES_DIR"/*.md | wc -l | tr -d ' ')"
  printf 'block = managed section inside a bigger file   hook = hook registered\n'
  printf 'occupied = something else is there   - = nothing\n'
}

# ---------------------------------------------------------------- uninstall

do_uninstall() {
  dir="${1:-$PWD}"
  head2 "Removing agent-rules links"
  unlink_rules "$HOME/.claude/rules"
  unblock     "$HOME/.codex/AGENTS.md"
  unblock     "$HOME/.codex/config.toml" "$TOML_BEGIN" "$TOML_END"
  unblock     "$HOME/.gemini/GEMINI.md"
  unlink_rules "$dir/.claude/rules"
  unlink_ours "$dir/.claude/hooks/check-prose.sh"
  unlink_ours "$dir/.claude/hooks/prose-patterns.txt"
  unlink_rules "$dir/.agents/rules"
  unlink_ours "$dir/AGENTS.md"
  unwire_settings "$HOME/.claude/settings.json" "$STALE_HOOK"
  say  "project settings.json hook entry left in place — remove it by hand if you want it gone"
  say  "backups (*.bak-*) are never deleted"
}

# ---------------------------------------------------------------- interactive

menu() {
  opts="global	wire user-level rules for every tool detected
project	wire this repo: rules for all four tools
build	regenerate generated/AGENTS.md from rules/*.md
status	show what is wired up right now
uninstall	remove every link this installer made"

  if command -v fzf >/dev/null 2>&1; then
    pick="$(printf '%s\n' "$opts" | fzf --height 40% --reverse --with-nth=1,2 \
              --delimiter='\t' --prompt='agent-rules > ' \
              --header='enter to run, esc to cancel' | cut -f1)"
  else
    say "fzf not found — falling back to a numbered prompt."
    PS3="choose > "
    select pick in global project build status uninstall quit; do
      [ -n "${pick:-}" ] && break
    done
    [ "${pick:-quit}" = "quit" ] && pick=""
  fi

  [ -n "${pick:-}" ] || { say "nothing to do"; return 0; }
  case "$pick" in
    build) head2 "generated/AGENTS.md"; build ;;
    project|status|uninstall)
      printf 'path [%s]: ' "$PWD"
      read -r ans
      target="${ans:-$PWD}"
      "do_$pick" "$target"
      ;;
    global) do_global ;;
  esac
}

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  global)     do_global ;;
  project)    do_project "${2:-$PWD}" ;;
  build)      head2 "generated/AGENTS.md"; build ;;
  status)     do_status  "${2:-$PWD}" ;;
  uninstall)  do_uninstall "${2:-$PWD}" ;;
  -h|--help|help) usage ;;
  "")         menu ;;
  *)          note "unknown command: $1"; usage; exit 2 ;;
esac

[ "$CHANGED" = "1" ] && say ""
exit 0
